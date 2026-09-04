import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/chat_page.dart';
import '../features/context/context_page.dart';
import '../features/plans/plan_tree_page.dart';
import '../features/plans/plans_page.dart';
import '../features/projects/project_detail_page.dart';
import '../features/projects/projects_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _HomeLanding(),
            ),
          ),
          GoRoute(
            path: '/chat/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: ChatPage(chatId: id));
            },
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectsPage(),
            ),
          ),
          GoRoute(
            path: '/projects/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: ProjectDetailPage(projectId: id));
            },
          ),
          GoRoute(
            path: '/plans',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlansPage(),
            ),
          ),
          GoRoute(
            path: '/plans/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: PlanTreePage(planId: id));
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/context',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContextPage(),
            ),
          ),
        ],
      ),
    ],
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter();
});

class _HomeLanding extends ConsumerWidget {
  const _HomeLanding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DotDotDot',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Local-first AI studio. Recent chats stay in the sidebar. '
                'Type /plan in a chat to save a course, or attach a project by name '
                'so its notes are included automatically.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => openNewChat(context, ref),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('New chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
