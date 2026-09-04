import '../models/plan_node.dart';

abstract class PlanRepository {
  Future<PlanNode?> getById(String id, {bool includeDeleted = false});

  Future<List<PlanNode>> listByProject(
    String? projectId, {
    bool includeDeleted = false,
  });

  Future<List<PlanNode>> listChildren(
    String? parentId, {
    String? projectId,
    bool includeDeleted = false,
  });

  /// Returns ancestors from root → parent of [nodeId] (excluding the node).
  Future<List<PlanNode>> getAncestors(
    String nodeId, {
    bool includeDeleted = false,
  });

  /// Returns root → … → [nodeId] inclusive.
  Future<List<PlanNode>> getAncestorChain(
    String nodeId, {
    bool includeDeleted = false,
  });

  Future<PlanNode> save(PlanNode node);

  Future<void> softDelete(String id, {required DateTime deletedAt});

  Stream<List<PlanNode>> watchByProject(
    String? projectId, {
    bool includeDeleted = false,
  });
}
