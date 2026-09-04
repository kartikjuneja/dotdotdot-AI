/// Slash-command parser for in-chat actions (plans, courses, and future plugins).
///
/// Commands are a discoverable UX layer over the same structured JSON the
/// model can emit from natural language. Users never need to know entity IDs.
class ChatCommandService {
  const ChatCommandService();

  static const Set<String> planAliases = {'plan', 'course', 'plans'};

  /// Parses a composer string. Non-commands return [ChatCommand.none].
  ChatCommand parse(String raw) {
    final text = raw.trim();
    if (!text.startsWith('/')) {
      return ChatCommand.none(text);
    }

    final withoutSlash = text.substring(1);
    final space = withoutSlash.indexOf(RegExp(r'\s'));
    final name = (space < 0 ? withoutSlash : withoutSlash.substring(0, space))
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    final arg = space < 0 ? '' : withoutSlash.substring(space).trim();

    if (name.isEmpty) {
      return ChatCommand.none(text);
    }

    if (planAliases.contains(name)) {
      final topic = arg.isEmpty ? 'this conversation' : arg;
      return ChatCommand(
        kind: ChatCommandKind.generatePlan,
        originalText: text,
        displayText: arg.isEmpty
            ? 'Generate a nested plan/course from this conversation.'
            : 'Generate a nested plan/course: $arg',
        topic: topic,
      );
    }

    return ChatCommand(
      kind: ChatCommandKind.unknown,
      originalText: text,
      displayText: text,
      topic: arg,
      unknownName: name,
    );
  }
}

enum ChatCommandKind { none, generatePlan, unknown }

class ChatCommand {
  const ChatCommand({
    required this.kind,
    required this.originalText,
    required this.displayText,
    this.topic,
    this.unknownName,
  });

  factory ChatCommand.none(String text) => ChatCommand(
        kind: ChatCommandKind.none,
        originalText: text,
        displayText: text,
      );

  final ChatCommandKind kind;
  final String originalText;
  final String displayText;
  final String? topic;
  final String? unknownName;

  bool get generatePlan => kind == ChatCommandKind.generatePlan;
}

/// Catalog of slash commands shown in the composer palette.
class ChatSlashCommand {
  const ChatSlashCommand({
    required this.name,
    required this.usage,
    required this.description,
  });

  final String name;
  final String usage;
  final String description;

  static const List<ChatSlashCommand> catalog = [
    ChatSlashCommand(
      name: 'plan',
      usage: '/plan [topic]',
      description: 'Generate a nested plan from this chat and save it.',
    ),
    ChatSlashCommand(
      name: 'course',
      usage: '/course [topic]',
      description: 'Same as /plan — save a course outline from this chat.',
    ),
  ];

  static List<ChatSlashCommand> matching(String composerText) {
    final text = composerText.trimLeft();
    if (!text.startsWith('/')) return const [];
    final q = text.substring(1).split(RegExp(r'\s')).first.toLowerCase();
    if (q.isEmpty) return catalog;
    return catalog.where((c) => c.name.startsWith(q)).toList(growable: false);
  }
}
