import 'package:dotdotdot_ai/domain/services/chat_command_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ChatCommandService();

  test('plain text is not a command', () {
    final cmd = service.parse('Hello there');
    expect(cmd.kind, ChatCommandKind.none);
    expect(cmd.displayText, 'Hello there');
    expect(cmd.generatePlan, isFalse);
  });

  test('/plan with topic becomes a readable generate request', () {
    final cmd = service.parse('/plan Learn Spanish in 8 weeks');
    expect(cmd.kind, ChatCommandKind.generatePlan);
    expect(cmd.generatePlan, isTrue);
    expect(cmd.displayText, 'Generate a nested plan/course: Learn Spanish in 8 weeks');
    expect(cmd.topic, 'Learn Spanish in 8 weeks');
  });

  test('/course without topic uses the conversation', () {
    final cmd = service.parse('/course');
    expect(cmd.kind, ChatCommandKind.generatePlan);
    expect(
      cmd.displayText,
      'Generate a nested plan/course from this conversation.',
    );
  });

  test('unknown command is flagged', () {
    final cmd = service.parse('/wipe everything');
    expect(cmd.kind, ChatCommandKind.unknown);
    expect(cmd.unknownName, 'wipe');
  });

  test('slash palette matches prefixes', () {
    expect(ChatSlashCommand.matching('hello'), isEmpty);
    expect(ChatSlashCommand.matching('/').length, 2);
    expect(
      ChatSlashCommand.matching('/pl').map((c) => c.name),
      ['plan'],
    );
  });
}
