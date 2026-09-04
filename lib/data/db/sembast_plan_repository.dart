import 'package:sembast/sembast.dart';

import '../../domain/models/plan_node.dart';
import '../../domain/repositories/plan_repository.dart';
import 'sembast_helpers.dart';
import 'stores.dart';

class SembastPlanRepository implements PlanRepository {
  SembastPlanRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.planNodes);

  @override
  Future<PlanNode?> getById(String id, {bool includeDeleted = false}) async {
    final snap = await _store.record(id).getSnapshot(_db);
    if (snap == null) return null;
    final node = PlanNode.fromJson(mapFromRecord(snap));
    if (!includeDeleted && node.isDeleted) return null;
    return node;
  }

  @override
  Future<List<PlanNode>> listAll({bool includeDeleted = false}) async {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('sortOrder'), SortOrder('updatedAt', false)],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => PlanNode.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<List<PlanNode>> listByProject(
    String? projectId, {
    bool includeDeleted = false,
  }) async {
    Filter? extra;
    if (projectId == null) {
      extra = Filter.isNull('projectId');
    } else {
      extra = Filter.equals('projectId', projectId);
    }
    final finder = softDeleteAwareFinder(
      extra: extra,
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => PlanNode.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<List<PlanNode>> listChildren(
    String? parentId, {
    String? projectId,
    bool includeDeleted = false,
  }) async {
    final parts = <Filter>[
      if (parentId == null)
        Filter.isNull('parentId')
      else
        Filter.equals('parentId', parentId),
    ];
    if (projectId != null) {
      parts.add(Filter.equals('projectId', projectId));
    }
    final finder = softDeleteAwareFinder(
      extra: parts.length == 1 ? parts.first : Filter.and(parts),
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')],
    );
    final rows = await _store.find(_db, finder: finder);
    return rows.map((s) => PlanNode.fromJson(mapFromRecord(s))).toList();
  }

  @override
  Future<List<PlanNode>> getAncestors(
    String nodeId, {
    bool includeDeleted = false,
  }) async {
    final chain = await getAncestorChain(
      nodeId,
      includeDeleted: includeDeleted,
    );
    if (chain.isEmpty) return const [];
    return chain.sublist(0, chain.length - 1);
  }

  @override
  Future<List<PlanNode>> getAncestorChain(
    String nodeId, {
    bool includeDeleted = false,
  }) async {
    final upward = <PlanNode>[];
    var currentId = nodeId;
    final seen = <String>{};

    while (true) {
      if (!seen.add(currentId)) {
        // Cycle guard.
        break;
      }
      final node = await getById(currentId, includeDeleted: includeDeleted);
      if (node == null) break;
      upward.add(node);
      final parentId = node.parentId;
      if (parentId == null || parentId.isEmpty) break;
      currentId = parentId;
    }

    return upward.reversed.toList();
  }

  @override
  Future<PlanNode> save(PlanNode node) async {
    await _store.record(node.id).put(_db, mapForPut(node.toJson()));
    return node;
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
  Stream<List<PlanNode>> watchAll({bool includeDeleted = false}) {
    final finder = softDeleteAwareFinder(
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('sortOrder'), SortOrder('updatedAt', false)],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => PlanNode.fromJson(mapFromRecord(s))).toList(),
        );
  }

  @override
  Stream<List<PlanNode>> watchByProject(
    String? projectId, {
    bool includeDeleted = false,
  }) {
    Filter? extra;
    if (projectId == null) {
      extra = Filter.isNull('projectId');
    } else {
      extra = Filter.equals('projectId', projectId);
    }
    final finder = softDeleteAwareFinder(
      extra: extra,
      includeDeleted: includeDeleted,
      sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')],
    );
    return _store.query(finder: finder).onSnapshots(_db).map(
          (rows) =>
              rows.map((s) => PlanNode.fromJson(mapFromRecord(s))).toList(),
        );
  }
}
