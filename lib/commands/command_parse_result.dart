import 'package:voice_assistant/commands/assistant_command.dart';

class CommandParseResult {
  const CommandParseResult._({this.command, this.message});

  const CommandParseResult.parsed(AssistantCommand command)
    : this._(command: command);

  const CommandParseResult.unsupported(String message)
    : this._(message: message);

  final AssistantCommand? command;
  final String? message;

  bool get isParsed => command != null;
}
