import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';

void main() {
  const parser = CommandParser();

  test('parses supported call phrases deterministically', () {
    final examples = <String, String>{
      'Call Mom': 'Mom',
      'Phone Dad': 'Dad',
      'Give Mom a call': 'Mom',
      'call 9876543210.': '9876543210',
    };

    for (final entry in examples.entries) {
      final result = parser.parse(entry.key);

      expect(result.isParsed, isTrue, reason: entry.key);
      expect((result.command! as CallCommand).contactQuery, entry.value);
    }
  });

  test('rejects calls without a target and unsupported commands', () {
    final missingTarget = parser.parse('Call');
    final unsupported = parser.parse('Set a timer for five minutes');

    expect(missingTarget.isParsed, isFalse);
    expect(missingTarget.message, 'A contact or phone number is required.');
    expect(unsupported.isParsed, isFalse);
    expect(unsupported.message, 'Command is not supported.');
  });
}
