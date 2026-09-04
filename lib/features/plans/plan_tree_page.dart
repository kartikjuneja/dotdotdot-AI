import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/plan_node.dart';
import 'plan_controller.dart';

class PlanTreePage extends ConsumerWidget {
  const PlanTreePage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planControllerProvider(planId));
    final controller = ref.read(planControllerProvider(planId).notifier);

    if (state.error != null && state.root == null) {
      return Center(child: Text(state.error!));
    }
    final root = state.root;
    if (root == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final byParent = state.childrenByParent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/plans'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  root.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => openNewChat(
                  context,
                  ref,
                  projectId: root.projectId,
                  planNodeId: root.id,
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Open plan chat'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _addChild(context, controller, parentId: root.id),
                icon: const Icon(Icons.add),
                label: const Text('Add child'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _PlanNodeTile(
                node: root,
                depth: 0,
                controller: controller,
                onOpenChat: () => openNewChat(
                  context,
                  ref,
                  projectId: root.projectId,
                  planNodeId: root.id,
                ),
              ),
              ..._buildChildren(
                context,
                ref,
                controller,
                byParent,
                parentId: root.id,
                depth: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren(
    BuildContext context,
    WidgetRef ref,
    PlanController controller,
    Map<String?, List<PlanNode>> byParent, {
    required String parentId,
    required int depth,
  }) {
    final children = byParent[parentId] ?? const [];
    final widgets = <Widget>[];
    for (final child in children) {
      widgets.add(
        _PlanNodeTile(
          node: child,
          depth: depth,
          controller: controller,
          onOpenChat: () => openNewChat(
            context,
            ref,
            projectId: child.projectId,
            planNodeId: child.id,
          ),
        ),
      );
      widgets.addAll(
        _buildChildren(
          context,
          ref,
          controller,
          byParent,
          parentId: child.id,
          depth: depth + 1,
        ),
      );
    }
    return widgets;
  }

  Future<void> _addChild(
    BuildContext context,
    PlanController controller, {
    required String parentId,
  }) async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add child node'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (ok == true && title.isNotEmpty) {
      await controller.addChild(parentId: parentId, title: title);
    }
  }
}

class _PlanNodeTile extends StatefulWidget {
  const _PlanNodeTile({
    required this.node,
    required this.depth,
    required this.controller,
    required this.onOpenChat,
  });

  final PlanNode node;
  final int depth;
  final PlanController controller;
  final VoidCallback onOpenChat;

  @override
  State<_PlanNodeTile> createState() => _PlanNodeTileState();
}

class _PlanNodeTileState extends State<_PlanNodeTile> {
  late double _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.node.progress.toDouble();
  }

  @override
  void didUpdateWidget(covariant _PlanNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.progress != widget.node.progress) {
      _progress = widget.node.progress.toDouble();
    }
  }

  PlanNode get node => widget.node;
  PlanController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 20.0, top: 8, bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.depth == 0 ? DotColors.amber : DotColors.paperLine,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _edit(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (node.body.isNotEmpty)
                            Text(
                              node.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Move up',
                    onPressed: () =>
                        controller.moveSort(id: node.id, delta: -1),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: () =>
                        controller.moveSort(id: node.id, delta: 1),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Add child',
                    onPressed: () => _addChild(context),
                    icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Open plan chat',
                    onPressed: widget.onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${_progress.round()}%',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Expanded(
                    child: Slider(
                      value: _progress,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_progress.round()}%',
                      onChanged: (v) => setState(() => _progress = v),
                      onChangeEnd: (v) {
                        controller.setProgress(node.id, v.round());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final titleCtrl = TextEditingController(text: node.title);
    final bodyCtrl = TextEditingController(text: node.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit plan node'),
        content: SizedBox(
          width: 420,
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
                maxLines: 5,
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
    if (ok == true && title.isNotEmpty) {
      await controller.updateNode(id: node.id, title: title, body: body);
    }
  }

  Future<void> _addChild(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add child'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (ok == true && title.isNotEmpty) {
      await controller.addChild(parentId: node.id, title: title);
    }
  }
}

