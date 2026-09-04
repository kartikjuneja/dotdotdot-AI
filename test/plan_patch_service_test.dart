import 'package:dotdotdot_ai/core/errors.dart';
import 'package:dotdotdot_ai/domain/models/plan_node.dart';
import 'package:dotdotdot_ai/domain/services/plan_patch_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PlanPatchService();
  final now = DateTime.utc(2026, 1, 1);

  PlanNode base() => PlanNode(
        id: 'n1',
        title: 'Draft',
        body: 'Body',
        progress: 10,
        status: PlanNodeStatus.active,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

  group('PlanPatchService.applyPatch', () {
    test('applies valid title, body, progress, and status', () {
      final patched = service.applyPatch(base(), {
        'title': 'Ship it',
        'body': 'Done notes',
        'progress': 80,
        'status': 'done',
        'unknown': 'ignored',
      });

      expect(patched.title, 'Ship it');
      expect(patched.body, 'Done notes');
      expect(patched.progress, 80);
      expect(patched.status, PlanNodeStatus.done);
    });

    test('accepts numeric progress as num', () {
      final patched = service.applyPatch(base(), {'progress': 50.0});
      expect(patched.progress, 50);
    });

    test('throws AppException for progress below 0', () {
      expect(
        () => service.applyPatch(base(), {'progress': -1}),
        throwsA(isA<AppException>()),
      );
    });

    test('throws AppException for progress above 100', () {
      expect(
        () => service.applyPatch(base(), {'progress': 101}),
        throwsA(isA<AppException>()),
      );
    });

    test('throws AppException for non-int progress', () {
      expect(
        () => service.applyPatch(base(), {'progress': true}),
        throwsA(isA<AppException>()),
      );
    });

    test('applyPatches applies in order', () {
      final patched = service.applyPatches(base(), [
        {'progress': 40},
        {'title': 'Mid'},
        {'progress': 90, 'status': 'archived'},
      ]);

      expect(patched.title, 'Mid');
      expect(patched.progress, 90);
      expect(patched.status, PlanNodeStatus.archived);
    });
  });
}
