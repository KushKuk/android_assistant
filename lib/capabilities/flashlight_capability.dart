import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling FlashlightCommand execution.
///
/// This capability encapsulates flashlight control logic and delegates
/// to the AssistantPlatform for actual implementation.
class FlashlightCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  FlashlightCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: FlashlightCapability.canHandle() called with command: $command');
    final result = command is FlashlightCommand;
    print('DIAG: FlashlightCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: FlashlightCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: FlashlightCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'FlashlightCapability can only handle FlashlightCommand');
    }

    final flashlightCommand = command as FlashlightCommand;
    print('DIAG: FlashlightCapability about to execute _executeFlashlightCommand');
    final result = await _executeFlashlightCommand(flashlightCommand);
    print('DIAG: FlashlightCapability._executeFlashlightCommand returned: $result');
    return result;
  }

  Future<ExecutionResult> _executeFlashlightCommand(
      FlashlightCommand command) async {
    print('DIAG: FlashlightCapability._executeFlashlightCommand() entered with command: $command');
    try {
      if (command.isOn) {
        print('DIAG: FlashlightCapability handling ON command');
        return await _handleTurnOn();
      } else if (command.isOff) {
        print('DIAG: FlashlightCapability handling OFF command');
        return await _handleTurnOff();
      } else {
        print('DIAG: FlashlightCapability unsupported action: ${command.action}');
        return ExecutionResult.unsupported(
            'Unsupported Flashlight action: ${command.action}');
      }
    } catch (e) {
      print('DIAG: FlashlightCapability._executeFlashlightCommand caught exception: $e');
      return ExecutionResult.failure('Flashlight execution failed: $e');
    }
  }

  Future<ExecutionResult> _handleTurnOn() async {
    print('DIAG: FlashlightCapability._handleTurnOn() entered');
    // First check availability
    final availabilityResult = await _platform.getFlashlightAvailability();
    print('DIAG: FlashlightCapability._handleTurnOn() availability result: $availabilityResult');
    if (availabilityResult.status == FlashlightStatus.unavailable) {
      return ExecutionResult.unavailable(
          availabilityResult.message ?? 'Flashlight unavailable on this device');
    }

    // If available, turn on
    final actionResult = await _platform.setFlashlightEnabled(true);
    print('DIAG: FlashlightCapability._handleTurnOn() action result: $actionResult');
    return _convertFlashlightActionResult(actionResult);
  }

  Future<ExecutionResult> _handleTurnOff() async {
    print('DIAG: FlashlightCapability._handleTurnOff() entered');
    // First check availability
    final availabilityResult = await _platform.getFlashlightAvailability();
    print('DIAG: FlashlightCapability._handleTurnOff() availability result: $availabilityResult');
    if (availabilityResult.status == FlashlightStatus.unavailable) {
      return ExecutionResult.unavailable(
          availabilityResult.message ?? 'Flashlight unavailable on this device');
    }

    // If available, turn off
    final actionResult = await _platform.setFlashlightEnabled(false);
    print('DIAG: FlashlightCapability._handleTurnOff() action result: $actionResult');
    return _convertFlashlightActionResult(actionResult);
  }

  ExecutionResult _convertFlashlightActionResult(FlashlightActionResult result) {
    print('DIAG: FlashlightCapability._convertFlashlightActionResult() entered with result: $result');
    switch (result.status) {
      case FlashlightActionStatus.success:
        print('DIAG: FlashlightCapability._convertFlashlightActionResult returning success');
        return ExecutionResult.success(data: result);
      case FlashlightActionStatus.failure:
        print('DIAG: FlashlightCapability._convertFlashlightActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Flashlight action failed');
      case FlashlightActionStatus.unavailable:
        print('DIAG: FlashlightCapability._convertFlashlightActionResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Flashlight not available');
      case FlashlightActionStatus.unsupported:
        print('DIAG: FlashlightCapability._convertFlashlightActionResult returning unsupported');
        return ExecutionResult.unsupported(result.message ?? 'Flashlight not supported');
    }
  }
}