import '../models/message.dart';

abstract class MessageRepository {
  Future<Message?> getById(String id);

  Future<List<Message>> listByChat(String chatId);

  Future<Message> save(Message message);

  Future<void> delete(String id);

  Stream<List<Message>> watchByChat(String chatId);
}
