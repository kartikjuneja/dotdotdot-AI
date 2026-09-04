import '../../core/scope_keys.dart';
import '../models/memory_item.dart';

abstract class MemoryRepository {
  Future<MemoryItem?> getById(String id, {bool includeDeleted = false});

  Future<List<MemoryItem>> listByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  });

  Future<MemoryItem> save(MemoryItem item);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<MemoryItem>> watchByScope(
    ContextScopeKind scopeKind, {
    String? scopeId,
    bool includeDeleted = false,
  });
}
