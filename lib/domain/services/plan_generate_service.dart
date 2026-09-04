import 'dart:convert';

import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/ids.dart';
import '../models/plan_node.dart';
import '../repositories/plan_repository.dart';

/// Nested plan/course draft produced by the model (or parsed from chat).
class PlanTreeDraft {
  const PlanTreeDraft({
    required this.title,
    this.body = '',
    this.progress = 0,
    this.status = PlanNodeStatus.active,
    this.children = const [],
  });

  final String title;
  final String body;
  final int progress;
  final PlanNodeStatus status;
  final List<PlanTreeDraft> children;

  int get nodeCount =>
      1 + children.fold<int>(0, (sum, child) => sum + child.nodeCount);
}

/// Parses `plan-create` JSON from assistant text and persists a nested tree.
class PlanGenerateService {
  const PlanGenerateService({
    this.maxDepth = 8,
    this.maxNodes = 50,
  });

  final int maxDepth;
  final int maxNodes;

  static final _fence = RegExp(
    r'```(?:plan-create|plan)\s*([\s\S]*?)```',
    multiLine: true,
  );

  /// Extracts the first plan-create / plan fenced JSON block, if any.
  PlanTreeDraft? extractFromAssistantText(String text) {
    final match = _fence.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return parseTree(Map<String, dynamic>.from(decoded));
  }

  PlanTreeDraft parseTree(Map<String, dynamic> json, {int depth = 0}) {
    if (depth > maxDepth) {
      throw AppException('Plan tree exceeds max depth of $maxDepth');
    }
    final title = (json['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw const AppException('Plan tree node is missing a title');
    }
    final body = json['body'] as String? ?? '';
    final progress = _asInt(json['progress']) ?? 0;
    if (progress < 0 || progress > 100) {
      throw AppException('Plan progress must be 0–100, got $progress');
    }
    var status = PlanNodeStatus.active;
    final statusRaw = json['status'];
    if (statusRaw is String && statusRaw.isNotEmpty) {
      try {
        status = PlanNodeStatus.fromJson(statusRaw);
      } on ArgumentError catch (e) {
        throw AppException(
          'Plan status must be active|done|archived',
          cause: e,
        );
      }
    }

    final rawChildren = json['children'];
    final children = <PlanTreeDraft>[];
    if (rawChildren is List) {
      for (final child in rawChildren) {
        if (child is! Map) continue;
        children.add(
          parseTree(Map<String, dynamic>.from(child), depth: depth + 1),
        );
      }
    }

    final draft = PlanTreeDraft(
      title: title,
      body: body,
      progress: progress,
      status: status,
      children: children,
    );
    if (depth == 0 && draft.nodeCount > maxNodes) {
      throw AppException(
        'Plan tree has ${draft.nodeCount} nodes; max is $maxNodes',
      );
    }
    return draft;
  }

  /// Saves [draft] as a new root plan plus nested children. Returns the root.
  Future<PlanNode> persistTree({
    required PlanTreeDraft draft,
    required PlanRepository repo,
    required UuidV4 ids,
    required Clock clock,
    String? projectId,
    String? parentId,
  }) async {
    if (draft.nodeCount > maxNodes) {
      throw AppException(
        'Plan tree has ${draft.nodeCount} nodes; max is $maxNodes',
      );
    }
    final now = clock.now();
    final siblings = await repo.listChildren(parentId, projectId: projectId);
    return _persistNode(
      draft: draft,
      repo: repo,
      ids: ids,
      now: now,
      projectId: projectId,
      parentId: parentId,
      sortOrder: siblings.length,
    );
  }

  Future<PlanNode> _persistNode({
    required PlanTreeDraft draft,
    required PlanRepository repo,
    required UuidV4 ids,
    required DateTime now,
    required String? projectId,
    required String? parentId,
    required int sortOrder,
  }) async {
    final node = PlanNode(
      id: ids.next(),
      projectId: projectId,
      parentId: parentId,
      title: draft.title,
      body: draft.body,
      progress: draft.progress,
      status: draft.status,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await repo.save(node);
    for (var i = 0; i < draft.children.length; i++) {
      await _persistNode(
        draft: draft.children[i],
        repo: repo,
        ids: ids,
        now: now,
        projectId: projectId,
        parentId: node.id,
        sortOrder: i,
      );
    }
    return node;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// System-prompt addendum so the model can emit a savable plan from any chat.
const String planCreateSystemAddendum = '''
You can turn this conversation into a nested plan or course at any time.
When the user asks for a plan, course, outline, or uses /plan or /course,
end your reply with a fenced JSON block the app will save automatically:

```plan-create
{"title":"Course title","body":"Short overview","children":[{"title":"Module 1","body":"What to do","children":[{"title":"Step","body":"...","children":[]}]}]}
```

Rules:
- Only include the fence when you are actually creating a plan.
- Keep it practical: typically 4–12 nodes, max depth 4.
- Every node needs a non-empty "title". "body" is optional markdown.
- Do not invent ids. The app assigns them.
''';

const String planPatchSystemAddendum = '''
This chat is linked to an existing plan. When you update that plan, include:

```plan-patch
{"title":"...","body":"...","progress":0,"status":"active"}
```

Only include fields you intend to change (title, body, progress 0–100, status active|done|archived).
You may still emit a ```plan-create``` block to save a *new* plan from this chat.
''';
