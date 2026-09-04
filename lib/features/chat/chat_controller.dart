import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/providers/ai_types.dart';
import '../../app/providers.dart';
import '../../core/logging.dart';
import '../../core/scope_keys.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/context_doc.dart';
import '../../domain/models/memory_item.dart';
import '../../domain/models/message.dart';

class ChatViewState {
  const ChatViewState({
    this.chat,
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.composerText = '',
  });

  final Chat? chat;
  final List<Message> messages;
  final bool isStreaming;
  final String? error;
  final String composerText;

  ChatViewState copyWith({
    Chat? chat,
    List<Message>? messages,
    bool? isStreaming,
    Object? error = _unset,
    String? composerText,
  }) {
    return ChatViewState(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: identical(error, _unset) ? this.error : error as String?,
      composerText: composerText ?? this.composerText,
    );
  }
}

const Object _unset = Object();

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatViewState, String>(
  ChatController.new,
);

class ChatController extends FamilyNotifier<ChatViewState, String> {
  StreamSubscription<List<Message>>? _messagesSub;
  bool _sending = false;

  String get chatId => arg;

  @override
  ChatViewState build(String chatId) {
    ref.onDispose(() {
      _messagesSub?.cancel();
    });

    Future.microtask(_load);
    return const ChatViewState();
  }

  Future<void> _load() async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final chat = await chatRepo.getById(chatId);
      if (chat == null) {
        state = state.copyWith(error: 'Chat not found');
        return;
      }
      state = state.copyWith(chat: chat, error: null);

      await _messagesSub?.cancel();
      _messagesSub = ref
          .read(messageRepositoryProvider)
          .watchByChat(chatId)
          .listen((messages) {
        state = state.copyWith(messages: messages);
      });
    } catch (e, st) {
      AppLog.e('Failed to load chat', error: e, stackTrace: st);
      state = state.copyWith(error: '$e');
    }
  }

  void setComposerText(String text) {
    state = state.copyWith(composerText: text);
  }

  Future<void> setModelId(String modelId) async {
    final chat = state.chat;
    if (chat == null) return;
    final updated = chat.copyWith(
      modelId: modelId,
      updatedAt: ref.read(clockProvider).now(),
    );
    await ref.read(chatRepositoryProvider).save(updated);
    state = state.copyWith(chat: updated);
  }

  Future<void> sendMessage([String? overrideText]) async {
    if (_sending || state.isStreaming) return;
    final text = (overrideText ?? state.composerText).trim();
    if (text.isEmpty) return;

    final chat = state.chat;
    if (chat == null) {
      state = state.copyWith(error: 'Chat not loaded');
      return;
    }

    _sending = true;
    state = state.copyWith(composerText: '', error: null, isStreaming: true);

    final clock = ref.read(clockProvider);
    final ids = ref.read(uuidProvider);
    final messageRepo = ref.read(messageRepositoryProvider);
    final now = clock.now();

    final userMessage = Message(
      id: ids.next(),
      chatId: chatId,
      role: MessageRole.user,
      text: text,
      status: MessageStatus.complete,
      createdAt: now,
    );
    await messageRepo.save(userMessage);

    // Auto-title from first user message.
    if (chat.title == 'New chat') {
      final title =
          text.length > 48 ? '${text.substring(0, 48).trimRight()}…' : text;
      final titled = chat.copyWith(title: title, updatedAt: now);
      await ref.read(chatRepositoryProvider).save(titled);
      state = state.copyWith(chat: titled);
    }

    final assistantId = ids.next();
    var assistant = Message(
      id: assistantId,
      chatId: chatId,
      role: MessageRole.assistant,
      text: '',
      status: MessageStatus.streaming,
      createdAt: clock.now(),
    );
    await messageRepo.save(assistant);

    try {
      final provider = await resolveAiProvider(
        ref,
        modelId: chat.modelId,
        preferredAccountId: chat.providerAccountId,
      );
      if (provider == null) {
        throw StateError(
          'No provider key configured. Add an API key in Settings.',
        );
      }

      final systemPrompt = await _buildSystemPrompt(chat);
      final persisted = await messageRepo.listByChat(chatId);
      final history = <ChatMessageDto>[
        if (systemPrompt.trim().isNotEmpty)
          ChatMessageDto(role: 'system', content: systemPrompt),
        for (final m in persisted)
          if (m.id != assistantId &&
              m.role != MessageRole.system &&
              m.status != MessageStatus.error &&
              m.text.trim().isNotEmpty)
            ChatMessageDto(
              role: m.role == MessageRole.user ? 'user' : 'assistant',
              content: m.text,
            ),
      ];

      final buffer = StringBuffer();
      await for (final delta in provider.streamChat(
        ChatRequest(model: chat.modelId, messages: history),
      )) {
        if (delta.error != null && delta.error!.isNotEmpty) {
          throw StateError(delta.error!);
        }
        if (delta.textDelta != null && delta.textDelta!.isNotEmpty) {
          buffer.write(delta.textDelta);
          assistant = assistant.copyWith(
            text: buffer.toString(),
            status: MessageStatus.streaming,
          );
          await messageRepo.save(assistant);
        }
        if (delta.isDone) break;
      }

      final finalText = buffer.toString();
      assistant = assistant.copyWith(
        text: finalText,
        status: MessageStatus.complete,
      );
      await messageRepo.save(assistant);

      final updatedChat = (state.chat ?? chat).copyWith(
        updatedAt: clock.now(),
      );
      await ref.read(chatRepositoryProvider).save(updatedChat);
      state = state.copyWith(chat: updatedChat, isStreaming: false);

      if (chat.planNodeId != null) {
        await _tryApplyPlanPatch(chat.planNodeId!, finalText);
      }
    } catch (e, st) {
      AppLog.e('Chat send failed', error: e, stackTrace: st);
      assistant = assistant.copyWith(
        status: MessageStatus.error,
        error: '$e',
        text: assistant.text.isEmpty ? '' : assistant.text,
      );
      await messageRepo.save(assistant);
      state = state.copyWith(isStreaming: false, error: '$e');
    } finally {
      _sending = false;
      if (state.isStreaming) {
        state = state.copyWith(isStreaming: false);
      }
    }
  }

  Future<String> _buildSystemPrompt(Chat chat) async {
    final contextRepo = ref.read(contextRepositoryProvider);
    final memoryRepo = ref.read(memoryRepositoryProvider);
    final merge = ref.read(contextMergeServiceProvider);

    final globalDocs =
        await contextRepo.listByScope(ContextScopeKind.global);
    final globalMemory =
        await memoryRepo.listByScope(ContextScopeKind.global);

    final projectDocs = chat.projectId == null
        ? const <ContextDoc>[]
        : await contextRepo.listByScope(
            ContextScopeKind.project,
            scopeId: chat.projectId,
          );
    final projectMemory = chat.projectId == null
        ? const <MemoryItem>[]
        : await memoryRepo.listByScope(
            ContextScopeKind.project,
            scopeId: chat.projectId,
          );

    final planDocs = <ContextDoc>[];
    final planMemory = <MemoryItem>[];
    if (chat.planNodeId != null) {
      final chain = await ref
          .read(planRepositoryProvider)
          .getAncestorChain(chat.planNodeId!);
      for (final node in chain) {
        planDocs.addAll(
          await contextRepo.listByScope(
            ContextScopeKind.plan,
            scopeId: node.id,
          ),
        );
        planMemory.addAll(
          await memoryRepo.listByScope(
            ContextScopeKind.plan,
            scopeId: node.id,
          ),
        );
      }
    }

    final chatDocs = await contextRepo.listByScope(
      ContextScopeKind.chat,
      scopeId: chat.id,
    );
    final chatMemory = await memoryRepo.listByScope(
      ContextScopeKind.chat,
      scopeId: chat.id,
    );

    var prompt = merge.mergeEntities(
      globalDocs: globalDocs,
      projectDocs: projectDocs,
      planAncestorDocs: planDocs,
      chatDocs: chatDocs,
      globalMemory: globalMemory,
      projectMemory: projectMemory,
      planAncestorMemory: planMemory,
      chatMemory: chatMemory,
    );

    if (chat.planNodeId != null) {
      prompt = '''
$prompt

When you update the linked plan, include a fenced JSON block:
```plan-patch
{"title":"...","body":"...","progress":0,"status":"active"}
```
Only include fields you intend to change.
'''.trim();
    }
    return prompt;
  }

  Future<void> _tryApplyPlanPatch(String planNodeId, String assistantText) async {
    try {
      final patch = _extractPlanPatch(assistantText);
      if (patch == null) return;
      final planRepo = ref.read(planRepositoryProvider);
      final node = await planRepo.getById(planNodeId);
      if (node == null) return;
      final patched = ref.read(planPatchServiceProvider).applyPatch(node, patch);
      await planRepo.save(
        patched.copyWith(updatedAt: ref.read(clockProvider).now()),
      );
      AppLog.i('Applied plan-patch to $planNodeId');
    } catch (e, st) {
      AppLog.w('Plan patch skipped', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic>? _extractPlanPatch(String text) {
    final fence = RegExp(
      r'```plan-patch\s*([\s\S]*?)```',
      multiLine: true,
    );
    final match = fence.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<void> attachMediaToLastAssistant(List<String> paths) async {
    final assistants = state.messages
        .where((m) => m.role == MessageRole.assistant)
        .toList();
    if (assistants.isEmpty) return;
    final last = assistants.last;
    final updated = last.copyWith(
      mediaPaths: [...last.mediaPaths, ...paths],
      status: MessageStatus.complete,
    );
    await ref.read(messageRepositoryProvider).save(updated);
  }

  Future<void> addAssistantMediaMessage({
    required String text,
    required List<String> mediaPaths,
  }) async {
    final msg = Message(
      id: ref.read(uuidProvider).next(),
      chatId: chatId,
      role: MessageRole.assistant,
      text: text,
      mediaPaths: mediaPaths,
      status: MessageStatus.complete,
      createdAt: ref.read(clockProvider).now(),
    );
    await ref.read(messageRepositoryProvider).save(msg);
  }
}
