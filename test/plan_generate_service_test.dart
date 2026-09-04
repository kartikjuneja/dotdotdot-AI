import 'package:dotdotdot_ai/core/clock.dart';
import 'package:dotdotdot_ai/core/errors.dart';
import 'package:dotdotdot_ai/core/ids.dart';
import 'package:dotdotdot_ai/data/db/sembast_plan_repository.dart';
import 'package:dotdotdot_ai/domain/services/plan_generate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

void main() {
  const service = PlanGenerateService();

  group('PlanGenerateService.extractFromAssistantText', () {
    test('parses plan-create fence', () {
      const text = '''
Here is a course.

```plan-create
{"title":"Spanish","body":"A1 path","children":[{"title":"Week 1","body":"Greetings","children":[]}]}
```
''';
      final draft = service.extractFromAssistantText(text);
      expect(draft, isNotNull);
      expect(draft!.title, 'Spanish');
      expect(draft.body, 'A1 path');
      expect(draft.children, hasLength(1));
      expect(draft.children.single.title, 'Week 1');
      expect(draft.nodeCount, 2);
    });

    test('parses plan fence alias', () {
      const text = '''
```plan
{"title":"Solo"}
```
''';
      final draft = service.extractFromAssistantText(text);
      expect(draft?.title, 'Solo');
      expect(draft?.children, isEmpty);
    });

    test('returns null without a fence', () {
      expect(service.extractFromAssistantText('just chat'), isNull);
    });
  });

  group('PlanGenerateService.parseTree', () {
    test('throws when title missing', () {
      expect(
        () => service.parseTree({'body': 'x'}),
        throwsA(isA<AppException>()),
      );
    });

    test('throws when too many nodes', () {
      final tiny = const PlanGenerateService(maxNodes: 2);
      expect(
        () => tiny.parseTree({
          'title': 'root',
          'children': [
            {'title': 'a'},
            {'title': 'b'},
          ],
        }),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('PlanGenerateService.persistTree', () {
    late Database db;
    late SembastPlanRepository repo;

    setUp(() async {
      db = await databaseFactoryMemory.openDatabase('plan_gen.db');
      repo = SembastPlanRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves nested nodes and returns root', () async {
      final draft = service.parseTree({
        'title': 'Course',
        'body': 'Overview',
        'children': [
          {
            'title': 'M1',
            'children': [
              {'title': 'M1.1'},
            ],
          },
          {'title': 'M2'},
        ],
      });

      final root = await service.persistTree(
        draft: draft,
        repo: repo,
        ids: UuidV4(),
        clock: _FixedClock(DateTime.utc(2026, 9, 4)),
        projectId: 'proj-1',
      );

      expect(root.title, 'Course');
      expect(root.projectId, 'proj-1');
      expect(root.parentId, isNull);

      final all = await repo.listAll();
      expect(all, hasLength(4));
      final kids = await repo.listChildren(root.id, projectId: 'proj-1');
      expect(kids.map((n) => n.title), ['M1', 'M2']);
      final grand = await repo.listChildren(kids.first.id, projectId: 'proj-1');
      expect(grand.single.title, 'M1.1');
    });
  });
}
