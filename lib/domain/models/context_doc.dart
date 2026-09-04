import '../../core/scope_keys.dart';
import 'json_helpers.dart';

/// User-authored context document at a given scope.
class ContextDoc {
  const ContextDoc({
    required this.id,
    required this.scopeKind,
    this.scopeId,
    required this.title,
    required this.body,
    this.fileRefs = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final ContextScopeKind scopeKind;
  final String? scopeId;
  final String title;
  final String body;
  final List<String> fileRefs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ContextDoc copyWith({
    String? id,
    ContextScopeKind? scopeKind,
    Object? scopeId = unsetValue,
    String? title,
    String? body,
    List<String>? fileRefs,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return ContextDoc(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId:
          identical(scopeId, unsetValue) ? this.scopeId : scopeId as String?,
      title: title ?? this.title,
      body: body ?? this.body,
      fileRefs: fileRefs ?? this.fileRefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory ContextDoc.fromJson(Map<String, dynamic> json) {
    return ContextDoc(
      id: json['id'] as String,
      scopeKind: ContextScopeKind.fromJson(json['scopeKind'] as String),
      scopeId: json['scopeId'] as String?,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      fileRefs: stringListFromJson(json['fileRefs']),
      createdAt: dateTimeFromJson(json['createdAt'])!,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeKind': scopeKind.toJson(),
        'scopeId': scopeId,
        'title': title,
        'body': body,
        'fileRefs': fileRefs,
        'createdAt': dateTimeToJson(createdAt),
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextDoc &&
          other.id == id &&
          other.scopeKind == scopeKind &&
          other.scopeId == scopeId &&
          other.title == title &&
          other.body == body &&
          _listEq(other.fileRefs, fileRefs) &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        scopeKind,
        scopeId,
        title,
        body,
        Object.hashAll(fileRefs),
        createdAt,
        updatedAt,
        deletedAt,
      );
}

bool _listEq(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
