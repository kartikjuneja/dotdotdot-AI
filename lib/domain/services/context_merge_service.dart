import '../models/context_doc.dart';
import '../models/memory_item.dart';

/// Merges scoped context (and optional memory) into a single prompt block.
///
/// Inheritance order in the output:
/// global → project → plan ancestors (root → current) → chat.
///
/// When over [charBudget], farther scopes are trimmed/dropped first so nearer
/// scopes are preferred.
class ContextMergeService {
  const ContextMergeService({this.defaultCharBudget = 12000});

  final int defaultCharBudget;

  /// Merges plain text parts. Empty strings are skipped.
  String merge({
    List<String> global = const [],
    List<String> project = const [],
    List<String> planAncestors = const [],
    List<String> chat = const [],
    int? charBudget,
  }) {
    final budget = charBudget ?? defaultCharBudget;
    final sections = <_Section>[
      _Section(label: 'global', text: _joinParts(global)),
      _Section(label: 'project', text: _joinParts(project)),
      for (var i = 0; i < planAncestors.length; i++)
        _Section(label: 'plan:$i', text: planAncestors[i].trim()),
      _Section(label: 'chat', text: _joinParts(chat)),
    ].where((s) => s.text.isNotEmpty).toList();

    final selected = <int, String>{};
    var used = 0;

    // Prefer nearer scopes: allocate from the end (chat) toward global.
    for (var i = sections.length - 1; i >= 0; i--) {
      final header = '### ${sections[i].label}\n';
      final sep = selected.isEmpty ? 0 : 2; // `\n\n` when joining
      final room = budget - used - sep - header.length;
      if (room <= 0) continue;

      final text = sections[i].text;
      final body = text.length <= room ? text : text.substring(0, room);
      final piece = '$header$body';
      selected[i] = piece;
      used += sep + piece.length;
    }

    final out = [
      for (var i = 0; i < sections.length; i++)
        if (selected.containsKey(i)) selected[i]!,
    ].join('\n\n');

    if (out.length <= budget) return out;
    return out.substring(0, budget);
  }

  /// Convenience merge from domain entities.
  ///
  /// [planAncestorDocs] should be ordered root → current. Memory lists are
  /// packed into the matching scope tier.
  String mergeEntities({
    List<ContextDoc> globalDocs = const [],
    List<ContextDoc> projectDocs = const [],
    List<ContextDoc> planAncestorDocs = const [],
    List<ContextDoc> chatDocs = const [],
    List<MemoryItem> globalMemory = const [],
    List<MemoryItem> projectMemory = const [],
    List<MemoryItem> planAncestorMemory = const [],
    List<MemoryItem> chatMemory = const [],
    int? charBudget,
  }) {
    return merge(
      global: [_packScope(globalDocs, globalMemory)],
      project: [_packScope(projectDocs, projectMemory)],
      planAncestors: [
        for (final doc in planAncestorDocs) _packScope([doc], const []),
        if (planAncestorMemory.isNotEmpty)
          _packScope(const [], planAncestorMemory),
      ],
      chat: [_packScope(chatDocs, chatMemory)],
      charBudget: charBudget,
    );
  }

  static String _joinParts(List<String> parts) =>
      parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join('\n\n');

  static String _packScope(List<ContextDoc> docs, List<MemoryItem> memory) {
    final docText = docs
        .where((d) => !d.isDeleted)
        .map((d) {
          final title = d.title.trim();
          final body = d.body.trim();
          if (title.isEmpty) return body;
          if (body.isEmpty) return title;
          return '$title\n$body';
        })
        .where((s) => s.isNotEmpty)
        .join('\n\n');

    final memItems = [...memory.where((m) => !m.isDeleted)]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });
    final memText = memItems
        .map((m) => m.content.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');

    if (docText.isEmpty) return memText.isEmpty ? '' : 'Memory:\n$memText';
    if (memText.isEmpty) return docText;
    return '$docText\n\nMemory:\n$memText';
  }
}

class _Section {
  _Section({required this.label, required this.text});

  final String label;
  final String text;
}
