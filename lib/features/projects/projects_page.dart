import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/project.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  'Projects',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _createProject(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New project'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Group chats, plans, and scoped memory.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DotColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (projects) {
              if (projects.isEmpty) {
                return const Center(child: Text('No projects yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ListTile(
                    tileColor: DotColors.paperElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: DotColors.paperLine),
                    ),
                    title: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: DotColors.textPrimary,
                          ),
                    ),
                    subtitle: project.description.isEmpty
                        ? null
                        : Text(
                            project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: DotColors.textSecondary),
                          ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'rename':
                            await _renameProject(context, ref, project);
                          case 'delete':
                            await _deleteProject(context, ref, project);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => context.go('/projects/${project.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
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
    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    nameCtrl.dispose();
    descCtrl.dispose();
    if (ok != true || name.isEmpty) return;

    final now = ref.read(clockProvider).now();
    final project = Project(
      id: ref.read(uuidProvider).next(),
      name: name,
      description: desc,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(projectRepositoryProvider).save(project);
    if (context.mounted) context.go('/projects/${project.id}');
  }

  Future<void> _renameProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final ctrl = TextEditingController(text: project.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (next == null || next.isEmpty) return;
    await ref.read(projectRepositoryProvider).save(
          project.copyWith(
            name: next,
            updatedAt: ref.read(clockProvider).now(),
          ),
        );
  }

  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('Soft-delete “${project.name}”. Chats remain but unlink later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(projectRepositoryProvider).softDelete(
          project.id,
          deletedAt: ref.read(clockProvider).now(),
        );
  }
}
