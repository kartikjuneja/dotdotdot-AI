import '../../core/scope_keys.dart';
import '../models/context_doc.dart';

abstract class ContextRepository {
  Future<ContextDoc?> getById(String id, {bool includeDeleted = false});

  Future<List<ContextDoc>> listByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  });

  Future<ContextDoc> save(ContextDoc doc);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<ContextDoc>> watchByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  });
}
