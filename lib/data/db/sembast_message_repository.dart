import 'package:sembast/sembast.dart';

import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastMessageRepository implements MessageRepository {
  SembastMessageRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.messages);

  @override
  Future<Message?> getById(String id) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    return Message.fromJson(mapFromRecord(snap));
  }

  @override
  Future<List<Message>> listByChat(String chatId) async {
    final finder = Finder(
      filter: Filter.equals('chatId', chatId),
      sortOrders: [SortOrder('createdAt')],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => Message.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<Message> save(Message message) async {
    await _store.record(message.id).put(_db, mapForPut(message.toJson()));
    return message;
  }

  @override
  Future<void> delete(String id) async {
    await _store.record(id).delete(_db);
  }

  @override
  Stream<List<Message>> watchByChat(String chatId) {
    final finder = Finder(
      filter: Filter.equals('chatId', chatId),
      sortOrders: [SortOrder('createdAt')],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => Message.fromJson(mapFromRecord(s))).toList(),
        );
  }
}
