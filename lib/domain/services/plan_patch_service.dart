import '../../core/errors.dart';
import '../models/plan_node.dart';

/// Applies JSON-map patches to [PlanNode] fields used by plan-AI tools.
class PlanPatchService {
  const PlanPatchService();

  /// Returns a patched copy of [node].
  ///
  /// Supported keys: `title`, `body`, `progress` (0–100), `status`
  /// (`active` | `done` | `archived`). Unknown keys are ignored.
  /// Throws [AppException] when progress/status are invalid.
  PlanNode applyPatch(PlanNode node, Map<String, dynamic> patch) {
    var next = node;

    if (patch.containsKey('title')) {
      final title = patch['title'];
      if (title is! String) {
        throw const AppException('Plan patch "title" must be a String');
      }
      next = next.copyWith(title: title);
    }

    if (patch.containsKey('body')) {
      final body = patch['body'];
      if (body is! String) {
        throw const AppException('Plan patch "body" must be a String');
      }
      next = next.copyWith(body: body);
    }

    if (patch.containsKey('progress')) {
      final progress = _asInt(patch['progress'], field: 'progress');
      if (progress < 0 || progress > 100) {
        throw AppException(
          'Plan patch "progress" must be 0–100, got $progress',
        );
      }
      next = next.copyWith(progress: progress);
    }

    if (patch.containsKey('status')) {
      final status = patch['status'];
      if (status is! String) {
        throw const AppException('Plan patch "status" must be a String');
      }
      try {
        next = next.copyWith(status: PlanNodeStatus.fromJson(status));
      } on ArgumentError catch (e) {
        throw AppException(
          'Plan patch "status" must be active|done|archived',
          cause: e,
        );
      }
    }

    return next;
  }

  /// Applies multiple patches in order.
  PlanNode applyPatches(PlanNode node, List<Map<String, dynamic>> patches) {
    var next = node;
    for (final patch in patches) {
      next = applyPatch(next, patch);
    }
    return next;
  }

  static int _asInt(Object? value, {required String field}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw AppException('Plan patch "$field" must be an int');
  }
}
