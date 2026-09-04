import '../../core/scope_keys.dart';
import 'json_helpers.dart';

/// A scoped memory fact the model may recall.
class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.scopeKind,
    this.scopeId,
    required this.content,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final ContextScopeKind scopeKind;

  /// Null when [scopeKind] is [ContextScopeKind.global].
  final String? scopeId;
  final String content;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  MemoryItem copyWith({
    String? id,
    ContextScopeKind? scopeKind,
    Object? scopeId = unsetValue,
    String? content,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId:
          identical(scopeId, unsetValue) ? this.scopeId : scopeId as String?,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      scopeKind: ContextScopeKind.fromJson(json['scopeKind'] as String),
      scopeId: json['scopeId'] as String?,
      content: json['content'] as String,
      pinned: json['pinned'] as bool? ?? false,
      createdAt: dateTimeFromJson(json['createdAt'])!,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeKind': scopeKind.toJson(),
        'scopeId': scopeId,
        'content': content,
        'pinned': pinned,
        'createdAt': dateTimeToJson(createdAt),
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryItem &&
          other.id == id &&
          other.scopeKind == scopeKind &&
          other.scopeId == scopeId &&
          other.content == content &&
          other.pinned == pinned &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        scopeKind,
        scopeId,
        content,
        pinned,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
