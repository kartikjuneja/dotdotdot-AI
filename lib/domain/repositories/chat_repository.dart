import '../models/chat.dart';

abstract class ChatRepository {
  Future<Chat?> getById(String id, {bool includeDeleted = false});

  Future<List<Chat>> list({
    String? projectId,
    String? planNodeId,
    bool includeDeleted = false,
  });

  Future<Chat> save(Chat chat);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<Chat>> watchAll({
    String? projectId,
    bool includeDeleted = false,
  });
}
