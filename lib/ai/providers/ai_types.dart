/// Chat message payload sent to providers (DTO, not persisted domain Message).
class ChatMessageDto {
  const ChatMessageDto({
    required this.role,
    required this.content,
  });

  /// `system` | `user` | `assistant` (mapped per-provider as needed).
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// Streaming / non-streaming chat completion request.
class ChatRequest {
  const ChatRequest({
    required this.model,
    required this.messages,
    this.temperature,
    this.maxTokens,
  });

  final String model;
  final List<ChatMessageDto> messages;
  final double? temperature;
  final int? maxTokens;
}

/// Incremental chat stream event.
class ChatDelta {
  const ChatDelta({
    this.textDelta,
    this.isDone = false,
    this.error,
  });

  final String? textDelta;
  final bool isDone;
  final String? error;
}

/// Text-to-image request.
class ImageRequest {
  const ImageRequest({
    required this.model,
    required this.prompt,
    this.size,
    this.n = 1,
  });

  final String model;
  final String prompt;
  final String? size;
  final int n;
}

/// Text-to-video request (capability-gated).
class VideoRequest {
  const VideoRequest({
    required this.model,
    required this.prompt,
    this.seconds,
    this.size,
  });

  final String model;
  final String prompt;
  final int? seconds;
  final String? size;
}

/// Text-to-speech / audio generation request.
class AudioRequest {
  const AudioRequest({
    required this.model,
    required this.input,
    this.voice,
    this.responseFormat,
  });

  final String model;
  final String input;
  final String? voice;
  final String? responseFormat;
}

/// Binary or URL media payload from a generation call.
class MediaResult {
  const MediaResult({
    this.bytes,
    this.url,
    this.base64Data,
    this.mimeType,
    this.revisedPrompt,
  });

  final List<int>? bytes;
  final String? url;
  final String? base64Data;
  final String? mimeType;
  final String? revisedPrompt;
}
