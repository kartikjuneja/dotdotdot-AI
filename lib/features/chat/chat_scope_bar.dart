import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/scope_keys.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/plan_node.dart';
import '../../domain/models/project.dart';
import 'chat_controller.dart';

/// Project / plan pickers plus a readable summary of what the model will see.
class ChatScopeBar extends ConsumerWidget {
  const ChatScopeBar({super.key, required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsStreamProvider).valueOrNull ??
        const <Project>[];
    final plans =
        ref.watch(allPlansStreamProvider).valueOrNull ?? const <PlanNode>[];
    final notifier = ref.read(chatControllerProvider(chat.id).notifier);

    final projectIds = {for (final p in projects) p.id};
    final planIds = {for (final n in plans) n.id};
    final projectValue =
        chat.projectId != null && projectIds.contains(chat.projectId)
            ? chat.projectId
            : null;
    final planValue =
        chat.planNodeId != null && planIds.contains(chat.planNodeId)
            ? chat.planNodeId
            : null;

    final visiblePlans = _plansForPicker(plans, projectValue, planValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: DotColors.paperElevated,
        border: Border(bottom: BorderSide(color: DotColors.paperLine)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _NamedDropdown<String?>(
            icon: Icons.folder_outlined,
            label: 'Project',
            value: projectValue,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No project'),
              ),
              for (final p in projects)
                DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: notifier.setProjectId,
          ),
          _NamedDropdown<String?>(
            icon: Icons.account_tree_outlined,
            label: 'Plan',
            value: planValue,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No linked plan'),
              ),
              for (final n in visiblePlans)
                DropdownMenuItem<String?>(
                  value: n.id,
                  child: Text(
                    n.parentId == null ? n.title : '↳ ${n.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: notifier.setPlanNodeId,
          ),
          _ContextSummary(chat: chat, projects: projects, plans: plans),
          OutlinedButton.icon(
            onPressed: () => context.go(
              '/context?scope=chat&scopeId=${chat.id}',
            ),
            icon: const Icon(Icons.notes_outlined, size: 16),
            label: const Text('Chat notes'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: DotColors.inkMuted,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => notifier.sendMessage(overrideText: '/plan'),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Generate plan'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFFFFE8B8),
              foregroundColor: DotColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  List<PlanNode> _plansForPicker(
    List<PlanNode> plans,
    String? projectId,
    String? currentPlanId,
  ) {
    final roots = plans.where((n) {
      if (n.parentId != null) return false;
      if (projectId == null) return true;
      return n.projectId == null || n.projectId == projectId;
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    if (currentPlanId == null) return roots;
    if (roots.any((n) => n.id == currentPlanId)) return roots;
    PlanNode? current;
    for (final n in plans) {
      if (n.id == currentPlanId) {
        current = n;
        break;
      }
    }
    if (current == null) return roots;
    return [current, ...roots];
  }
}

class _NamedDropdown<T> extends StatelessWidget {
  const _NamedDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        border: Border.all(color: DotColors.paperLine),
        borderRadius: BorderRadius.circular(10),
        color: DotColors.paper,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DotColors.inkMuted),
          const SizedBox(width: 6),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isDense: true,
                isExpanded: true,
                value: value,
                hint: Text(label),
                items: items,
                onChanged: (v) {
                  if (v != null || null is T) onChanged(v as T);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextSummary extends ConsumerWidget {
  const _ContextSummary({
    required this.chat,
    required this.projects,
    required this.plans,
  });

  final Chat chat;
  final List<Project> projects;
  final List<PlanNode> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalDocs = ref
            .watch(contextDocsByScopeProvider((ContextScopeKind.global, null)))
            .valueOrNull ??
        const [];
    final projectDocs = chat.projectId == null
        ? const []
        : ref
                .watch(
                  contextDocsByScopeProvider(
                    (ContextScopeKind.project, chat.projectId),
                  ),
                )
                .valueOrNull ??
            const [];
    final planDocs = chat.planNodeId == null
        ? const []
        : ref
                .watch(
                  contextDocsByScopeProvider(
                    (ContextScopeKind.plan, chat.planNodeId),
                  ),
                )
                .valueOrNull ??
            const [];
    final chatDocs = ref
            .watch(contextDocsByScopeProvider((ContextScopeKind.chat, chat.id)))
            .valueOrNull ??
        const [];

    final projectName = _nameFor(
      chat.projectId,
      {for (final p in projects) p.id: p.name},
    );
    final planName = _nameFor(
      chat.planNodeId,
      {for (final n in plans) n.id: n.title},
    );

    final parts = <String>[
      if (globalDocs.isNotEmpty) 'Global (${globalDocs.length})',
      if (projectName != null)
        'Project: $projectName${projectDocs.isEmpty ? '' : ' (${projectDocs.length})'}',
      if (planName != null)
        'Plan: $planName${planDocs.isEmpty ? '' : ' (${planDocs.length})'}',
      if (chatDocs.isNotEmpty) 'This chat (${chatDocs.length})',
    ];

    return ActionChip(
      avatar: const Icon(Icons.layers_outlined, size: 16),
      label: Text(
        parts.isEmpty
            ? 'No extra context — model only sees this thread'
            : 'Context: ${parts.join(' → ')}',
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _showExplainer(context, parts),
    );
  }

  String? _nameFor(String? id, Map<String, String> names) {
    if (id == null) return null;
    return names[id];
  }

  void _showExplainer(BuildContext context, List<String> parts) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What the model sees',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Custom notes and memory are merged nearest-first: '
                'this chat, then the linked plan, then the project, then global. '
                'Pick a project or plan by name above — you never need an id.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DotColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              if (parts.isEmpty)
                const Text('Nothing extra is injected yet.')
              else
                for (final p in parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: DotColors.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p)),
                      ],
                    ),
                  ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).go(
                      '/context?scope=chat&scopeId=${chat.id}',
                    );
                  },
                  child: const Text('Edit notes for this chat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
