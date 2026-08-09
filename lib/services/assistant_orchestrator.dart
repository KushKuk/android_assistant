import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';

/// Orchestrator responsible for routing commands to appropriate capabilities.
class AssistantOrchestrator {
  final List<AssistantCapability> _capabilities;

  AssistantOrchestrator(List<AssistantCapability> capabilities)
      : _capabilities = List.unmodifiable(capabilities);

  /// Executes the given command by finding the first capability that can handle it.
  ///
  /// Returns [ExecutionResult.unsupported] if no capability can handle the command.
  Future<ExecutionResult> executeCommand(AssistantCommand command) {
    print('DIAG: AssistantOrchestrator executing command: $command');
    print('DIAG: AssistantOrchestrator checking ${_capabilities.length} capabilities');
    for (int i = 0; i < _capabilities.length; i++) {
      final capability = _capabilities[i];
      print('DIAG: AssistantOrchestrator checking capability $i: ${capability.runtimeType}');
      final canHandle = capability.canHandle(command);
      print('DIAG: AssistantOrchestrator capability $i canHandle: $canHandle');
      if (canHandle) {
        print('DIAG: AssistantOrchestrator selected capability $i: ${capability.runtimeType}');
        print('DIAG: AssistantOrchestrator about to execute capability.execute()');
        final result = capability.execute(command);
        print('DIAG: AssistantOrchestrator capability.execute() returned: $result');
        return result;
      }
    }
    print('DIAG: AssistantOrchestrator no capability found for command: $command');
    return Future.value(
        ExecutionResult.unsupported('No capability found for command: $command'));
  }

  /// Returns true if any registered capability can handle the given command.
  bool canHandleCommand(AssistantCommand command) {
    return _capabilities.any((capability) => capability.canHandle(command));
  }

  /// Returns the list of registered capabilities.
  List<AssistantCapability> get capabilities => List.unmodifiable(_capabilities);
}