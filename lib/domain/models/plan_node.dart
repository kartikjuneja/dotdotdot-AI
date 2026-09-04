import 'json_helpers.dart';

enum PlanNodeStatus {
  active,
  done,
  archived;

  static PlanNodeStatus fromJson(String value) =>
      PlanNodeStatus.values.byName(value);

  String toJson() => name;
}

/// Nested plan / course node with progress and soft-delete.
class PlanNode {
  const PlanNode({
    required this.id,
    this.projectId,
    this.parentId,
    required this.title,
    required this.body,
    required this.progress,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? projectId;
  final String? parentId;
  final String title;
  final String body;

  /// Progress percentage in `0..100`.
  final int progress;
  final PlanNodeStatus status;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  PlanNode copyWith({
    String? id,
    Object? projectId = unsetValue,
    Object? parentId = unsetValue,
    String? title,
    String? body,
    int? progress,
    PlanNodeStatus? status,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return PlanNode(
      id: id ?? this.id,
      projectId: identical(projectId, unsetValue)
          ? this.projectId
          : projectId as String?,
      parentId:
          identical(parentId, unsetValue) ? this.parentId : parentId as String?,
      title: title ?? this.title,
      body: body ?? this.body,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory PlanNode.fromJson(Map<String, dynamic> json) {
    return PlanNode(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      status: PlanNodeStatus.fromJson(json['status'] as String),
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: dateTimeFromJson(json['createdAt'])!,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'parentId': parentId,
        'title': title,
        'body': body,
        'progress': progress,
        'status': status.toJson(),
        'sortOrder': sortOrder,
        'createdAt': dateTimeToJson(createdAt),
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanNode &&
          other.id == id &&
          other.projectId == projectId &&
          other.parentId == parentId &&
          other.title == title &&
          other.body == body &&
          other.progress == progress &&
          other.status == status &&
          other.sortOrder == sortOrder &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        parentId,
        title,
        body,
        progress,
        status,
        sortOrder,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
