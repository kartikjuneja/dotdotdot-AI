/// Last-write-wins merge of remote backup rows into local maps (by uuid).
///
/// Soft-delete aware via `updatedAt` / `deletedAt`. When both sides diverge
/// with equal timestamps but different content, keeps local and writes a
/// conflict copy of remote with id suffix `_conflict_<ts>` and a `[conflict]`
/// title/name prefix where applicable.
class SyncMerger {
  const SyncMerger();

  /// Merge one entity collection. Returns merged rows (map by id).
  Map<String, Map<String, dynamic>> mergeMaps({
    required Map<String, Map<String, dynamic>> local,
    required Map<String, Map<String, dynamic>> remote,
    required String titleField,
    DateTime? Function(Map<String, dynamic>)? timestampOf,
  }) {
    final tsOf = timestampOf ?? _defaultTimestamp;
    final out = <String, Map<String, dynamic>>{
      for (final e in local.entries) e.key: Map<String, dynamic>.from(e.value),
    };

    for (final entry in remote.entries) {
      final id = entry.key;
      final remoteRow = Map<String, dynamic>.from(entry.value);
      final localRow = out[id];

      if (localRow == null) {
        out[id] = remoteRow;
        continue;
      }

      if (_mapsEqual(localRow, remoteRow)) {
        continue;
      }

      final localTs = tsOf(localRow);
      final remoteTs = tsOf(remoteRow);

      if (remoteTs != null &&
          (localTs == null || remoteTs.isAfter(localTs))) {
        out[id] = remoteRow;
        continue;
      }

      if (localTs != null &&
          (remoteTs == null || localTs.isAfter(remoteTs))) {
        // Local wins — no conflict copy needed for pure LWW.
        continue;
      }

      // Equal (or missing) timestamps but different content → conflict.
      final conflict = _asConflictCopy(
        remoteRow,
        titleField: titleField,
      );
      out[id] = Map<String, dynamic>.from(localRow);
      out[conflict['id'] as String] = conflict;
    }

    return out;
  }

  /// Merge a full backup package pair into entity maps.
  MergedStores mergePackages({
    required List<Map<String, dynamic>> localChats,
    required List<Map<String, dynamic>> localMessages,
    required List<Map<String, dynamic>> localProjects,
    required List<Map<String, dynamic>> localPlans,
    required List<Map<String, dynamic>> localMemory,
    required List<Map<String, dynamic>> localContext,
    required List<Map<String, dynamic>> localProviders,
    required List<Map<String, dynamic>> remoteChats,
    required List<Map<String, dynamic>> remoteMessages,
    required List<Map<String, dynamic>> remoteProjects,
    required List<Map<String, dynamic>> remotePlans,
    required List<Map<String, dynamic>> remoteMemory,
    required List<Map<String, dynamic>> remoteContext,
    required List<Map<String, dynamic>> remoteProviders,
  }) {
    final chats = mergeMaps(
      local: _index(_withSoftDeleteTs(localChats)),
      remote: _index(_withSoftDeleteTs(remoteChats)),
      titleField: 'title',
    );
    final projects = mergeMaps(
      local: _index(_withSoftDeleteTs(localProjects)),
      remote: _index(_withSoftDeleteTs(remoteProjects)),
      titleField: 'name',
    );
    final plans = mergeMaps(
      local: _index(_withSoftDeleteTs(localPlans)),
      remote: _index(_withSoftDeleteTs(remotePlans)),
      titleField: 'title',
    );
    final memory = mergeMaps(
      local: _index(_withSoftDeleteTs(localMemory)),
      remote: _index(_withSoftDeleteTs(remoteMemory)),
      titleField: 'content',
    );
    final context = mergeMaps(
      local: _index(_withSoftDeleteTs(localContext)),
      remote: _index(_withSoftDeleteTs(remoteContext)),
      titleField: 'title',
    );
    final providers = mergeMaps(
      local: _index(_withSoftDeleteTs(localProviders)),
      remote: _index(_withSoftDeleteTs(remoteProviders)),
      titleField: 'displayName',
    );
    final messages = mergeMaps(
      local: _index(localMessages),
      remote: _index(remoteMessages),
      titleField: 'text',
      timestampOf: (m) => _parseTs(m['createdAt']),
    );

    return MergedStores(
      chats: chats.values.toList(growable: false),
      messages: messages.values.toList(growable: false),
      projects: projects.values.toList(growable: false),
      plans: plans.values.toList(growable: false),
      memory: memory.values.toList(growable: false),
      context: context.values.toList(growable: false),
      providers: providers.values.toList(growable: false),
      conflictCount: [
        ...chats.keys,
        ...messages.keys,
        ...projects.keys,
        ...plans.keys,
        ...memory.keys,
        ...context.keys,
        ...providers.keys,
      ].where((id) => id.contains('_conflict_')).length,
    );
  }

  static Map<String, Map<String, dynamic>> _index(
    List<Map<String, dynamic>> rows,
  ) {
    final map = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null) continue;
      map[id] = Map<String, dynamic>.from(row);
    }
    return map;
  }

  /// Ensure soft-deleted rows participate in LWW via updatedAt.
  static List<Map<String, dynamic>> _withSoftDeleteTs(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final deletedAt = copy['deletedAt'];
      final updatedAt = copy['updatedAt'];
      if (deletedAt != null && updatedAt == null) {
        copy['updatedAt'] = deletedAt;
      }
      return copy;
    }).toList(growable: false);
  }

  static DateTime? _defaultTimestamp(Map<String, dynamic> row) {
    return _parseTs(row['updatedAt']) ?? _parseTs(row['createdAt']);
  }

  static DateTime? _parseTs(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  static Map<String, dynamic> _asConflictCopy(
    Map<String, dynamic> remote, {
    required String titleField,
  }) {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final baseId = remote['id'] as String? ?? 'unknown';
    final copy = Map<String, dynamic>.from(remote);
    copy['id'] = '${baseId}_conflict_$ts';
    final title = copy[titleField];
    if (title is String) {
      if (!title.startsWith('[conflict]')) {
        copy[titleField] = '[conflict] $title';
      }
    }
    final now = DateTime.now().toUtc().toIso8601String();
    if (copy.containsKey('updatedAt')) {
      copy['updatedAt'] = now;
    }
    return copy;
  }

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final av = a[key];
      final bv = b[key];
      if (av is Map && bv is Map) {
        if (!_mapsEqual(
          Map<String, dynamic>.from(av),
          Map<String, dynamic>.from(bv),
        )) {
          return false;
        }
      } else if (av is List && bv is List) {
        if (av.length != bv.length) return false;
        for (var i = 0; i < av.length; i++) {
          if (av[i] != bv[i]) return false;
        }
      } else if (av != bv) {
        return false;
      }
    }
    return true;
  }
}

class MergedStores {
  const MergedStores({
    required this.chats,
    required this.messages,
    required this.projects,
    required this.plans,
    required this.memory,
    required this.context,
    required this.providers,
    required this.conflictCount,
  });

  final List<Map<String, dynamic>> chats;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> memory;
  final List<Map<String, dynamic>> context;
  final List<Map<String, dynamic>> providers;
  final int conflictCount;
}
