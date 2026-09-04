import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/providers/ai_types.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/logging.dart';
import '../../domain/models/model_info.dart';
import '../chat/chat_controller.dart';
import 'media_store.dart';

/// Capability-gated media generation actions for the active chat model.
class MediaActions extends ConsumerWidget {
  const MediaActions({
    super.key,
    required this.chatId,
    required this.modelId,
    this.promptHint,
  });

  final String chatId;
  final String modelId;
  final String? promptHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(modelCatalogProvider);
    return catalogAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (catalog) {
        final model = catalog.find(modelId);
        if (model == null) return const SizedBox.shrink();
        final caps = model.capabilities;
        final buttons = <Widget>[];
        if (caps.contains(ModelCapability.image)) {
          buttons.add(
            _ActionButton(
              icon: Icons.image_outlined,
              label: 'Image',
              onPressed: () => _generate(
                context,
                ref,
                kind: ModelCapability.image,
              ),
            ),
          );
        }
        if (caps.contains(ModelCapability.audio)) {
          buttons.add(
            _ActionButton(
              icon: Icons.graphic_eq,
              label: 'Audio',
              onPressed: () => _generate(
                context,
                ref,
                kind: ModelCapability.audio,
              ),
            ),
          );
        }
        if (caps.contains(ModelCapability.video)) {
          buttons.add(
            _ActionButton(
              icon: Icons.movie_outlined,
              label: 'Video',
              onPressed: () => _generate(
                context,
                ref,
                kind: ModelCapability.video,
              ),
            ),
          );
        }
        if (buttons.isEmpty) return const SizedBox.shrink();
        return Wrap(spacing: 8, runSpacing: 8, children: buttons);
      },
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref, {
    required ModelCapability kind,
  }) async {
    final controller = TextEditingController(text: promptHint ?? '');
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Generate ${kind.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe what to generate…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (prompt == null || prompt.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Generating ${kind.name}…')),
    );

    try {
      final provider = await resolveAiProvider(
        catalog: await ref.read(modelCatalogProvider.future),
        providers: ref.read(providerRepositoryProvider),
        vault: ref.read(keyVaultProvider),
        modelId: modelId,
      );
      if (provider == null) {
        throw StateError('Add a provider API key in Settings first.');
      }

      late final MediaResult result;
      switch (kind) {
        case ModelCapability.image:
          result = await provider.generateImage(
            ImageRequest(model: modelId, prompt: prompt),
          );
        case ModelCapability.audio:
          result = await provider.generateAudio(
            AudioRequest(model: modelId, input: prompt),
          );
        case ModelCapability.video:
          result = await provider.generateVideo(
            VideoRequest(model: modelId, prompt: prompt),
          );
        default:
          throw StateError('Unsupported media kind');
      }

      final path = await _persistMedia(result, kind: kind);
      await ref
          .read(chatControllerProvider(chatId).notifier)
          .addAssistantMediaMessage(
            text: 'Generated ${kind.name}: $prompt',
            mediaPaths: [path],
          );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('${kind.name} saved')));
    } catch (e, st) {
      AppLog.e('Media generation failed', error: e, stackTrace: st);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  Future<String> _persistMedia(
    MediaResult result, {
    required ModelCapability kind,
  }) async {
    final bytes = await _toBytes(result);
    final ext = _extFor(kind, result.mimeType);
    final name = '${kind.name}_${DateTime.now().millisecondsSinceEpoch}$ext';
    return saveMediaBytes(
      bytes: bytes,
      fileName: name,
      mimeType: result.mimeType ?? _defaultMime(kind),
    );
  }

  Future<Uint8List> _toBytes(MediaResult result) async {
    if (result.bytes != null && result.bytes!.isNotEmpty) {
      return Uint8List.fromList(result.bytes!);
    }
    if (result.base64Data != null && result.base64Data!.isNotEmpty) {
      var raw = result.base64Data!;
      if (raw.contains(',')) raw = raw.split(',').last;
      return Uint8List.fromList(base64Decode(raw));
    }
    if (result.url != null && result.url!.isNotEmpty) {
      return Uint8List.fromList(utf8.encode(result.url!));
    }
    throw StateError('Media result had no bytes, base64, or url');
  }

  String _defaultMime(ModelCapability kind) => switch (kind) {
        ModelCapability.image => 'image/png',
        ModelCapability.audio => 'audio/mpeg',
        ModelCapability.video => 'video/mp4',
        _ => 'application/octet-stream',
      };

  String _extFor(ModelCapability kind, String? mime) {
    if (mime != null) {
      if (mime.contains('png')) return '.png';
      if (mime.contains('jpeg') || mime.contains('jpg')) return '.jpg';
      if (mime.contains('webp')) return '.webp';
      if (mime.contains('mpeg') || mime.contains('mp3')) return '.mp3';
      if (mime.contains('wav')) return '.wav';
      if (mime.contains('mp4')) return '.mp4';
      if (mime.contains('webm')) return '.webm';
    }
    return switch (kind) {
      ModelCapability.image => '.png',
      ModelCapability.audio => '.mp3',
      ModelCapability.video => '.mp4',
      _ => '.bin',
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: DotColors.inkMuted,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
