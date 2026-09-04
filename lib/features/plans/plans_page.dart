import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/plan_node.dart';
import 'plan_controller.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = GoRouterState.of(context).uri.queryParameters['projectId'];
    final plansAsync = ref.watch(rootPlansProvider(projectId));
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Plans / Courses',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _createRoot(context, ref, projectId),
                icon: const Icon(Icons.add),
                label: const Text('New plan'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            projectId == null
                ? 'Nested plans with progress. Optionally filter by project.'
                : 'Plans for this project.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DotColors.textSecondary,
                ),
          ),
        ),
        if (projectsAsync.valueOrNull != null &&
            projectsAsync.valueOrNull!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: projectId == null,
                  onSelected: (_) => context.go('/plans'),
                ),
                for (final p in projectsAsync.valueOrNull!)
                  FilterChip(
                    label: Text(p.name),
                    selected: projectId == p.id,
                    onSelected: (_) => context.go('/plans?projectId=${p.id}'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (plans) {
              if (plans.isEmpty) {
                return const Center(
                  child: Text(
                    'No root plans yet. Create one here, or type /plan in any chat.',
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return ListTile(
                    tileColor: DotColors.paperElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: DotColors.paperLine),
                    ),
                    title: Text(
                      plan.title,
                      style: const TextStyle(color: DotColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${plan.progress}% · ${plan.status.name}',
                      style: const TextStyle(color: DotColors.textSecondary),
                    ),
                    trailing: SizedBox(
                      width: 96,
                      child: LinearProgressIndicator(
                        value: plan.progress / 100,
                        backgroundColor: DotColors.paperLine,
                        color: DotColors.amber,
                      ),
                    ),
                    onTap: () => context.go('/plans/${plan.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createRoot(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New plan'),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (ok != true || title.isEmpty) return;

    final now = ref.read(clockProvider).now();
    final roots = await ref
        .read(planRepositoryProvider)
        .listChildren(null, projectId: projectId);
    final node = PlanNode(
      id: ref.read(uuidProvider).next(),
      projectId: projectId,
      parentId: null,
      title: title,
      body: '',
      progress: 0,
      status: PlanNodeStatus.active,
      sortOrder: roots.length,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(planRepositoryProvider).save(node);
    if (context.mounted) context.go('/plans/${node.id}');
  }
}
