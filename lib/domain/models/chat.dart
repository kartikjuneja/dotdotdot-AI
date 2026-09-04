import 'json_helpers.dart';

/// A conversation thread, optionally scoped to a project and/or plan node.
class Chat {
  const Chat({
    required this.id,
    required this.title,
    this.projectId,
    this.planNodeId,
    this.providerAccountId,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? projectId;
  final String? planNodeId;
  final String? providerAccountId;
  final String modelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Chat copyWith({
    String? id,
    String? title,
    Object? projectId = unsetValue,
    Object? planNodeId = unsetValue,
    Object? providerAccountId = unsetValue,
    String? modelId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      projectId: identical(projectId, unsetValue)
          ? this.projectId
          : projectId as String?,
      planNodeId: identical(planNodeId, unsetValue)
          ? this.planNodeId
          : planNodeId as String?,
      providerAccountId: identical(providerAccountId, unsetValue)
          ? this.providerAccountId
          : providerAccountId as String?,
      modelId: modelId ?? this.modelId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      title: json['title'] as String,
      projectId: json['projectId'] as String?,
      planNodeId: json['planNodeId'] as String?,
      providerAccountId: json['providerAccountId'] as String?,
      modelId: json['modelId'] as String,
      createdAt: dateTimeFromJson(json['createdAt'])!,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'projectId': projectId,
        'planNodeId': planNodeId,
        'providerAccountId': providerAccountId,
        'modelId': modelId,
        'createdAt': dateTimeToJson(createdAt),
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          other.id == id &&
          other.title == title &&
          other.projectId == projectId &&
          other.planNodeId == planNodeId &&
          other.providerAccountId == providerAccountId &&
          other.modelId == modelId &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        projectId,
        planNodeId,
        providerAccountId,
        modelId,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
