import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/project.dart';

final _projectProvider =
    FutureProvider.family<Project?, String>((ref, id) async {
  return ref.watch(projectRepositoryProvider).getById(id);
});

final _projectChatsProvider =
    StreamProvider.family<List<Chat>, String>((ref, projectId) {
  return ref.watch(chatRepositoryProvider).watchAll(projectId: projectId);
});

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(_projectProvider(projectId));
    final chatsAsync = ref.watch(_projectChatsProvider(projectId));

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (project) {
        if (project == null) {
          return const Center(child: Text('Project not found'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/projects'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (project.description.isNotEmpty)
                          Text(
                            project.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: DotColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(
                      '/context?scope=project&scopeId=$projectId',
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Context'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => openNewChat(
                      context,
                      ref,
                      projectId: projectId,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('New chat'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(
                      '/context?scope=project&scopeId=$projectId&tab=memory',
                    ),
                    icon: const Icon(Icons.push_pin_outlined, size: 18),
                    label: const Text('Memory pins'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/plans?projectId=$projectId'),
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    label: const Text('Plans'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Chats in this project',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: chatsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (chats) {
                  if (chats.isEmpty) {
                    return const Center(
                      child: Text('No chats in this project yet.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return ListTile(
                        title: Text(
                          chat.title,
                          style: const TextStyle(color: DotColors.textPrimary),
                        ),
                        subtitle: Text(chat.modelId),
                        onTap: () => context.go('/chat/${chat.id}'),
                        trailing: TextButton(
                          onPressed: () => _moveOut(ref, chat),
                          child: const Text('Move out'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveOut(WidgetRef ref, Chat chat) async {
    await ref.read(chatRepositoryProvider).save(
          chat.copyWith(
            projectId: null,
            updatedAt: ref.read(clockProvider).now(),
          ),
        );
  }
}
