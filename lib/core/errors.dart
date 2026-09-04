/// Base application exception with an optional underlying cause.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? 'AppException: $message' : 'AppException: $message ($cause)';
}

/// Thrown when an AI adapter does not support the requested modality/capability.
class CapabilityUnsupported extends AppException {
  const CapabilityUnsupported(
    String message, {
    this.capability,
    this.providerType,
    Object? cause,
  }) : super(message, cause: cause);

  final String? capability;
  final String? providerType;

  @override
  String toString() =>
      'CapabilityUnsupported: $message'
      '${capability != null ? ' capability=$capability' : ''}'
      '${providerType != null ? ' provider=$providerType' : ''}';
}

/// Thrown when a provider rate-limits the client.
class RateLimitedException extends AppException {
  const RateLimitedException(
    String message, {
    this.retryAfter,
    Object? cause,
  }) : super(message, cause: cause);

  /// Optional hint for when the client may retry.
  final Duration? retryAfter;

  @override
  String toString() =>
      'RateLimitedException: $message'
      '${retryAfter != null ? ' retryAfter=$retryAfter' : ''}';
}

/// Thrown for authentication / API-key failures.
class AuthException extends AppException {
  const AuthException(String message, {Object? cause})
      : super(message, cause: cause);

  @override
  String toString() => 'AuthException: $message';
}
