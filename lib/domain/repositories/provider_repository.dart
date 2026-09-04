import '../models/provider_account.dart';

abstract class ProviderRepository {
  Future<ProviderAccount?> getById(String id, {bool includeDeleted = false});

  Future<List<ProviderAccount>> list({bool includeDeleted = false});

  Future<ProviderAccount> save(ProviderAccount account);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<ProviderAccount>> watchAll({bool includeDeleted = false});
}
