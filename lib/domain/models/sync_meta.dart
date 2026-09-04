import 'json_helpers.dart';

/// Local sync metadata for optional Google Drive backups.
class SyncMeta {
  const SyncMeta({
    required this.id,
    this.driveFileId,
    this.revision,
    this.lastSyncAt,
    this.conflictState,
    required this.backupKeysEnabled,
  });

  final String id;
  final String? driveFileId;
  final String? revision;
  final DateTime? lastSyncAt;
  final String? conflictState;

  /// When true, encrypted key backup may be included. Default should be false.
  final bool backupKeysEnabled;

  SyncMeta copyWith({
    String? id,
    Object? driveFileId = unsetValue,
    Object? revision = unsetValue,
    Object? lastSyncAt = unsetValue,
    Object? conflictState = unsetValue,
    bool? backupKeysEnabled,
  }) {
    return SyncMeta(
      id: id ?? this.id,
      driveFileId: identical(driveFileId, unsetValue)
          ? this.driveFileId
          : driveFileId as String?,
      revision: identical(revision, unsetValue)
          ? this.revision
          : revision as String?,
      lastSyncAt: identical(lastSyncAt, unsetValue)
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      conflictState: identical(conflictState, unsetValue)
          ? this.conflictState
          : conflictState as String?,
      backupKeysEnabled: backupKeysEnabled ?? this.backupKeysEnabled,
    );
  }

  factory SyncMeta.fromJson(Map<String, dynamic> json) {
    return SyncMeta(
      id: json['id'] as String,
      driveFileId: json['driveFileId'] as String?,
      revision: json['revision'] as String?,
      lastSyncAt: dateTimeFromJson(json['lastSyncAt']),
      conflictState: json['conflictState'] as String?,
      backupKeysEnabled: json['backupKeysEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driveFileId': driveFileId,
        'revision': revision,
        'lastSyncAt': dateTimeToJson(lastSyncAt),
        'conflictState': conflictState,
        'backupKeysEnabled': backupKeysEnabled,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMeta &&
          other.id == id &&
          other.driveFileId == driveFileId &&
          other.revision == revision &&
          other.lastSyncAt == lastSyncAt &&
          other.conflictState == conflictState &&
          other.backupKeysEnabled == backupKeysEnabled;

  @override
  int get hashCode => Object.hash(
        id,
        driveFileId,
        revision,
        lastSyncAt,
        conflictState,
        backupKeysEnabled,
      );
}
