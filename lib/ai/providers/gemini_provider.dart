import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logging.dart';
import '../../domain/models/model_info.dart';
import '../../domain/models/provider_account.dart';
import 'ai_provider.dart';
import 'ai_types.dart';

/// Google Generative Language API adapter (Gemini / Imagen).
class GeminiProvider implements AiProvider {
  GeminiProvider({
    required this.apiKey,
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = _normalizeBase(
          baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta',
        ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _normalizeBase(
                  baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta',
                ),
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 5),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  @override
  String get id => 'gemini';

  final String apiKey;
  final String baseUrl;
  final Dio _dio;

  static String _normalizeBase(String url) {
    if (url.endsWith('/')) return url.substring(0, url.length - 1);
    return url;
  }

  Map<String, String> get _headers => {
        'x-goog-api-key': apiKey,
        'Content-Type': 'application/json',
      };

  @override
  Future<List<ModelInfo>> listModels() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(headers: _headers),
      );
      _throwIfRateLimited(response);
      final models = response.data?['models'];
      if (models is! List) return const [];
      return models.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        var name = map['name'] as String? ?? '';
        if (name.startsWith('models/')) {
          name = name.substring('models/'.length);
        }
        final methods = (map['supportedGenerationMethods'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};
        final caps = <ModelCapability>{};
        if (methods.contains('generateContent') ||
            methods.contains('streamGenerateContent')) {
          caps.add(ModelCapability.chat);
        }
        if (name.contains('imagen') || name.contains('image')) {
          caps.add(ModelCapability.image);
        }
        if (caps.isEmpty) caps.add(ModelCapability.chat);
        return ModelInfo(
          id: name,
          providerType: ProviderType.gemini,
          name: (map['displayName'] as String?) ?? name,
          capabilities: caps,
          streaming: methods.contains('streamGenerateContent'),
          experimental: name.contains('exp') || name.contains('preview'),
          notes: map['description'] as String?,
        );
      }).toList(growable: false);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Stream<ChatDelta> streamChat(ChatRequest req) async* {
    try {
      final path =
          '/models/${Uri.encodeComponent(req.model)}:streamGenerateContent';
      final response = await _dio.post<ResponseBody>(
        path,
        queryParameters: const {'alt': 'sse'},
        data: _chatBody(req),
        options: Options(
          headers: _headers,
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 429) {
        throw RateLimitedException(
          AppLog.redact('Rate limited by gemini'),
          retryAfter: _retryAfter(response.headers),
        );
      }
      if (response.statusCode != null && response.statusCode! >= 400) {
        final errText = await _readStreamAsString(response.data);
        throw AppException(
          AppLog.redact(
            'Gemini chat failed (${response.statusCode}): '
            '${errText.isEmpty ? 'unknown error' : errText}',
          ),
        );
      }

      final body = response.data;
      if (body == null) {
        yield const ChatDelta(isDone: true, error: 'Empty stream response');
        return;
      }

      var buffer = '';
      await for (final chunk in body.stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        while (true) {
          final nl = buffer.indexOf('\n');
          if (nl < 0) break;
          var line = buffer.substring(0, nl);
          buffer = buffer.substring(nl + 1);
          if (line.endsWith('\r')) {
            line = line.substring(0, line.length - 1);
          }
          if (line.isEmpty || line.startsWith(':')) continue;
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') {
            if (payload == '[DONE]') {
              yield const ChatDelta(isDone: true);
              return;
            }
            continue;
          }
          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            if (json['error'] != null) {
              yield ChatDelta(
                isDone: true,
                error: AppLog.redact(json['error'].toString()),
              );
              return;
            }
            final text = _extractText(json);
            if (text != null && text.isNotEmpty) {
              yield ChatDelta(textDelta: text);
            }
          } on FormatException {
            // Skip malformed SSE chunks.
          }
        }
      }
      yield const ChatDelta(isDone: true);
    } on RateLimitedException {
      rethrow;
    } on AppException catch (e) {
      yield ChatDelta(isDone: true, error: AppLog.redact(e.message));
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw RateLimitedException(
          AppLog.redact('Rate limited by gemini'),
          retryAfter: _retryAfter(e.response?.headers),
          cause: e,
        );
      }
      yield ChatDelta(isDone: true, error: AppLog.redact(_dioMessage(e)));
    } catch (e) {
      yield ChatDelta(isDone: true, error: AppLog.redact(e.toString()));
    }
  }

  @override
  Future<MediaResult> generateImage(ImageRequest req) async {
    final model = req.model.toLowerCase();
    if (model.contains('imagen')) {
      return _generateImagen(req);
    }
    return _generateGeminiImage(req);
  }

  Future<MediaResult> _generateImagen(ImageRequest req) async {
    try {
      final path = '/models/${Uri.encodeComponent(req.model)}:predict';
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'instances': [
            {'prompt': req.prompt},
          ],
          'parameters': {
            'sampleCount': req.n.clamp(1, 4),
          },
        },
        options: Options(headers: _headers),
      );
      _throwIfRateLimited(response);
      final predictions = response.data?['predictions'];
      if (predictions is! List || predictions.isEmpty) {
        throw const AppException('Imagen returned no predictions');
      }
      final first = Map<String, dynamic>.from(predictions.first as Map);
      String? b64 = first['bytesBase64Encoded'] as String?;
      if (b64 == null) {
        final image = first['image'];
        if (image is Map) {
          b64 = image['bytesBase64Encoded'] as String?;
        }
      }
      return MediaResult(
        base64Data: b64,
        mimeType: (first['mimeType'] as String?) ?? 'image/png',
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<MediaResult> _generateGeminiImage(ImageRequest req) async {
    try {
      final path = '/models/${Uri.encodeComponent(req.model)}:generateContent';
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': req.prompt},
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        },
        options: Options(headers: _headers),
      );
      _throwIfRateLimited(response);
      final candidates = response.data?['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw const AppException('Gemini image generation returned no candidates');
      }
      final content = (candidates.first as Map)['content'];
      final parts = content is Map ? content['parts'] : null;
      if (parts is! List) {
        throw const AppException('Gemini image generation missing parts');
      }
      for (final part in parts) {
        if (part is! Map) continue;
        final inline = part['inlineData'] ?? part['inline_data'];
        if (inline is Map) {
          return MediaResult(
            base64Data: inline['data'] as String?,
            mimeType: (inline['mimeType'] ?? inline['mime_type']) as String? ??
                'image/png',
          );
        }
      }
      throw const AppException('Gemini image generation returned no image data');
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Future<MediaResult> generateVideo(VideoRequest req) async {
    throw CapabilityUnsupported(
      'Video generation is not supported by the Gemini adapter yet '
      '(model "${req.model}"). Experimental Veo access is not wired.',
      capability: 'video',
      providerType: ProviderType.gemini.name,
    );
  }

  @override
  Future<MediaResult> generateAudio(AudioRequest req) async {
    throw CapabilityUnsupported(
      'Audio generation is not supported by the Gemini adapter '
      '(model "${req.model}"). Use an OpenAI TTS model instead.',
      capability: 'audio',
      providerType: ProviderType.gemini.name,
    );
  }

  Map<String, dynamic> _chatBody(ChatRequest req) {
    String? systemText;
    final contents = <Map<String, dynamic>>[];

    for (final msg in req.messages) {
      final role = msg.role.toLowerCase();
      if (role == 'system') {
        systemText = systemText == null
            ? msg.content
            : '$systemText\n${msg.content}';
        continue;
      }
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg.content},
        ],
      });
    }

    return {
      if (systemText != null && systemText.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemText},
          ],
        },
      'contents': contents,
      'generationConfig': {
        if (req.temperature != null) 'temperature': req.temperature,
        if (req.maxTokens != null) 'maxOutputTokens': req.maxTokens,
      },
    };
  }

  String? _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final buf = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buf.write(part['text'] as String);
      }
    }
    final text = buf.toString();
    return text.isEmpty ? null : text;
  }

  void _throwIfRateLimited(Response<dynamic> response) {
    if (response.statusCode == 429) {
      throw RateLimitedException(
        AppLog.redact('Rate limited by gemini'),
        retryAfter: _retryAfter(response.headers),
      );
    }
  }

  Duration? _retryAfter(Headers? headers) {
    final raw = headers?.value('retry-after');
    if (raw == null) return null;
    final seconds = int.tryParse(raw);
    if (seconds != null) return Duration(seconds: seconds);
    return null;
  }

  Exception _mapDio(DioException e) {
    if (e.response?.statusCode == 429) {
      return RateLimitedException(
        AppLog.redact('Rate limited by gemini'),
        retryAfter: _retryAfter(e.response?.headers),
        cause: e,
      );
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return AuthException(
        AppLog.redact('Authentication failed for gemini'),
        cause: e,
      );
    }
    return AppException(AppLog.redact(_dioMessage(e)), cause: e);
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? e.toString();
  }

  Future<String> _readStreamAsString(ResponseBody? body) async {
    if (body == null) return '';
    final chunks = <int>[];
    await for (final chunk in body.stream) {
      chunks.addAll(chunk);
    }
    return utf8.decode(chunks, allowMalformed: true);
  }
}
