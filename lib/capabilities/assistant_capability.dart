import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';

/// Interface for assistant capabilities that can execute commands.
abstract class AssistantCapability {
  /// Returns true if this capability can handle the given command.
  bool canHandle(AssistantCommand command);

  /// Executes the given command and returns the result.
  ///
  /// The command is guaranteed to be one that this capability can handle
  /// (based on canHandle returning true).
  Future<ExecutionResult> execute(AssistantCommand command);
}