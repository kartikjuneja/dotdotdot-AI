import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/message.dart';
import '../media/media_store.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align =
        _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = _isUser ? DotColors.ink : DotColors.paperElevated;
    final fg = _isUser ? DotColors.paper : DotColors.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(_isUser ? 16 : 4),
      bottomRight: Radius.circular(_isUser ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: _isUser ? null : Border.all(color: DotColors.paperLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.text.isNotEmpty)
                  SelectableText(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                if (message.mediaPaths.isNotEmpty) ...[
                  if (message.text.isNotEmpty) const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final path in message.mediaPaths)
                        _MediaThumb(path: path),
                    ],
                  ),
                ],
                if (message.status == MessageStatus.streaming)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (message.status == MessageStatus.error) ...[
                  const SizedBox(height: 8),
                  Text(
                    message.error ?? 'Something went wrong',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DotColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.path});

  final String path;

  bool get _isImage {
    final lower = path.toLowerCase();
    return lower.startsWith('data:image') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final label = path.split(RegExp(r'[\\/]')).last;
    if (_isImage) {
      final bytes = _imageBytes();
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 160,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Fallback(label: label),
          ),
        );
      }
    }
    return _Fallback(
      label: label.length > 40 ? '${label.substring(0, 40)}…' : label,
      icon: _isImage ? Icons.image : Icons.attach_file,
    );
  }

  Uint8List? _imageBytes() {
    if (path.startsWith('data:')) {
      final comma = path.indexOf(',');
      if (comma < 0) return null;
      try {
        return base64Decode(path.substring(comma + 1));
      } catch (_) {
        return null;
      }
    }
    return readLocalFileBytes(path);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.label, this.icon = Icons.attach_file});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DotColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DotColors.paperLine),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DotColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
