import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parse_result.dart';

/// Deterministic parsing for supported commands. Execution is intentionally
/// separate and remains the responsibility of the Android call pipeline.
class CommandParser {
  const CommandParser();

  CommandParseResult parse(String input) {
    print('DIAG: CommandParser.parse() entered with input: "$input"');
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      print('DIAG: CommandParser.parse() exiting: empty input');
      return const CommandParseResult.unsupported('No command was provided.');
    }

    final contactQuery = _callTarget(normalizedInput);
    if (contactQuery == null) {
      print('DIAG: CommandParser.parse() exiting: command not supported');
      return const CommandParseResult.unsupported('Command is not supported.');
    }
    if (contactQuery.isEmpty) {
      print('DIAG: CommandParser.parse() exiting: empty contact query');
      return const CommandParseResult.unsupported(
        'A contact or phone number is required.',
      );
    }
    print('DIAG: CommandParser.parse() exiting: parsed CallCommand with query: $contactQuery');
    return CommandParseResult.parsed(CallCommand(contactQuery: contactQuery));
  }

  String? _callTarget(String input) {
    print('DIAG: CommandParser._callTarget() entered with input: $input');
    for (final pattern in _callPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final trimmed = _trimTerminalPunctuation(match.group(1)!);
        print('DIAG: CommandParser._callTarget() exiting with match: $trimmed');
        return trimmed;
      }
    }
    if (_callWithoutTarget.hasMatch(input)) {
      print('DIAG: CommandParser._callTarget() exiting: call without target');
      return '';
    }
    print('DIAG: CommandParser._callTarget() exiting: no match');
    return null;
  }

  String _trimTerminalPunctuation(String value) =>
      value.trim().replaceFirst(RegExp(r'[.!?]+$'), '').trim();

  static final _callPatterns = <RegExp>[
    RegExp(r'^\s*(?:call|phone)\s+(.+?)\s*$', caseSensitive: false),
    RegExp(r'^\s*give\s+(.+?)\s+a\s+call\s*$', caseSensitive: false),
  ];

  static final _callWithoutTarget = RegExp(
    r'^\s*(?:call|phone)\s*[.!?]?\s*$',
    caseSensitive: false,
  );
}
