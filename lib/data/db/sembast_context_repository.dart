import 'package:sembast/sembast.dart';

import '../../core/scope_keys.dart';
import '../../domain/models/context_doc.dart';
import '../../domain/repositories/context_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastContextRepository implements ContextRepository {
  SembastContextRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.contextDocs);

  @override
  Future<ContextDoc?> getById(String id, {bool includeDeleted = false}) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final doc = ContextDoc.fromJson(mapFromRecord(snap));
    if (!includeDeleted && doc.isDeleted) return null;
    return doc;
  }

  @override
  Future<List<ContextDoc>> listByScope(
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
      sortOrders: [SortOrder('updatedAt', false)],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => ContextDoc.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<ContextDoc> save(ContextDoc doc) async {
    await _store.record(doc.id).put(_db, mapForPut(doc.toJson()));
    return doc;
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
  Stream<List<ContextDoc>> watchByScope(
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
      sortOrders: [SortOrder('updatedAt', false)],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => ContextDoc.fromJson(mapFromRecord(s))).toList(),
        );
  }
}
