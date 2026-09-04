import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../domain/models/model_info.dart';
import '../media/media_actions.dart';
import 'chat_controller.dart';
import 'chat_scope_bar.dart';
import 'message_bubble.dart';
import 'model_picker.dart';
import 'slash_command_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.chatId));
    final notifier = ref.read(chatControllerProvider(widget.chatId).notifier);

    ref.listen(chatControllerProvider(widget.chatId), (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isStreaming != next.isStreaming) {
        _scrollToBottom();
      }
      if (next.createdPlanId != null &&
          next.createdPlanId != prev?.createdPlanId) {
        final title = next.createdPlanTitle ?? 'Plan';
        final planId = next.createdPlanId!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved plan “$title”'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => context.go('/plans/$planId'),
            ),
          ),
        );
        notifier.clearCreatedPlanBanner();
      }
    });

    if (state.error != null && state.chat == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, style: const TextStyle(color: DotColors.danger)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final chat = state.chat;
    final modelId = chat?.modelId ?? 'gemini-3.6-flash';
    final showSlash = _composer.text.trimLeft().startsWith('/');

    return Column(
      children: [
        _ChatHeader(
          title: chat?.title ?? 'Chat',
          modelId: modelId,
          onModelSelected: notifier.setModelId,
        ),
        if (chat != null) ChatScopeBar(chat: chat),
        if (state.error != null)
          Material(
            color: const Color(0xFFFFE8E6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: DotColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: DotColors.danger, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: state.messages.isEmpty
              ? _EmptyChatHint(
                  onGeneratePlan: chat == null
                      ? null
                      : () => notifier.sendMessage(overrideText: '/plan'),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: state.messages[index]);
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: MediaActions(
            chatId: widget.chatId,
            modelId: modelId,
            promptHint: _composer.text.trim().isEmpty ? null : _composer.text,
          ),
        ),
        if (showSlash)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SlashCommandBar(
              composerText: _composer.text,
              onPick: (value) {
                _composer
                  ..text = value
                  ..selection = TextSelection.collapsed(offset: value.length);
                notifier.setComposerText(value);
                setState(() {});
              },
            ),
          ),
        _Composer(
          controller: _composer,
          enabled: !state.isStreaming && chat != null,
          isStreaming: state.isStreaming,
          onChanged: (value) {
            notifier.setComposerText(value);
            setState(() {});
          },
          onSend: () async {
            final text = _composer.text;
            _composer.clear();
            setState(() {});
            await notifier.sendMessage(overrideText: text);
          },
        ),
      ],
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  const _EmptyChatHint({this.onGeneratePlan});

  final VoidCallback? onGeneratePlan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a message to begin.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DotColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type /plan to save a course from this chat, or attach a project '
                'above so its notes are included automatically.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onGeneratePlan != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onGeneratePlan,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate a plan from this chat'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.modelId,
    required this.onModelSelected,
  });

  final String title;
  final String modelId;
  final ValueChanged<String> onModelSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DotColors.paperLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ModelPicker(
              selectedModelId: modelId,
              filterCapability: ModelCapability.chat,
              onSelected: onModelSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.isStreaming,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isStreaming;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 6,
                onChanged: onChanged,
                onSubmitted: enabled ? (_) => onSend() : null,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Message, or /plan to save a course…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: enabled ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: DotColors.amber,
                foregroundColor: DotColors.ink,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isStreaming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
