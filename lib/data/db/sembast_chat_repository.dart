import 'package:sembast/sembast.dart';

import '../../domain/models/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastChatRepository implements ChatRepository {
  SembastChatRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.chats);

  @override
  Future<Chat?> getById(String id, {bool includeDeleted = false}) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final chat = Chat.fromJson(mapFromRecord(snap));
    if (!includeDeleted && chat.isDeleted) return null;
    return chat;
  }

  @override
  Future<List<Chat>> list({
    String? projectId,
    String? planNodeId,
    bool includeDeleted = false,
  }) async {
    Filter? extra;
    final parts = <Filter>[];
    if (projectId != null) {
      parts.add(Filter.equals('projectId', projectId));
    }
    if (planNodeId != null) {
      parts.add(Filter.equals('planNodeId', planNodeId));
    }
    if (parts.isNotEmpty) {
      extra = parts.length == 1 ? parts.first : Filter.and(parts);
    }
    final finder = softDeleteAwareFinder(
      extra: extra,
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => Chat.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<Chat> save(Chat chat) async {
    await _store.record(chat.id).put(_db, mapForPut(chat.toJson()));
    return chat;
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    final existing = await getById(id, includeDeleted: true);
    if (existing == null) return;
    await save(
      existing.copyWith(
        deletedAt: deletedAt,
        updatedAt: deletedAt,
      ),
    );
  }

  @override
  Stream<List<Chat>> watchAll({
    String? projectId,
    bool includeDeleted = false,
  }) {
    Filter? extra;
    if (projectId != null) {
      extra = Filter.equals('projectId', projectId);
    }
    final finder = softDeleteAwareFinder(
      extra: extra,
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    return _store
        .query(finder: finder)
        .onSnapshots(_db)
        .map((rows) => rows.map((s) => Chat.fromJson(mapFromRecord(s))).toList());
  }
}
