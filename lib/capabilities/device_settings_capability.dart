import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/device_settings_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'dart:convert';

/// Capability for handling DeviceSettingsCommand execution.
///
/// This capability encapsulates device settings control logic and delegates
/// to the AssistantPlatform for actual implementation via Binder IPC.
class DeviceSettingsCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  DeviceSettingsCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    return command is DeviceSettingsCommand;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    if (!canHandle(command)) {
      return ExecutionResult.invalidArguments(
          'DeviceSettingsCapability can only handle DeviceSettingsCommand');
    }

    final deviceSettingsCommand = command as DeviceSettingsCommand;
    return await _executeDeviceSettingsCommand(deviceSettingsCommand);
  }

  Future<ExecutionResult> _executeDeviceSettingsCommand(
      DeviceSettingsCommand command) async {
    print('DIAG: DeviceSettingsCapability._executeDeviceSettingsCommand() entered with command: $command');
    try {
      String operation = '';
      String action = '';

      // Map device settings command to system operation
      switch (command.settingsType) {
        case DeviceSettingsType.volumeMedia:
          operation = "settings.volume.media";
          break;
        case DeviceSettingsType.volumeRing:
          operation = "settings.volume.ring";
          break;
        case DeviceSettingsType.volumeAlarm:
          operation = "settings.volume.alarm";
          break;
        case DeviceSettingsType.brightness:
          operation = "settings.brightness";
          break;
        case DeviceSettingsType.flashlight:
          operation = "settings.flashlight";
          break;
        case DeviceSettingsType.ringerMode:
          operation = "settings.ringer";
          break;
        case DeviceSettingsType.dnd:
          operation = "settings.dnd";
          break;
      }

      // Map action
      switch (command.action) {
        case DeviceSettingsAction.getStatus:
          action = "get";
          break;
        case DeviceSettingsAction.set:
          action = "set";
          break;
        case DeviceSettingsAction.increase:
          action = "increase";
          break;
        case DeviceSettingsAction.decrease:
          action = "decrease";
          break;
        case DeviceSettingsAction.mute:
          action = "mute";
          break;
        case DeviceSettingsAction.unmute:
          action = "unmute";
          break;
        case DeviceSettingsAction.max:
          action = "max";
          break;
        case DeviceSettingsAction.min:
          action = "min";
          break;
        case DeviceSettingsAction.toggle:
          action = "toggle";
          break;
      }

      // Prepare args
      Map<String, dynamic>? args;
      if (command.value != null) {
        // For volume and brightness operations, use percentage
        if (command.settingsType == DeviceSettingsType.volumeMedia ||
            command.settingsType == DeviceSettingsType.volumeRing ||
            command.settingsType == DeviceSettingsType.volumeAlarm ||
            command.settingsType == DeviceSettingsType.brightness) {
          if (command.action == DeviceSettingsAction.set ||
              command.action == DeviceSettingsAction.increase ||
              command.action == DeviceSettingsAction.decrease ||
              command.action == DeviceSettingsAction.mute ||
              command.action == DeviceSettingsAction.unmute ||
              command.action == DeviceSettingsAction.max ||
              command.action == DeviceSettingsAction.min) {
            args = {'percentage': command.value};
          }
        }
        // For flashlight, ringer mode, and dnd operations, use enabled
        else if (command.settingsType == DeviceSettingsType.flashlight ||
            command.settingsType == DeviceSettingsType.ringerMode ||
            command.settingsType == DeviceSettingsType.dnd) {
          if (command.action == DeviceSettingsAction.set) {
            args = {'enabled': command.value};
          }
        }
      }

      // Execute the operation through Binder IPC
      print('DIAG: DeviceSettingsCapability executing system operation: $operation, action: $action, args: $args');
      final resultJson = await _platform.executeSystemOperation(
        operation,
        action,
        args: args,
      );

      if (resultJson == null) {
        return ExecutionResult.failure('System operation returned null result');
      }

      // Parse the JSON result and convert to DeviceSettingsResult
      try {
        final resultMap = jsonDecode(resultJson) as Map<String, dynamic>;
        final status = resultMap['status'] as String?;
        final operationId = resultMap['operation'] as String?;
        final message = resultMap['message'] as String?;
        final silent = resultMap['silent'] as bool? ?? true;
        final requiresUserAction = resultMap['requiresUserAction'] as bool? ?? false;
        final currentValue = resultMap['currentValue'];

        final deviceSettingsResult = DeviceSettingsResult(
          status: status ?? 'unknown',
          operation: operationId ?? '',
          message: message ?? '',
          silent: silent,
          requiresUserAction: requiresUserAction,
          currentValue: currentValue,
        );

        // Convert based on status
        switch (status?.toLowerCase()) {
          case 'success':
            return ExecutionResult.success(data: deviceSettingsResult);
          case 'permission_required':
            return ExecutionResult.permissionRequired(
                message ?? 'Permission required');
          case 'user_action_required':
            return ExecutionResult.userActionRequired(
                message ?? 'User action required',
                data: deviceSettingsResult);
          case 'unsupported':
            return ExecutionResult.unsupported(
                message ?? 'Operation not supported');
          case 'denied':
            return ExecutionResult.failure(message ?? 'Operation denied');
          case 'failed':
          default:
            return ExecutionResult.failure(message ?? 'Operation failed');
        }
      } catch (e) {
        print('DIAG: DeviceSettingsCapability failed to parse system operation result: $e');
        return ExecutionResult.failure('Failed to parse system operation result: $e');
      }
    } catch (e) {
      print('DIAG: DeviceSettingsCapability._executeDeviceSettingsCommand caught exception: $e');
      return ExecutionResult.failure('Device settings execution failed: $e');
    }
  }
}