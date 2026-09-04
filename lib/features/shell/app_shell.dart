import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import 'chat_list_pane.dart';

const double _wideBreakpoint = 800;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location) {
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/plans')) return 2;
    if (location.startsWith('/settings') || location.startsWith('/context')) {
      return 3;
    }
    return 0; // chats / home / chat detail
  }

  void _goIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/projects');
      case 2:
        context.go('/plans');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);
    final wide = MediaQuery.sizeOf(context).width > _wideBreakpoint;

    final navBody = wide
        ? Row(
            children: [
              _Sidebar(
                selectedIndex: selected,
                onSelect: (i) => _goIndex(context, i),
                onNewChat: () => openNewChat(context, ref),
              ),
              VerticalDivider(
                width: 1,
                color: DotColors.paperLine.withOpacity(0.5),
              ),
              Expanded(child: child),
            ],
          )
        : child;

    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: Text(
                _mobileTitle(location),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
                IconButton(
                  tooltip: 'New chat',
                  onPressed: () => openNewChat(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _SidebarContent(
                  selectedIndex: selected,
                  onSelect: (i) {
                    Navigator.of(context).pop();
                    _goIndex(context, i);
                  },
                  onNewChat: () {
                    Navigator.of(context).pop();
                    openNewChat(context, ref);
                  },
                ),
              ),
            ),
      body: navBody,
    );
  }

  String _mobileTitle(String location) {
    if (location.startsWith('/projects')) return 'Projects';
    if (location.startsWith('/plans')) return 'Plans';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith('/context')) return 'Context';
    if (location.startsWith('/chat/')) return 'Chat';
    return 'DotDotDot';
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onNewChat,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Material(
        color: DotColors.ink,
        child: SafeArea(
          child: _SidebarContent(
            selectedIndex: selectedIndex,
            onSelect: onSelect,
            onNewChat: onNewChat,
          ),
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.selectedIndex,
    required this.onSelect,
    required this.onNewChat,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final paper = DotColors.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'DotDotDot',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: paper,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: DotColors.amber,
              foregroundColor: DotColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onNewChat,
            icon: const Icon(Icons.add),
            label: const Text('New chat'),
          ),
        ),
        const SizedBox(height: 4),
        _NavTile(
          icon: Icons.chat_bubble_outline,
          label: 'Chats',
          selected: selectedIndex == 0,
          onTap: () => onSelect(0),
        ),
        _NavTile(
          icon: Icons.folder_outlined,
          label: 'Projects',
          selected: selectedIndex == 1,
          onTap: () => onSelect(1),
        ),
        _NavTile(
          icon: Icons.account_tree_outlined,
          label: 'Plans / Courses',
          selected: selectedIndex == 2,
          onTap: () => onSelect(2),
        ),
        _NavTile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          selected: selectedIndex == 3,
          onTap: () => onSelect(3),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Recent',
            style: TextStyle(
              color: DotColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Expanded(child: ChatListPane()),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: TextButton(
            onPressed: () {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              GoRouter.of(context).go('/context');
            },
            style: TextButton.styleFrom(foregroundColor: DotColors.amber),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Context & memory'),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DotColors.amber : DotColors.paper.withOpacity(0.75);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        selected: selected,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
