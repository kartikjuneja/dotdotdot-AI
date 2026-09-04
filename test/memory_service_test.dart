import 'package:dotdotdot_ai/core/clock.dart';
import 'package:dotdotdot_ai/core/scope_keys.dart';
import 'package:dotdotdot_ai/data/db/sembast_memory_repository.dart';
import 'package:dotdotdot_ai/domain/services/memory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  late Database db;
  late MemoryService service;
  late _FixedClock clock;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('memory_test.db');
    clock = _FixedClock(DateTime.utc(2026, 3, 1, 12));
    service = MemoryService(
      SembastMemoryRepository(db),
      clock: clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('add and list global memory', () async {
    final item = await service.add(
      scopeKind: ContextScopeKind.global,
      content: 'Prefer concise answers',
      pinned: true,
    );

    expect(item.scopeId, isNull);
    expect(item.pinned, isTrue);
    expect(item.content, 'Prefer concise answers');

    final listed = await service.list(ContextScopeKind.global);
    expect(listed, hasLength(1));
    expect(listed.single.id, item.id);
  });

  test('add requires scopeId for non-global scopes', () async {
    await expectLater(
      service.add(
        scopeKind: ContextScopeKind.project,
        content: 'x',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('pin and remove', () async {
    final item = await service.add(
      scopeKind: ContextScopeKind.chat,
      scopeId: 'chat-1',
      content: 'Remember this',
    );
    expect(item.pinned, isFalse);

    clock.advance(const Duration(minutes: 1));
    final pinned = await service.pin(item.id);
    expect(pinned.pinned, isTrue);
    expect(pinned.updatedAt.isAfter(item.updatedAt), isTrue);

    clock.advance(const Duration(minutes: 1));
    await service.remove(item.id);

    final listed = await service.list(
      ContextScopeKind.chat,
      scopeId: 'chat-1',
    );
    expect(listed, isEmpty);
  });
}
