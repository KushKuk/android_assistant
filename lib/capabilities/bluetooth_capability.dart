import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling BluetoothCommand execution.
///
/// This capability encapsulates Bluetooth control logic and delegates
/// to the AssistantPlatform for actual implementation.
class BluetoothCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  BluetoothCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: BluetoothCapability.canHandle() called with command: $command');
    final result = command is BluetoothCommand;
    print('DIAG: BluetoothCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: BluetoothCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: BluetoothCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'BluetoothCapability can only handle BluetoothCommand');
    }

    final bluetoothCommand = command as BluetoothCommand;
    print('DIAG: BluetoothCapability about to execute _executeBluetoothCommand');
    final result = await _executeBluetoothCommand(bluetoothCommand);
    print('DIAG: BluetoothCapability._executeBluetoothCommand returned: $result');
    return result;
  }

  Future<ExecutionResult> _executeBluetoothCommand(
      BluetoothCommand command) async {
    print('DIAG: BluetoothCapability._executeBluetoothCommand() entered with command: $command');
    try {
      if (command.isGetStatus) {
        print('DIAG: BluetoothCapability handling getStatus');
        return await _handleGetStatus();
      } else if (command.isEnable) {
        print('DIAG: BluetoothCapability handling enable');
        return await _handleEnable();
      } else if (command.isDisable) {
        print('DIAG: BluetoothCapability handling disable');
        return await _handleDisable();
      } else if (command.isListDevices) {
        print('DIAG: BluetoothCapability handling listDevices');
        return await _handleListDevices();
      } else if (command.isConnect) {
        print('DIAG: BluetoothCapability handling connect');
        if (command.deviceAddress == null && command.deviceQuery == null) {
          print('DIAG: BluetoothCapability connect missing device address/query');
          return ExecutionResult.invalidArguments(
              'Device address or query required for connect');
        }
        final address = command.deviceAddress ?? await _resolveDeviceAddress(
            command.deviceQuery!);
        if (address == null) {
          print('DIAG: BluetoothCapability connect device not found: ${command.deviceQuery}');
          return ExecutionResult.failure(
              'Device not found: "${command.deviceQuery}"');
        }
        print('DIAG: BluetoothCapability connecting to device: $address');
        return await _handleConnect(address);
      } else if (command.isDisconnect) {
        print('DIAG: BluetoothCapability handling disconnect');
        if (command.deviceAddress == null && command.deviceQuery == null) {
          print('DIAG: BluetoothCapability disconnect missing device address/query');
          return ExecutionResult.invalidArguments(
              'Device address or query required for disconnect');
        }
        final address = command.deviceAddress ?? await _resolveDeviceAddress(
            command.deviceQuery!);
        if (address == null) {
          print('DIAG: BluetoothCapability disconnect device not found: ${command.deviceQuery}');
          return ExecutionResult.failure(
              'Device not found: "${command.deviceQuery}"');
        }
        print('DIAG: BluetoothCapability disconnecting from device: $address');
        return await _handleDisconnect(address);
      } else {
        print('DIAG: BluetoothCapability unsupported action: ${command.action}');
        return ExecutionResult.unsupported(
            'Unsupported Bluetooth action: ${command.action}');
      }
    } catch (e) {
      print('DIAG: BluetoothCapability._executeBluetoothCommand caught exception: $e');
      return ExecutionResult.failure('Bluetooth execution failed: $e');
    }
  }

  Future<ExecutionResult> _handleGetStatus() async {
    print('DIAG: BluetoothCapability._handleGetStatus() entered');
    final result = await _platform.getBluetoothStatus();
    print('DIAG: BluetoothCapability._handleGetStatus got result: $result');
    final converted = _convertBluetoothStatusResult(result);
    print('DIAG: BluetoothCapability._handleGetStatus returning: $converted');
    return converted;
  }

  Future<ExecutionResult> _handleEnable() async {
    print('DIAG: BluetoothCapability._handleEnable() entered');
    final result = await _platform.requestBluetoothEnable();
    print('DIAG: BluetoothCapability._handleEnable got result: $result');
    final converted = _convertBluetoothActionResult(result);
    print('DIAG: BluetoothCapability._handleEnable returning: $converted');
    return converted;
  }

  Future<ExecutionResult> _handleDisable() async {
    print('DIAG: BluetoothCapability._handleDisable() entered');
    final result = await _platform.requestBluetoothDisable();
    print('DIAG: BluetoothCapability._handleDisable got result: $result');
    final converted = _convertBluetoothActionResult(result);
    print('DIAG: BluetoothCapability._handleDisable returning: $converted');
    return converted;
  }

  Future<ExecutionResult> _handleListDevices() async {
    print('DIAG: BluetoothCapability._handleListDevices() entered');
    final result = await _platform.getBluetoothDevices();
    print('DIAG: BluetoothCapability._handleListDevices got result: $result');
    final converted = _convertBluetoothDeviceListResult(result);
    print('DIAG: BluetoothCapability._handleListDevices returning: $converted');
    return converted;
  }

  Future<ExecutionResult> _handleConnect(String deviceAddress) async {
    print('DIAG: BluetoothCapability._handleConnect() entered with deviceAddress: $deviceAddress');
    final result = await _platform.connectBluetoothDevice(deviceAddress);
    print('DIAG: BluetoothCapability._handleConnect got result: $result');
    final converted = _convertBluetoothActionResult(result);
    print('DIAG: BluetoothCapability._handleConnect returning: $converted');
    return converted;
  }

  Future<ExecutionResult> _handleDisconnect(String deviceAddress) async {
    print('DIAG: BluetoothCapability._handleDisconnect() entered with deviceAddress: $deviceAddress');
    final result = await _platform.disconnectBluetoothDevice(deviceAddress);
    print('DIAG: BluetoothCapability._handleDisconnect got result: $result');
    final converted = _convertBluetoothActionResult(result);
    print('DIAG: BluetoothCapability._handleDisconnect returning: $converted');
    return converted;
  }

  Future<String?> _resolveDeviceAddress(String query) async {
    print('DIAG: BluetoothCapability._resolveDeviceAddress() entered with query: $query');
    final devicesResult = await _platform.getBluetoothDevices();
    print('DIAG: BluetoothCapability._resolveDeviceAddress got devicesResult: $devicesResult');
    final devicesResultExec = _convertBluetoothDeviceListResult(devicesResult);
    print('DIAG: BluetoothCapability._resolveDeviceAddress got devicesResultExec: $devicesResultExec');

    if (devicesResultExec.status != ExecutionStatus.success) {
      print('DIAG: BluetoothCapability._resolveDeviceAddress devicesResultExec not success, returning null');
      return null;
    }

    final devices = devicesResultExec.data as List<BluetoothDeviceInfo>? ?? [];
    print('DIAG: BluetoothCapability._resolveDeviceAddress got devices list: $devices');
    final queryLower = query.toLowerCase();
    print('DIAG: BluetoothCapability._resolveDeviceAddress queryLower: $queryLower');

    // First try exact match (case insensitive)
    final exactMatch = devices.firstWhere(
        (device) => device.name.toLowerCase() == queryLower,
        orElse: () => BluetoothDeviceInfo(
          name: '', address: '', bondState: BluetoothBondState.none,
          connectionState: BluetoothConnectionState.disconnected),
    );

    if (exactMatch.name.isNotEmpty) {
      print('DIAG: BluetoothCapability._resolveDeviceAddress exactMatch found: ${exactMatch.address}');
      return exactMatch.address;
    }

    // Then try partial match (case insensitive)
    final partialMatches = devices.where(
        (device) => device.name.toLowerCase().contains(queryLower)).toList();
    print('DIAG: BluetoothCapability._resolveDeviceAddress partialMatches count: ${partialMatches.length}');

    if (partialMatches.length == 1) {
      print('DIAG: BluetoothCapability._resolveDeviceAddress partialMatch found: ${partialMatches.first.address}');
      return partialMatches.first.address;
    }

    // Multiple matches or no matches
    print('DIAG: BluetoothCapability._resolveDeviceAddress no unique match found, returning null');
    return null;
  }

  ExecutionResult _convertBluetoothStatusResult(
      BluetoothStatusResult result) {
    print('DIAG: BluetoothCapability._convertBluetoothStatusResult() entered with result: $result');
    switch (result.status) {
      case BluetoothStatus.enabled:
        print('DIAG: BluetoothCapability._convertBluetoothStatusResult returning success for enabled');
        return ExecutionResult.success(data: result);
      case BluetoothStatus.disabled:
        print('DIAG: BluetoothCapability._convertBluetoothStatusResult returning success for disabled');
        return ExecutionResult.success(data: result);
      case BluetoothStatus.unavailable:
        print('DIAG: BluetoothCapability._convertBluetoothStatusResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Bluetooth unavailable');
      case BluetoothStatus.permissionRequired:
        print('DIAG: BluetoothCapability._convertBluetoothStatusResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Bluetooth permission required');
    }
  }

  ExecutionResult _convertBluetoothActionResult(
      BluetoothActionResult result) {
    print('DIAG: BluetoothCapability._convertBluetoothActionResult() entered with result: $result');
    switch (result.status) {
      case BluetoothActionStatus.success:
        print('DIAG: BluetoothCapability._convertBluetoothActionResult returning success');
        return ExecutionResult.success(data: result);
      case BluetoothActionStatus.failure:
        print('DIAG: BluetoothCapability._convertBluetoothActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Bluetooth action failed');
      case BluetoothActionStatus.permissionRequired:
        print('DIAG: BluetoothCapability._convertBluetoothActionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Bluetooth permission required');
      case BluetoothActionStatus.userActionRequired:
        print('DIAG: BluetoothCapability._convertBluetoothActionResult returning userActionRequired');
        return ExecutionResult.userActionRequired(
            result.message ?? 'User action required',
            data: result);
      case BluetoothActionStatus.unsupported:
        print('DIAG: BluetoothCapability._convertBluetoothActionResult returning unsupported');
        return ExecutionResult.unsupported(
            result.message ?? 'Bluetooth action unsupported');
    }
  }

  ExecutionResult _convertBluetoothDeviceListResult(
      BluetoothDeviceListResult result) {
    print('DIAG: BluetoothCapability._convertBluetoothDeviceListResult() entered with result: $result');
    if (result.devices.isEmpty) {
      if (result.message.isNotEmpty) {
        // Check if the message indicates an error condition
        final lowerMessage = result.message.toLowerCase();
        if (lowerMessage.contains('not available') ||
            lowerMessage.contains('error') ||
            lowerMessage.contains('failed') ||
            lowerMessage.contains('permission')) {
          print('DIAG: BluetoothCapability._convertBluetoothDeviceListResult returning failure: $result.message');
          return ExecutionResult.failure(result.message);
        }
        // Otherwise treat as success with empty list (e.g., no devices found but no error)
        print('DIAG: BluetoothCapability._convertBluetoothDeviceListResult returning success with empty list');
        return ExecutionResult.success(data: result);
      }
      // No devices and no message - treat as success
      print('DIAG: BluetoothCapability._convertBluetoothDeviceListResult returning success with empty list (no message)');
      return ExecutionResult.success(data: result);
    }

    // Check if we need to indicate user action for device selection
    // For now, we'll just return the list as success
    print('DIAG: BluetoothCapability._convertBluetoothDeviceListResult returning success');
    return ExecutionResult.success(data: result);
  }
}