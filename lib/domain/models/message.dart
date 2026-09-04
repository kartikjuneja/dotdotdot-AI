import 'json_helpers.dart';

enum MessageRole {
  user,
  assistant,
  system;

  static MessageRole fromJson(String value) => MessageRole.values.byName(value);

  String toJson() => name;
}

enum MessageStatus {
  pending,
  streaming,
  complete,
  error;

  static MessageStatus fromJson(String value) =>
      MessageStatus.values.byName(value);

  String toJson() => name;
}

/// A single chat message with optional local media paths and usage.
class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.role,
    required this.text,
    this.mediaPaths = const [],
    required this.status,
    this.error,
    required this.createdAt,
    this.usageTokens,
  });

  final String id;
  final String chatId;
  final MessageRole role;
  final String text;
  final List<String> mediaPaths;
  final MessageStatus status;
  final String? error;
  final DateTime createdAt;
  final int? usageTokens;

  Message copyWith({
    String? id,
    String? chatId,
    MessageRole? role,
    String? text,
    List<String>? mediaPaths,
    MessageStatus? status,
    Object? error = unsetValue,
    DateTime? createdAt,
    Object? usageTokens = unsetValue,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      text: text ?? this.text,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      status: status ?? this.status,
      error: identical(error, unsetValue) ? this.error : error as String?,
      createdAt: createdAt ?? this.createdAt,
      usageTokens: identical(usageTokens, unsetValue)
          ? this.usageTokens
          : usageTokens as int?,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      role: MessageRole.fromJson(json['role'] as String),
      text: json['text'] as String? ?? '',
      mediaPaths: stringListFromJson(json['mediaPaths']),
      status: MessageStatus.fromJson(json['status'] as String),
      error: json['error'] as String?,
      createdAt: dateTimeFromJson(json['createdAt'])!,
      usageTokens: json['usageTokens'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'role': role.toJson(),
        'text': text,
        'mediaPaths': mediaPaths,
        'status': status.toJson(),
        'error': error,
        'createdAt': dateTimeToJson(createdAt),
        'usageTokens': usageTokens,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          other.id == id &&
          other.chatId == chatId &&
          other.role == role &&
          other.text == text &&
          _listEq(other.mediaPaths, mediaPaths) &&
          other.status == status &&
          other.error == error &&
          other.createdAt == createdAt &&
          other.usageTokens == usageTokens;

  @override
  int get hashCode => Object.hash(
        id,
        chatId,
        role,
        text,
        Object.hashAll(mediaPaths),
        status,
        error,
        createdAt,
        usageTokens,
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
