import 'package:sembast/sembast.dart';

import '../../domain/models/provider_account.dart';
import '../../domain/repositories/provider_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastProviderRepository implements ProviderRepository {
  SembastProviderRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.providers);

  @override
  Future<ProviderAccount?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final account = ProviderAccount.fromJson(mapFromRecord(snap));
    if (!includeDeleted && account.isDeleted) return null;
    return account;
  }

  @override
  Future<List<ProviderAccount>> list({bool includeDeleted = false}) async {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows
        .map((s) => ProviderAccount.fromJson(mapFromRecord(s)))
        .toList();
  }

  @override
  Future<ProviderAccount> save(ProviderAccount account) async {
    await _store.record(account.id).put(_db, mapForPut(account.toJson()));
    return account;
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    final existing = await getById(id, includeDeleted: true);
    if (existing == null) return;
    await save(
      existing.copyWith(
        deletedAt: deletedAt,
        updatedAt: deletedAt,
        enabled: false,
      ),
    );
  }

  @override
  Stream<List<ProviderAccount>> watchAll({bool includeDeleted = false}) {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('updatedAt', false)],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) => rows
              .map((s) => ProviderAccount.fromJson(mapFromRecord(s)))
              .toList(),
        );
  }
}
