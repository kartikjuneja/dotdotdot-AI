import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/scope_keys.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/context_doc.dart';
import '../../domain/models/memory_item.dart';
import '../../domain/models/plan_node.dart';
import '../../domain/models/project.dart';

class ContextPage extends ConsumerStatefulWidget {
  const ContextPage({super.key});

  @override
  ConsumerState<ContextPage> createState() => _ContextPageState();
}

class _ContextPageState extends ConsumerState<ContextPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ContextScopeKind _scopeKind = ContextScopeKind.global;
  String? _scopeId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = GoRouterState.of(context).uri.queryParameters;
      final scope = q['scope'];
      final scopeId = q['scopeId'];
      final tab = q['tab'];
      if (scope != null) {
        try {
          setState(() {
            _scopeKind = ContextScopeKind.fromJson(scope);
            _scopeId = scopeId;
          });
        } catch (_) {}
      }
      if (tab == 'memory') {
        _tabs.index = 1;
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _setScope(ContextScopeKind kind, {String? scopeId}) {
    setState(() {
      _scopeKind = kind;
      _scopeId = kind == ContextScopeKind.global ? null : scopeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects =
        ref.watch(projectsStreamProvider).valueOrNull ?? const <Project>[];
    final plans =
        ref.watch(allPlansStreamProvider).valueOrNull ?? const <PlanNode>[];
    final chats =
        ref.watch(chatsStreamProvider).valueOrNull ?? const <Chat>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'Context & memory',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            'Notes and pins are attached to a place you can name — this app, '
            'a project, a plan, or a chat. They are merged into prompts '
            'automatically (chat → plan → project → global).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DotColors.textSecondary,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final kind in ContextScopeKind.values)
                ChoiceChip(
                  label: Text(_kindLabel(kind)),
                  selected: _scopeKind == kind,
                  onSelected: (_) => _setScope(
                    kind,
                    scopeId: _defaultIdFor(kind, projects, plans, chats),
                  ),
                ),
            ],
          ),
        ),
        if (_scopeKind != ContextScopeKind.global)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: _ScopePicker(
              kind: _scopeKind,
              selectedId: _scopeId,
              projects: projects,
              plans: plans,
              chats: chats,
              onSelected: (id) => _setScope(_scopeKind, scopeId: id),
            ),
          ),
        TabBar(
          controller: _tabs,
          labelColor: DotColors.ink,
          indicatorColor: DotColors.amber,
          tabs: const [
            Tab(text: 'Context docs'),
            Tab(text: 'Memory pins'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _ContextDocsPane(scopeKind: _scopeKind, scopeId: _scopeId),
              _MemoryPane(scopeKind: _scopeKind, scopeId: _scopeId),
            ],
          ),
        ),
      ],
    );
  }

  String? _defaultIdFor(
    ContextScopeKind kind,
    List<Project> projects,
    List<PlanNode> plans,
    List<Chat> chats,
  ) {
    return switch (kind) {
      ContextScopeKind.global => null,
      ContextScopeKind.project =>
        projects.isEmpty ? null : projects.first.id,
      ContextScopeKind.plan => plans.isEmpty
          ? null
          : (plans.where((n) => n.parentId == null).isNotEmpty
              ? plans.firstWhere((n) => n.parentId == null).id
              : plans.first.id),
      ContextScopeKind.chat => chats.isEmpty ? null : chats.first.id,
    };
  }
}

String _kindLabel(ContextScopeKind kind) => switch (kind) {
      ContextScopeKind.global => 'This app',
      ContextScopeKind.project => 'A project',
      ContextScopeKind.plan => 'A plan',
      ContextScopeKind.chat => 'A chat',
    };

class _ScopePicker extends StatelessWidget {
  const _ScopePicker({
    required this.kind,
    required this.selectedId,
    required this.projects,
    required this.plans,
    required this.chats,
    required this.onSelected,
  });

  final ContextScopeKind kind;
  final String? selectedId;
  final List<Project> projects;
  final List<PlanNode> plans;
  final List<Chat> chats;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = switch (kind) {
      ContextScopeKind.global => const <DropdownMenuItem<String>>[],
      ContextScopeKind.project => [
          for (final p in projects)
            DropdownMenuItem(value: p.id, child: Text(p.name)),
        ],
      ContextScopeKind.plan => [
          for (final n in _sortedPlans(plans))
            DropdownMenuItem(
              value: n.id,
              child: Text(
                n.parentId == null ? n.title : '↳ ${n.title}',
              ),
            ),
        ],
      ContextScopeKind.chat => [
          for (final c in chats)
            DropdownMenuItem(value: c.id, child: Text(c.title)),
        ],
    };

    if (items.isEmpty) {
      final hint = switch (kind) {
        ContextScopeKind.project => 'Create a project first, then add notes here.',
        ContextScopeKind.plan => 'Create a plan first, or generate one from a chat with /plan.',
        ContextScopeKind.chat => 'Start a chat, then attach notes to it.',
        ContextScopeKind.global => '',
      };
      return Text(hint, style: Theme.of(context).textTheme.bodyMedium);
    }

    final value = items.any((i) => i.value == selectedId) ? selectedId : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: switch (kind) {
          ContextScopeKind.project => 'Which project?',
          ContextScopeKind.plan => 'Which plan?',
          ContextScopeKind.chat => 'Which chat?',
          ContextScopeKind.global => '',
        },
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: const Text('Choose by name'),
          items: items,
          onChanged: onSelected,
        ),
      ),
    );
  }

  List<PlanNode> _sortedPlans(List<PlanNode> plans) {
    final roots = plans.where((n) => n.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final out = <PlanNode>[];
    void walk(PlanNode node) {
      out.add(node);
      final kids = plans.where((n) => n.parentId == node.id).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final k in kids) {
        walk(k);
      }
    }

    for (final r in roots) {
      walk(r);
    }
    for (final n in plans) {
      if (!out.any((e) => e.id == n.id)) out.add(n);
    }
    return out;
  }
}

class _ContextDocsPane extends ConsumerWidget {
  const _ContextDocsPane({required this.scopeKind, required this.scopeId});

  final ContextScopeKind scopeKind;
  final String? scopeId;

  bool get _scopeOk =>
      scopeKind == ContextScopeKind.global ||
      (scopeId != null && scopeId!.isNotEmpty);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_scopeOk) {
      return Center(
        child: Text(
          'Pick ${_kindLabel(scopeKind).toLowerCase()} above — no ids needed.',
        ),
      );
    }

    final docsAsync =
        ref.watch(contextDocsByScopeProvider((scopeKind, scopeId)));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _editDoc(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add context'),
            ),
          ),
        ),
        Expanded(
          child: docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (docs) {
              if (docs.isEmpty) {
                return const Center(
                  child: Text('No context docs in this scope.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return ListTile(
                    tileColor: DotColors.paperElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: DotColors.paperLine),
                    ),
                    title: Text(
                      doc.title,
                      style: const TextStyle(color: DotColors.textPrimary),
                    ),
                    subtitle: Text(
                      doc.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _editDoc(context, ref, existing: doc),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(contextRepositoryProvider).softDelete(
                              doc.id,
                              deletedAt: ref.read(clockProvider).now(),
                            );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editDoc(
    BuildContext context,
    WidgetRef ref, {
    ContextDoc? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add context' : 'Edit context'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Body'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text;
    titleCtrl.dispose();
    bodyCtrl.dispose();
    if (ok != true || title.isEmpty) return;

    final now = ref.read(clockProvider).now();
    final doc = ContextDoc(
      id: existing?.id ?? ref.read(uuidProvider).next(),
      scopeKind: scopeKind,
      scopeId: scopeKind == ContextScopeKind.global ? null : scopeId,
      title: title,
      body: body,
      fileRefs: existing?.fileRefs ?? const [],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(contextRepositoryProvider).save(doc);
  }
}

class _MemoryPane extends ConsumerWidget {
  const _MemoryPane({required this.scopeKind, required this.scopeId});

  final ContextScopeKind scopeKind;
  final String? scopeId;

  bool get _scopeOk =>
      scopeKind == ContextScopeKind.global ||
      (scopeId != null && scopeId!.isNotEmpty);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_scopeOk) {
      return Center(
        child: Text(
          'Pick ${_kindLabel(scopeKind).toLowerCase()} above — no ids needed.',
        ),
      );
    }

    final memAsync = ref.watch(_memoryProvider((scopeKind, scopeId)));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _addMemory(context, ref),
              icon: const Icon(Icons.push_pin_outlined),
              label: const Text('Pin memory'),
            ),
          ),
        ),
        Expanded(
          child: memAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No memory items yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    tileColor: DotColors.paperElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: DotColors.paperLine),
                    ),
                    leading: Icon(
                      item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: item.pinned ? DotColors.amberDeep : null,
                    ),
                    title: Text(
                      item.content,
                      style: const TextStyle(color: DotColors.textPrimary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: item.pinned ? 'Unpin' : 'Pin',
                          onPressed: () => ref
                              .read(memoryServiceProvider)
                              .pin(item.id, pinned: !item.pinned),
                          icon: const Icon(Icons.push_pin_outlined),
                        ),
                        IconButton(
                          onPressed: () =>
                              ref.read(memoryServiceProvider).remove(item.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addMemory(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pin memory'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Fact to remember…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final content = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || content.isEmpty) return;
    await ref.read(memoryServiceProvider).add(
          scopeKind: scopeKind,
          scopeId: scopeKind == ContextScopeKind.global ? null : scopeId,
          content: content,
          pinned: true,
        );
  }
}

final _memoryProvider =
    StreamProvider.family<List<MemoryItem>, ScopeKey>((ref, key) {
  final (kind, id) = key;
  return ref.watch(memoryRepositoryProvider).watchByScope(kind, scopeId: id);
});
