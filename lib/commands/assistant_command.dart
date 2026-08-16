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

// ADD WHATSAPP COMMANDS
class WhatsAppMessageCommand extends AssistantCommand {
  const WhatsAppMessageCommand({
    required this.contactQuery,
    required this.message,
    this.confirmed = false,
  });

  final String contactQuery;
  final String message;
  final bool confirmed;
}

class WhatsAppAudioCallCommand extends AssistantCommand {
  const WhatsAppAudioCallCommand({
    required this.contactQuery,
    this.confirmed = false,
  });

  final String contactQuery;
  final bool confirmed;
}

class WhatsAppVideoCallCommand extends AssistantCommand {
  const WhatsAppVideoCallCommand({
    required this.contactQuery,
    this.confirmed = false,
  });

  final String contactQuery;
  final bool confirmed;
}

// ADD SPOTIFY COMMANDS
class SpotifyOpenCommand extends AssistantCommand {
  const SpotifyOpenCommand();
}

class SpotifyPlaybackCommand extends AssistantCommand {
  const SpotifyPlaybackCommand({required this.action});

  final SpotifyPlaybackAction action;

  bool get isPlay => action == SpotifyPlaybackAction.play;
  bool get isPause => action == SpotifyPlaybackAction.pause;
  bool get isResume => action == SpotifyPlaybackAction.resume;
  bool get isNext => action == SpotifyPlaybackAction.next;
  bool get isPrevious => action == SpotifyPlaybackAction.previous;
}

enum SpotifyPlaybackAction { play, pause, resume, next, previous }

class SpotifyPlayTrackCommand extends AssistantCommand {
  const SpotifyPlayTrackCommand({required this.query});

  final String query;
}

class SpotifyPlayArtistCommand extends AssistantCommand {
  const SpotifyPlayArtistCommand({required this.query});

  final String query;
}

class SpotifyPlayPlaylistCommand extends AssistantCommand {
  const SpotifyPlayPlaylistCommand({required this.query});

  final String query;
}