import 'package:dotdotdot_ai/domain/services/context_merge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ContextMergeService(defaultCharBudget: 12000);

  group('ContextMergeService.merge', () {
    test('skips empty parts', () {
      final out = service.merge(
        global: ['', '  '],
        project: ['Project notes'],
        chat: [''],
        charBudget: 500,
      );

      expect(out, contains('### project'));
      expect(out, contains('Project notes'));
      expect(out, isNot(contains('### global')));
      expect(out, isNot(contains('### chat')));
    });

    test('prefers nearer scopes under budget', () {
      final out = service.merge(
        global: ['GLOBAL_UNIQUE ${'g' * 200}'],
        project: ['PROJECT_UNIQUE ${'p' * 200}'],
        planAncestors: ['PLAN_UNIQUE ${'a' * 200}'],
        chat: ['CHAT_UNIQUE ${'c' * 200}'],
        charBudget: 180,
      );

      expect(out, contains('CHAT_UNIQUE'));
      expect(out, isNot(contains('GLOBAL_UNIQUE')));
      // Chat is nearer than project; under a tight budget chat should win.
      expect(out.indexOf('### chat'), greaterThanOrEqualTo(0));
    });

    test('keeps inheritance order when everything fits', () {
      final out = service.merge(
        global: ['G'],
        project: ['P'],
        planAncestors: ['A0', 'A1'],
        chat: ['C'],
        charBudget: 500,
      );

      expect(out.indexOf('### global'), lessThan(out.indexOf('### project')));
      expect(out.indexOf('### project'), lessThan(out.indexOf('### plan:0')));
      expect(out.indexOf('### plan:0'), lessThan(out.indexOf('### plan:1')));
      expect(out.indexOf('### plan:1'), lessThan(out.indexOf('### chat')));
    });

    test('returns empty string when all inputs empty', () {
      expect(service.merge(charBudget: 100), isEmpty);
    });
  });
}
