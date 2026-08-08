import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parse_result.dart';

/// Deterministic parsing for supported commands. Execution is intentionally
/// separate and remains the responsibility of the Android call pipeline.
class CommandParser {
  const CommandParser();

  CommandParseResult parse(String input) {
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      return const CommandParseResult.unsupported('No command was provided.');
    }

    final contactQuery = _callTarget(normalizedInput);
    if (contactQuery == null) {
      return const CommandParseResult.unsupported('Command is not supported.');
    }
    if (contactQuery.isEmpty) {
      return const CommandParseResult.unsupported(
        'A contact or phone number is required.',
      );
    }
    return CommandParseResult.parsed(CallCommand(contactQuery: contactQuery));
  }

  String? _callTarget(String input) {
    for (final pattern in _callPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) return _trimTerminalPunctuation(match.group(1)!);
    }
    if (_callWithoutTarget.hasMatch(input)) return '';
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
