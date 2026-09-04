import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../core/scope_keys.dart';
import '../models/memory_item.dart';
import '../repositories/memory_repository.dart';

/// List / add / pin helpers for scoped memory.
class MemoryService {
  MemoryService(
    this._repository, {
    Clock clock = const SystemClock(),
    UuidV4? ids,
  })  : _clock = clock,
        _ids = ids ?? UuidV4();

  final MemoryRepository _repository;
  final Clock _clock;
  final UuidV4 _ids;

  Future<List<MemoryItem>> list(
    ContextScopeKind scopeKind, {
    String? scopeId,
  }) {
    _validateScope(scopeKind, scopeId);
    return _repository.listByScope(scopeKind, scopeId: scopeId);
  }

  Future<MemoryItem> add({
    required ContextScopeKind scopeKind,
    String? scopeId,
    required String content,
    bool pinned = false,
  }) async {
    _validateScope(scopeKind, scopeId);
    final now = _clock.now();
    final item = MemoryItem(
      id: _ids.next(),
      scopeKind: scopeKind,
      scopeId: scopeKind == ContextScopeKind.global ? null : scopeId,
      content: content,
      pinned: pinned,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.save(item);
  }

  Future<MemoryItem> pin(String id, {bool pinned = true}) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw StateError('MemoryItem $id not found');
    }
    final updated = existing.copyWith(
      pinned: pinned,
      updatedAt: _clock.now(),
    );
    return _repository.save(updated);
  }

  Future<void> remove(String id) async {
    await _repository.softDelete(id, deletedAt: _clock.now());
  }

  void _validateScope(ContextScopeKind scopeKind, String? scopeId) {
    if (scopeKind == ContextScopeKind.global) {
      if (scopeId != null) {
        throw ArgumentError(
          'scopeId must be null for ContextScopeKind.global',
        );
      }
      return;
    }
    if (scopeId == null || scopeId.isEmpty) {
      throw ArgumentError('scopeId is required for $scopeKind');
    }
  }
}
