import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logging.dart';
import '../../domain/models/model_info.dart';
import '../../domain/models/provider_account.dart';
import 'ai_provider.dart';
import 'ai_types.dart';

/// Shared OpenAI-compatible HTTP adapter (OpenAI, OpenRouter, etc.).
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.id,
    required this.providerType,
    required this.baseUrl,
    required this.apiKey,
    this.defaultHeaders = const {},
    Dio? dio,
    Set<String> videoModelIds = const {'sora'},
  })  : _videoModelIds = videoModelIds,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _normalizeBase(baseUrl),
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 5),
                headers: {
                  'Content-Type': 'application/json',
                  ...defaultHeaders,
                },
              ),
            );

  @override
  final String id;

  final ProviderType providerType;
  final String baseUrl;
  final String apiKey;
  final Map<String, String> defaultHeaders;
  final Set<String> _videoModelIds;
  final Dio _dio;

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $apiKey',
        ...defaultHeaders,
      };

  static String _normalizeBase(String url) {
    if (url.endsWith('/')) return url.substring(0, url.length - 1);
    return url;
  }

  @override
  Future<List<ModelInfo>> listModels() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(headers: _authHeaders),
      );
      _throwIfRateLimited(response);
      final data = response.data?['data'];
      if (data is! List) return const [];
      return data.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final modelId = map['id'] as String? ?? '';
        return ModelInfo(
          id: modelId,
          providerType: providerType,
          name: modelId,
          capabilities: const {ModelCapability.chat},
          streaming: true,
          experimental: false,
          notes: 'Live from provider /models',
        );
      }).toList(growable: false);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Stream<ChatDelta> streamChat(ChatRequest req) async* {
    ResponseBody? body;
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': req.model,
          'messages': req.messages.map((m) => m.toJson()).toList(),
          'stream': true,
          if (req.temperature != null) 'temperature': req.temperature,
          if (req.maxTokens != null) 'max_tokens': req.maxTokens,
        },
        options: Options(
          headers: _authHeaders,
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 429) {
        throw RateLimitedException(
          AppLog.redact('Rate limited by $id'),
          retryAfter: _retryAfter(response.headers),
        );
      }
      if (response.statusCode != null && response.statusCode! >= 400) {
        final errText = await _readStreamAsString(response.data);
        throw AppException(
          AppLog.redact(
            'Chat failed (${response.statusCode}): ${errText.isEmpty ? 'unknown error' : errText}',
          ),
        );
      }

      body = response.data;
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
          if (payload.isEmpty) continue;
          if (payload == '[DONE]') {
            yield const ChatDelta(isDone: true);
            return;
          }
          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            if (json['error'] != null) {
              final msg = AppLog.redact(json['error'].toString());
              yield ChatDelta(isDone: true, error: msg);
              return;
            }
            final choices = json['choices'];
            if (choices is! List || choices.isEmpty) continue;
            final choice = choices.first as Map<String, dynamic>;
            final delta = choice['delta'];
            String? text;
            if (delta is Map) {
              text = delta['content'] as String?;
            }
            final finish = choice['finish_reason'] as String?;
            if (text != null && text.isNotEmpty) {
              yield ChatDelta(textDelta: text);
            }
            if (finish != null && finish.isNotEmpty) {
              yield const ChatDelta(isDone: true);
              return;
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
          AppLog.redact('Rate limited by $id'),
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/images/generations',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          'n': req.n,
          if (req.size != null) 'size': req.size,
        },
        options: Options(headers: _authHeaders),
      );
      _throwIfRateLimited(response);
      final data = response.data?['data'];
      if (data is! List || data.isEmpty) {
        throw const AppException('Image generation returned no data');
      }
      final first = Map<String, dynamic>.from(data.first as Map);
      return MediaResult(
        url: first['url'] as String?,
        base64Data: first['b64_json'] as String?,
        mimeType: 'image/png',
        revisedPrompt: first['revised_prompt'] as String?,
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Future<MediaResult> generateVideo(VideoRequest req) async {
    final marked = _videoModelIds.any(
      (id) => req.model == id || req.model.startsWith('$id'),
    );
    if (!marked) {
      throw CapabilityUnsupported(
        'Video generation is not supported for model "${req.model}" on $id',
        capability: 'video',
        providerType: providerType.name,
      );
    }

    try {
      // Experimental OpenAI-style videos endpoint; shape may change.
      final response = await _dio.post<Map<String, dynamic>>(
        '/videos',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          if (req.seconds != null) 'seconds': req.seconds.toString(),
          if (req.size != null) 'size': req.size,
        },
        options: Options(
          headers: _authHeaders,
          validateStatus: (_) => true,
        ),
      );
      _throwIfRateLimited(response);
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw CapabilityUnsupported(
          AppLog.redact(
            'Video generation unavailable for "${req.model}" on $id '
            '(${response.statusCode}). Experimental API may require access.',
          ),
          capability: 'video',
          providerType: providerType.name,
        );
      }
      final data = response.data;
      final url = data?['url'] as String? ??
          (data?['data'] is List && (data!['data'] as List).isNotEmpty
              ? ((data['data'] as List).first as Map)['url'] as String?
              : null);
      return MediaResult(
        url: url,
        mimeType: 'video/mp4',
      );
    } on CapabilityUnsupported {
      rethrow;
    } on DioException catch (e) {
      throw CapabilityUnsupported(
        AppLog.redact(
          'Video generation failed for "${req.model}" on $id: ${_dioMessage(e)}',
        ),
        capability: 'video',
        providerType: providerType.name,
        cause: e,
      );
    }
  }

  @override
  Future<MediaResult> generateAudio(AudioRequest req) async {
    try {
      final response = await _dio.post<List<int>>(
        '/audio/speech',
        data: {
          'model': req.model,
          'input': req.input,
          'voice': req.voice ?? 'alloy',
          if (req.responseFormat != null) 'response_format': req.responseFormat,
        },
        options: Options(
          headers: _authHeaders,
          responseType: ResponseType.bytes,
        ),
      );
      _throwIfRateLimited(response);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const AppException('Audio generation returned empty body');
      }
      return MediaResult(
        bytes: bytes,
        mimeType: _audioMime(req.responseFormat),
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  void _throwIfRateLimited(Response<dynamic> response) {
    if (response.statusCode == 429) {
      throw RateLimitedException(
        AppLog.redact('Rate limited by $id'),
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
        AppLog.redact('Rate limited by $id'),
        retryAfter: _retryAfter(e.response?.headers),
        cause: e,
      );
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return AuthException(
        AppLog.redact('Authentication failed for $id'),
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

  String _audioMime(String? format) {
    switch (format) {
      case 'opus':
        return 'audio/opus';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'pcm':
        return 'audio/pcm';
      case 'wav':
        return 'audio/wav';
      case 'mp3':
      default:
        return 'audio/mpeg';
    }
  }
}
