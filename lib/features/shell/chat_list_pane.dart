import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/project.dart';

class ChatListPane extends ConsumerWidget {
  const ChatListPane({super.key, this.projectId});

  /// When set, only lists chats for this project.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = projectId == null
        ? ref.watch(chatsStreamProvider)
        : ref.watch(_projectChatsProvider(projectId!));
    final projectsAsync = ref.watch(projectsStreamProvider);
    final location = GoRouterState.of(context).uri.path;

    return chatsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Could not load chats.\n$e',
            style: const TextStyle(color: DotColors.paper)),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No chats yet.',
              style: TextStyle(color: Color(0xFFB8C4CE)),
            ),
          );
        }
        final projects = projectsAsync.valueOrNull ?? const <Project>[];
        final byId = {for (final p in projects) p.id: p};

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final selected = location == '/chat/${chat.id}';
            final project = chat.projectId == null
                ? null
                : byId[chat.projectId!];
            return _ChatTile(
              chat: chat,
              projectName: project?.name,
              selected: selected,
              onTap: () => context.go('/chat/${chat.id}'),
              onRename: () => _renameChat(context, ref, chat),
              onDelete: () => _deleteChat(context, ref, chat),
              onNotes: () => context.go(
                '/context?scope=chat&scopeId=${chat.id}',
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _renameChat(BuildContext context, WidgetRef ref, Chat chat) async {
  final ctrl = TextEditingController(text: chat.title);
  final next = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename chat'),
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
  await ref.read(chatRepositoryProvider).save(
        chat.copyWith(title: next, updatedAt: ref.read(clockProvider).now()),
      );
}

Future<void> _deleteChat(BuildContext context, WidgetRef ref, Chat chat) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete chat?'),
      content: Text('“${chat.title}” will be removed from this device.'),
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
  await ref.read(chatRepositoryProvider).softDelete(
        chat.id,
        deletedAt: ref.read(clockProvider).now(),
      );
  if (context.mounted && GoRouterState.of(context).uri.path == '/chat/${chat.id}') {
    context.go('/');
  }
}

final _projectChatsProvider =
    StreamProvider.family<List<Chat>, String>((ref, projectId) {
  return ref.watch(chatRepositoryProvider).watchAll(projectId: projectId);
});

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onNotes,
    this.projectName,
  });

  final Chat chat;
  final String? projectName;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd().add_jm();
    return ListTile(
      selected: selected,
      onTap: onTap,
      title: Text(
        chat.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? DotColors.amber : DotColors.paper,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (projectName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DotColors.inkSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  projectName!,
                  style: const TextStyle(
                    color: DotColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Text(
            fmt.format(chat.updatedAt.toLocal()),
            style: TextStyle(
              color: DotColors.paper.withOpacity(0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: DotColors.paper.withOpacity(0.55),
        ),
        onSelected: (value) {
          switch (value) {
            case 'notes':
              onNotes();
            case 'rename':
              onRename();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'notes', child: Text('Add notes')),
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
