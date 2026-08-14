import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling ScreenshotCommand execution.
///
/// This capability encapsulates screenshot capture logic and delegates
/// to the AssistantPlatform for actual implementation.
class ScreenshotCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  ScreenshotCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: ScreenshotCapability.canHandle() called with command: $command');
    final result = command is ScreenshotCommand;
    print('DIAG: ScreenshotCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: ScreenshotCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: ScreenshotCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'ScreenshotCapability can only handle ScreenshotCommand');
    }

    print('DIAG: ScreenshotCapability about to execute _executeScreenshotCommand');
    final result = await _executeScreenshotCommand();
    print('DIAG: ScreenshotCapability._executeScreenshotCommand returned: $result');
    return result;
  }

  Future<ExecutionResult> _executeScreenshotCommand() async {
    print('DIAG: ScreenshotCapability._executeScreenshotCommand() entered');
    try {
      // Attempt to take a screenshot
      final actionResult = await _platform.takeScreenshot();
      print('DIAG: ScreenshotCapability._executeScreenshotCommand() action result: $actionResult');
      return _convertScreenshotActionResult(actionResult);
    } catch (e) {
      print('DIAG: ScreenshotCapability._executeScreenshotCommand caught exception: $e');
      return ExecutionResult.failure('Screenshot execution failed: $e');
    }
  }

  ExecutionResult _convertScreenshotActionResult(ScreenshotActionResult result) {
    print('DIAG: ScreenshotCapability._convertScreenshotActionResult() entered with result: $result');
    switch (result.status) {
      case ScreenshotActionStatus.success:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning success');
        return ExecutionResult.success(data: result);
      case ScreenshotActionStatus.failure:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Screenshot action failed');
      case ScreenshotActionStatus.unavailable:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Screenshot not available');
      case ScreenshotActionStatus.permissionRequired:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(result.message ?? 'Screenshot permission required');
      case ScreenshotActionStatus.userActionRequired:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning userActionRequired');
        return ExecutionResult.userActionRequired(
            result.message ?? 'User action required for screenshot',
            data: result);
      case ScreenshotActionStatus.unsupported:
        print('DIAG: ScreenshotCapability._convertScreenshotActionResult returning unsupported');
        return ExecutionResult.unsupported(result.message ?? 'Screenshot not supported');
    }
  }
}