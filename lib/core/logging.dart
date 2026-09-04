import 'dart:developer' as developer;

/// Application logger that redacts Authorization headers and API keys.
///
/// Never log raw secrets. Prefer logging vault refs / provider ids only.
class AppLog {
  AppLog._();

  static const String _name = 'dotdotdot_ai';

  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    _log(message, level: 800, error: error, stackTrace: stackTrace);
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    _log(message, level: 800, error: error, stackTrace: stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _log(message, level: 900, error: error, stackTrace: stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _log(message, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      redact(message),
      name: _name,
      level: level,
      error: error == null ? null : redact('$error'),
      stackTrace: stackTrace,
    );
  }

  /// Redacts Authorization headers, bearer tokens, and common API key shapes.
  static String redact(String input) {
    var out = input;
    out = out.replaceAllMapped(
      RegExp(
        r'(Authorization\s*[:=]\s*)(Bearer\s+)?(\S+)',
        caseSensitive: false,
      ),
      (m) => '${m[1]}${m[2] ?? ''}[REDACTED]',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'''((?:api[_-]?key|x-api-key|apikey)\s*[:=]\s*)(["']?)([^\s"']+)''',
        caseSensitive: false,
      ),
      (m) => '${m[1]}${m[2] ?? ''}[REDACTED]',
    );
    out = out.replaceAllMapped(
      RegExp(r'\b(sk-[A-Za-z0-9_\-]{8,})\b'),
      (_) => '[REDACTED_KEY]',
    );
    out = out.replaceAllMapped(
      RegExp(r'\b(AIza[0-9A-Za-z_\-]{10,})\b'),
      (_) => '[REDACTED_KEY]',
    );
    return out;
  }
}
