import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/plan_node.dart';

class PlanTreeState {
  const PlanTreeState({
    this.root,
    this.nodes = const [],
    this.error,
  });

  final PlanNode? root;
  final List<PlanNode> nodes;
  final String? error;

  /// Children grouped by parentId (null = roots under this tree's project).
  Map<String?, List<PlanNode>> get childrenByParent {
    final map = <String?, List<PlanNode>>{};
    for (final n in nodes) {
      map.putIfAbsent(n.parentId, () => []).add(n);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  PlanTreeState copyWith({
    PlanNode? root,
    List<PlanNode>? nodes,
    Object? error = _unset,
  }) {
    return PlanTreeState(
      root: root ?? this.root,
      nodes: nodes ?? this.nodes,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const Object _unset = Object();

final planControllerProvider =
    NotifierProvider.family<PlanController, PlanTreeState, String>(
  PlanController.new,
);

class PlanController extends FamilyNotifier<PlanTreeState, String> {
  @override
  PlanTreeState build(String planId) {
    Future.microtask(_load);
    return const PlanTreeState();
  }

  String get planId => arg;

  Future<void> _load() async {
    try {
      final repo = ref.read(planRepositoryProvider);
      final root = await repo.getById(planId);
      if (root == null) {
        state = state.copyWith(error: 'Plan not found');
        return;
      }
      final all = await repo.listByProject(root.projectId);
      // Keep only root + descendants.
      final ids = <String>{root.id};
      var changed = true;
      while (changed) {
        changed = false;
        for (final n in all) {
          if (n.parentId != null &&
              ids.contains(n.parentId) &&
              ids.add(n.id)) {
            changed = true;
          }
        }
      }
      final subtree = all.where((n) => ids.contains(n.id)).toList();
      state = PlanTreeState(root: root, nodes: subtree);
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  Future<void> refresh() => _load();

  Future<PlanNode> addChild({
    required String? parentId,
    required String title,
    String body = '',
  }) async {
    final root = state.root;
    final repo = ref.read(planRepositoryProvider);
    final siblings = await repo.listChildren(
      parentId,
      projectId: root?.projectId,
    );
    final now = ref.read(clockProvider).now();
    final node = PlanNode(
      id: ref.read(uuidProvider).next(),
      projectId: root?.projectId,
      parentId: parentId,
      title: title,
      body: body,
      progress: 0,
      status: PlanNodeStatus.active,
      sortOrder: siblings.length,
      createdAt: now,
      updatedAt: now,
    );
    await repo.save(node);
    await _load();
    return node;
  }

  Future<void> updateNode({
    required String id,
    String? title,
    String? body,
    int? progress,
    PlanNodeStatus? status,
  }) async {
    final repo = ref.read(planRepositoryProvider);
    final existing = await repo.getById(id);
    if (existing == null) return;
    final next = existing.copyWith(
      title: title,
      body: body,
      progress: progress,
      status: status,
      updatedAt: ref.read(clockProvider).now(),
    );
    await repo.save(next);
    await _load();
  }

  Future<void> setProgress(String id, int progress) async {
    final clamped = progress.clamp(0, 100);
    await updateNode(id: id, progress: clamped);
  }

  Future<void> reorderChild({
    required String id,
    required int newSortOrder,
  }) async {
    final repo = ref.read(planRepositoryProvider);
    final existing = await repo.getById(id);
    if (existing == null) return;
    await repo.save(
      existing.copyWith(
        sortOrder: newSortOrder,
        updatedAt: ref.read(clockProvider).now(),
      ),
    );
    await _load();
  }

  Future<void> moveSort({
    required String id,
    required int delta,
  }) async {
    PlanNode? node;
    for (final n in state.nodes) {
      if (n.id == id) {
        node = n;
        break;
      }
    }
    if (node == null) return;
    final siblings = state.childrenByParent[node.parentId] ?? const [];
    final index = siblings.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final target = index + delta;
    if (target < 0 || target >= siblings.length) return;

    final a = siblings[index];
    final b = siblings[target];
    final repo = ref.read(planRepositoryProvider);
    final now = ref.read(clockProvider).now();
    await repo.save(a.copyWith(sortOrder: b.sortOrder, updatedAt: now));
    await repo.save(b.copyWith(sortOrder: a.sortOrder, updatedAt: now));
    await _load();
  }

  Future<void> softDelete(String id) async {
    await ref.read(planRepositoryProvider).softDelete(
          id,
          deletedAt: ref.read(clockProvider).now(),
        );
    await _load();
  }
}

final rootPlansProvider =
    StreamProvider.family<List<PlanNode>, String?>((ref, projectId) {
  return ref.watch(planRepositoryProvider).watchByProject(projectId).map(
        (nodes) => nodes.where((n) => n.parentId == null).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
});
