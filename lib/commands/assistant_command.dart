import 'package:voice_assistant/models/bluetooth_device_info.dart';

sealed class AssistantCommand {
  const AssistantCommand();
}

class CallCommand extends AssistantCommand {
  const CallCommand({required this.contactQuery});

  final String contactQuery;
}

class BluetoothCommand extends AssistantCommand {
  const BluetoothCommand({
    required this.action,
    this.deviceQuery,
    this.deviceAddress,
  });

  final BluetoothAction action;
  final String? deviceQuery; // For resolving devices by name
  final String? deviceAddress; // For direct address specification

  bool get isGetStatus => action == BluetoothAction.getStatus;
  bool get isEnable => action == BluetoothAction.enable;
  bool get isDisable => action == BluetoothAction.disable;
  bool get isListDevices => action == BluetoothAction.listDevices;
  bool get isConnect => action == BluetoothAction.connect;
  bool get isDisconnect => action == BluetoothAction.disconnect;
}

// ADD CONNECTIVITY COMMAND
class ConnectivityCommand extends AssistantCommand {
  const ConnectivityCommand({
    required this.type,
    required this.action,
  });

  final ConnectivityType type;
  final ConnectivityAction action;

  bool get isGetStatus => action == ConnectivityAction.getStatus;
  bool get isEnable => action == ConnectivityAction.enable;
  bool get isDisable => action == ConnectivityAction.disable;
  bool get isOpenSettings => action == ConnectivityAction.openSettings;
}

enum ConnectivityType { wifi, mobileData, hotspot }

enum ConnectivityAction { getStatus, enable, disable, openSettings }

// ADD FLASHLIGHT COMMAND
class FlashlightCommand extends AssistantCommand {
  const FlashlightCommand({required this.action});

  final FlashlightAction action;

  bool get isOn => action == FlashlightAction.on;
  bool get isOff => action == FlashlightAction.off;
}

enum FlashlightAction { on, off }

// ADD SCREENSHOT COMMAND
class ScreenshotCommand extends AssistantCommand {
  const ScreenshotCommand();
}