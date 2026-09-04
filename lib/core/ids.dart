import 'package:uuid/uuid.dart';

/// Generates RFC 4122 version-4 UUIDs for entity primary keys.
class UuidV4 {
  UuidV4([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Returns a new random UUID v4 string.
  String next() => _uuid.v4();
}
