import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/services/chat_command_service.dart';

/// Slash-command palette shown when the composer starts with `/`.
class SlashCommandBar extends StatelessWidget {
  const SlashCommandBar({
    super.key,
    required this.composerText,
    required this.onPick,
  });

  final String composerText;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final matches = ChatSlashCommand.matching(composerText);
    if (matches.isEmpty) return const SizedBox.shrink();

    return Material(
      color: DotColors.paperElevated,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Commands',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: DotColors.textSecondary,
                ),
              ),
            ),
          ),
          for (final cmd in matches)
            ListTile(
              dense: true,
              leading: const Icon(Icons.terminal, size: 18),
              title: Text(cmd.usage),
              subtitle: Text(cmd.description),
              onTap: () => onPick('/${cmd.name} '),
            ),
        ],
      ),
    );
  }
}
