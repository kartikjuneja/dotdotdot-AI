import 'package:sembast/sembast.dart';

import '../../core/scope_keys.dart';
import '../../domain/models/memory_item.dart';
import '../../domain/repositories/memory_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastMemoryRepository implements MemoryRepository {
  SembastMemoryRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.memoryItems);

  @override
  Future<MemoryItem?> getById(String id, {bool includeDeleted = false}) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final item = MemoryItem.fromJson(mapFromRecord(snap));
    if (!includeDeleted && item.isDeleted) return null;
    return item;
  }

  @override
  Future<List<MemoryItem>> listByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  }) async {
    final parts = <Filter>[
      Filter.equals('scopeKind', scopeKind.toJson()),
    ];
    if (scopeKind == ContextScopeKind.global || scopeId == null) {
      parts.add(Filter.isNull('scopeId'));
    } else {
      parts.add(Filter.equals('scopeId', scopeId));
    }
    final finder = softDeleteAwareFinder(
      extra: Filter.and(parts),
      includeDeleted: includeDeleted,
      sortOrders: [
        SortOrder('pinned', false),
        SortOrder('createdAt'),
      ],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => MemoryItem.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<MemoryItem> save(MemoryItem item) async {
    await _store.record(item.id).put(_db, mapForPut(item.toJson()));
    return item;
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
  Stream<List<MemoryItem>> watchByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  }) {
    final parts = <Filter>[
      Filter.equals('scopeKind', scopeKind.toJson()),
    ];
    if (scopeKind == ContextScopeKind.global || scopeId == null) {
      parts.add(Filter.isNull('scopeId'));
    } else {
      parts.add(Filter.equals('scopeId', scopeId));
    }
    final finder = softDeleteAwareFinder(
      extra: Filter.and(parts),
      includeDeleted: includeDeleted,
      sortOrders: [
        SortOrder('pinned', false),
        SortOrder('createdAt'),
      ],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => MemoryItem.fromJson(mapFromRecord(s))).toList(),
        );
  }
}
