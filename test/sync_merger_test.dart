import 'package:dotdotdot_ai/data/sync/sync_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const merger = SyncMerger();

  group('SyncMerger.mergeMaps', () {
    test('inserts remote-only rows', () {
      final out = merger.mergeMaps(
        local: {},
        remote: {
          'a': {'id': 'a', 'title': 'Remote', 'updatedAt': '2026-01-02T00:00:00.000Z'},
        },
        titleField: 'title',
      );
      expect(out['a']?['title'], 'Remote');
    });

    test('last-write-wins by updatedAt', () {
      final out = merger.mergeMaps(
        local: {
          'a': {
            'id': 'a',
            'title': 'Local',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
        },
        remote: {
          'a': {
            'id': 'a',
            'title': 'Remote',
            'updatedAt': '2026-01-03T00:00:00.000Z',
          },
        },
        titleField: 'title',
      );
      expect(out['a']?['title'], 'Remote');
      expect(out.length, 1);
    });

    test('keeps local and writes conflict copy on equal timestamps', () {
      final out = merger.mergeMaps(
        local: {
          'a': {
            'id': 'a',
            'title': 'Local',
            'updatedAt': '2026-01-02T00:00:00.000Z',
          },
        },
        remote: {
          'a': {
            'id': 'a',
            'title': 'Remote',
            'updatedAt': '2026-01-02T00:00:00.000Z',
          },
        },
        titleField: 'title',
      );
      expect(out['a']?['title'], 'Local');
      final conflict = out.values.where((r) => (r['id'] as String).contains('_conflict_'));
      expect(conflict.length, 1);
      expect(conflict.first['title'], startsWith('[conflict]'));
    });
  });
}
