import 'json_helpers.dart';

/// A workspace that groups chats, plans, and scoped memory/context.
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    this.defaultModelId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? defaultModelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    Object? defaultModelId = unsetValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = unsetValue,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultModelId: identical(defaultModelId, unsetValue)
          ? this.defaultModelId
          : defaultModelId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, unsetValue)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      defaultModelId: json['defaultModelId'] as String?,
      createdAt: dateTimeFromJson(json['createdAt'])!,
      updatedAt: dateTimeFromJson(json['updatedAt'])!,
      deletedAt: dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'defaultModelId': defaultModelId,
        'createdAt': dateTimeToJson(createdAt),
        'updatedAt': dateTimeToJson(updatedAt),
        'deletedAt': dateTimeToJson(deletedAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.defaultModelId == defaultModelId &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        defaultModelId,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
