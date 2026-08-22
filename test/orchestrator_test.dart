import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/capabilities/bluetooth_capability.dart';
import 'package:voice_assistant/capabilities/connectivity_capability.dart';
import 'package:voice_assistant/capabilities/flashlight_capability.dart';
import 'package:voice_assistant/capabilities/screenshot_capability.dart';
import 'package:voice_assistant/capabilities/spotify_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';
import 'package:voice_assistant/services/assistant_orchestrator.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_state.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/services/settings_repository.dart';

class TestCapability implements AssistantCapability {
  final bool shouldHandle;
  final ExecutionResult resultToReturn;

  TestCapability(this.shouldHandle, this.resultToReturn);

  @override
  bool canHandle(AssistantCommand command) => shouldHandle;

  @override
  Future<ExecutionResult> execute(AssistantCommand command) =>
      Future.value(resultToReturn);
}

class MockAssistantPlatform implements AssistantPlatform {
  final _eventController =
      StreamController<Map<Object?, Object?>>.broadcast();

  bool hasBluetoothPermissionValue = false;
  bool requestBluetoothPermissionResult = false;

  @override
  Stream<Map<Object?, Object?>> get events => _eventController.stream;

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<bool> hasCallPermission() async => true;

  @override
  Future<bool> hasContactsPermission() async => true;

  @override
  Future<bool> requestCallPermission() async => true;

  @override
  Future<bool> requestContactsPermission() async => true;

  // Bluetooth permission methods
  @override
  Future<bool> hasBluetoothPermission() async => hasBluetoothPermissionValue;

  @override
  Future<bool> requestBluetoothPermission() async => requestBluetoothPermissionResult;

  @override
  Future<ContactSearchResult> resolveContacts(String query) async =>
      ContactSearchResult(query: query, candidates: []);

  @override
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  }) async =>
      CallExecutionResult(
          status: CallExecutionStatus.confirmationRequired,
          message: 'Please confirm',
          confirmationToken: 'test-token');

  @override
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  }) async =>
      CallExecutionResult(
          status: CallExecutionStatus.calling, message: 'Call in progress');

  @override
  Future<AssistantIntegrationStatus> getIntegrationStatus() async =>
      const AssistantIntegrationStatus(
        isAvailable: true,
        platform: 'Android',
        androidApiLevel: 33,
        voiceInteractionServiceRegistered: false,
      );

  @override
  Future<SttState> getSpeechRecognitionStatus() async => SttState.idle;

  @override
  Future<TtsState> getTtsStatus() async => TtsState.idle;

  @override
  Future<TtsSpeakResult> speak(String text) async =>
      TtsSpeakResult(success: true);

  @override
  Future<SttResult> startListening() async => SttResult(success: true);

  @override
  Future<SttResult> stopListening() async => SttResult(success: true);

  @override
  Future<SttResult> cancelListening() async => SttResult(success: true);

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> syncSettings(AssistantSettings settings) async {}

  // Bluetooth methods
  @override
  Future<BluetoothStatusResult> getBluetoothStatus() async =>
      const BluetoothStatusResult(status: BluetoothStatus.disabled);

  @override
  Future<BluetoothActionResult> requestBluetoothEnable() async =>
      const BluetoothActionResult(status: BluetoothActionStatus.success);

  @override
  Future<BluetoothActionResult> requestBluetoothDisable() async =>
      const BluetoothActionResult(status: BluetoothActionStatus.success);

  @override
  Future<BluetoothDeviceListResult> getBluetoothDevices({bool onlyBonded = false}) async =>
      const BluetoothDeviceListResult(devices: [], message: '');

  @override
  Future<BluetoothActionResult> connectBluetoothDevice(String deviceAddress) async =>
      const BluetoothActionResult(status: BluetoothActionStatus.success);

  @override
  Future<BluetoothActionResult> disconnectBluetoothDevice(String deviceAddress) async =>
      const BluetoothActionResult(status: BluetoothActionStatus.success);

  // Connectivity methods
  @override
  Future<WifiStatusResult> getWifiStatus() async =>
      const WifiStatusResult(status: WifiStatus.disabled);

  @override
  Future<WifiActionResult> setWifiEnabled(bool enabled) async =>
      const WifiActionResult(status: WifiActionStatus.success);

  @override
  Future<MobileDataStatusResult> getMobileDataStatus() async =>
      const MobileDataStatusResult(status: MobileDataStatus.disabled);

  @override
  Future<MobileDataActionResult> setMobileDataEnabled(bool enabled) async =>
      const MobileDataActionResult(status: MobileDataActionStatus.success);

  @override
  Future<HotspotStatusResult> getHotspotStatus() async =>
      const HotspotStatusResult(status: HotspotStatus.disabled);

  @override
  Future<HotspotActionResult> setHotspotEnabled(bool enabled) async =>
      const HotspotActionResult(status: HotspotActionStatus.success);

  @override
  Future<SettingsActionResult> openWifiSettings() async =>
      const SettingsActionResult(status: SettingsActionStatus.success);

  @override
  Future<SettingsActionResult> openMobileDataSettings() async =>
      const SettingsActionResult(status: SettingsActionStatus.success);

  @override
  Future<SettingsActionResult> openHotspotSettings() async =>
      const SettingsActionResult(status: SettingsActionStatus.success);

  // Flashlight methods
  @override
  Future<FlashlightAvailabilityResult> getFlashlightAvailability() async =>
      const FlashlightAvailabilityResult(status: FlashlightStatus.available);

  @override
  Future<FlashlightActionResult> setFlashlightEnabled(bool enabled) async =>
      const FlashlightActionResult(status: FlashlightActionStatus.success);

  // Screenshot methods
  @override
  Future<ScreenshotActionResult> takeScreenshot() async =>
      const ScreenshotActionResult(status: ScreenshotActionStatus.success);

  @override
  Future<void> startWakeWordDetection() async {
    // Mock implementation for testing
  }

  @override
  Future<void> stopWakeWordDetection() async {
    // Mock implementation for testing
  }

  // Spotify methods
  @override
  Future<bool> isSpotifyInstalled() async => true;

  @override
  Future<String?> executeSystemOperation(String operation, String action, {Map<String, dynamic>? args}) async {
    // Return a successful test operation result for the system.test operation
    if (operation == 'system.test' && action == 'get') {
      return '''
      {
        "status": "SUCCESS",
        "operation": "system.test",
        "message": "System test successful",
        "silent": true,
        "requiresUserAction": false
      }
      ''';
    }
    // For unknown operations, return unsupported
    return '''
    {
      "status": "UNSUPPORTED",
      "operation": "$operation",
      "message": "Operation not supported",
      "silent": true,
      "requiresUserAction": false
    }
    ''';
  }

  @override
  Future<void> openSpotify() async {}

  // System Service methods (Binder IPC)
  @override
  Future<bool> pingSystemService() async => true;

  @override
  Future<String?> getSystemServiceVersion() async => '1.0.0-prototype';

  @override
  Future<String?> getSystemServiceStatus() async => 'OK';

  @override
  Future<void> playSpotify() async {}

  @override
  Future<void> pauseSpotify() async {}

  @override
  Future<void> resumeSpotify() async {}

  @override
  Future<void> nextSpotify() async {}

  @override
  Future<void> previousSpotify() async {}

  @override
  Future<void> searchAndPlayTrack(String query) async {}

  @override
  Future<void> searchAndPlayArtist(String query) async {}

  @override
  Future<void> searchAndPlayPlaylist(String query) async {}

  // WhatsApp methods
  @override
  Future<bool> isWhatsAppAvailable() async => true;

  @override
  Future<Object> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async => {'success': true, 'messageId': 'test-123'};

  @override
  Future<Object> makeWhatsAppCall({
    required String phoneNumber,
    required bool isVideo,
  }) async => {'success': true, 'callId': 'test-456'};
}

void main() {
  group('AssistantOrchestrator', () {
    test('routes command to correct capability', () async {
      final platform = MockAssistantPlatform();
      final callCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([callCapability]);

      final command = CallCommand(contactQuery: 'Mom');
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('returns unsupported result for unsupported command', () async {
      final platform = MockAssistantPlatform();
      final callCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([callCapability]);

      final command = CallCommand(contactQuery: 'Mom');
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.unsupported));
      expect(result.message, contains('No capability found'));
    });

    test('canHandleCommand returns true for supported commands', () async {
      final platform = MockAssistantPlatform();
      final callCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([callCapability]);

      final command = CallCommand(contactQuery: 'Mom');
      expect(orchestrator.canHandleCommand(command), isTrue);
    });

    test('canHandleCommand returns false for unsupported commands', () async {
      final platform = MockAssistantPlatform();
      final callCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([callCapability]);

      final command = CallCommand(contactQuery: 'Mom');
      expect(orchestrator.canHandleCommand(command), isFalse);
    });

    test('propagates capability execution results', () async {
      final platform = MockAssistantPlatform();
      final callCapability = TestCapability(
          true, ExecutionResult.failure('Test failure'));
      final orchestrator = AssistantOrchestrator([callCapability]);

      final command = CallCommand(contactQuery: 'Mom');
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Test failure'));
    });

    test('does not execute unrelated capability', () async {
      final platform = MockAssistantPlatform();
      // First capability says it can't handle the command
      final incapable = TestCapability(false, ExecutionResult.success());
      // Second capability says it can handle and returns success
      final capable = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([incapable, capable]);

      final command = CallCommand(contactQuery: 'Mom');
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });
  });

  group('ConnectivityCapability', () {
    test('routes Wi-Fi command to connectivity capability', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes mobile data command to connectivity capability', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.mobileData, action: ConnectivityAction.disable);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes hotspot command to connectivity capability', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.hotspot, action: ConnectivityAction.getStatus);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('returns unsupported result for unsupported connectivity command', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.unsupported));
      expect(result.message, contains('No capability found'));
    });

    test('canHandleCommand returns true for supported connectivity commands', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      expect(orchestrator.canHandleCommand(command), isTrue);
    });

    test('canHandleCommand returns false for unsupported connectivity commands', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      expect(orchestrator.canHandleCommand(command), isFalse);
    });

    test('propagates connectivity capability execution results', () async {
      final platform = MockAssistantPlatform();
      final connectivityCapability = TestCapability(
          true, ExecutionResult.failure('Test failure'));
      final orchestrator = AssistantOrchestrator([connectivityCapability]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Test failure'));
    });

    test('does not execute unrelated capability for connectivity command', () async {
      final platform = MockAssistantPlatform();
      // First capability says it can't handle the command
      final incapable = TestCapability(false, ExecutionResult.success());
      // Second capability says it can handle and returns success
      final capable = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([incapable, capable]);

      final command = ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });
  });

  group('FlashlightCapability', () {
    test('routes flashlight on command to flashlight capability', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes flashlight off command to flashlight capability', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.off);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('returns unsupported result for unsupported flashlight command', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.unsupported));
      expect(result.message, contains('No capability found'));
    });

    test('canHandleCommand returns true for supported flashlight commands', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      expect(orchestrator.canHandleCommand(command), isTrue);
    });

    test('canHandleCommand returns false for unsupported flashlight commands', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      expect(orchestrator.canHandleCommand(command), isFalse);
    });

    test('propagates flashlight capability execution results', () async {
      final platform = MockAssistantPlatform();
      final flashlightCapability = TestCapability(
          true, ExecutionResult.failure('Test failure'));
      final orchestrator = AssistantOrchestrator([flashlightCapability]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Test failure'));
    });

    test('does not execute unrelated capability for flashlight command', () async {
      final platform = MockAssistantPlatform();
      // First capability says it can't handle the command
      final incapable = TestCapability(false, ExecutionResult.success());
      // Second capability says it can handle and returns success
      final capable = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([incapable, capable]);

      final command = FlashlightCommand(action: FlashlightAction.on);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });
  });

  group('ScreenshotCapability', () {
    test('routes screenshot command to screenshot capability', () async {
      final platform = MockAssistantPlatform();
      final screenshotCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([screenshotCapability]);

      final command = ScreenshotCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('returns unsupported result for unsupported screenshot command', () async {
      final platform = MockAssistantPlatform();
      final screenshotCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([screenshotCapability]);

      final command = ScreenshotCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.unsupported));
      expect(result.message, contains('No capability found'));
    });

    test('canHandleCommand returns true for supported screenshot commands', () async {
      final platform = MockAssistantPlatform();
      final screenshotCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([screenshotCapability]);

      final command = ScreenshotCommand();
      expect(orchestrator.canHandleCommand(command), isTrue);
    });

    test('canHandleCommand returns false for unsupported screenshot commands', () async {
      final platform = MockAssistantPlatform();
      final screenshotCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([screenshotCapability]);

      final command = ScreenshotCommand();
      expect(orchestrator.canHandleCommand(command), isFalse);
    });

    test('propagates screenshot capability execution results', () async {
      final platform = MockAssistantPlatform();
      final screenshotCapability = TestCapability(
          true, ExecutionResult.failure('Test failure'));
      final orchestrator = AssistantOrchestrator([screenshotCapability]);

      final command = ScreenshotCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Test failure'));
    });

    test('does not execute unrelated capability for screenshot command', () async {
      final platform = MockAssistantPlatform();
      // First capability says it can't handle the command
      final incapable = TestCapability(false, ExecutionResult.success());
      // Second capability says it can handle and returns success
      final capable = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([incapable, capable]);

      final command = ScreenshotCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });
  });

  group('SpotifyCapability', () {
    test('routes Spotify open command to Spotify capability', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyOpenCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes Spotify playback command to Spotify capability', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.play);
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes Spotify play track command to Spotify capability', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyPlayTrackCommand(query: 'test song');
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes Spotify play artist command to Spotify capability', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyPlayArtistCommand(query: 'test artist');
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('routes Spotify play playlist command to Spotify capability', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyPlayPlaylistCommand(query: 'test playlist');
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });

    test('returns unsupported result for unsupported Spotify command', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyOpenCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.unsupported));
      expect(result.message, contains('No capability found'));
    });

    test('canHandleCommand returns true for supported Spotify commands', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyOpenCommand();
      expect(orchestrator.canHandleCommand(command), isTrue);
    });

    test('canHandleCommand returns false for unsupported Spotify commands', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(false, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyOpenCommand();
      expect(orchestrator.canHandleCommand(command), isFalse);
    });

    test('propagates Spotify capability execution results', () async {
      final platform = MockAssistantPlatform();
      final spotifyCapability = TestCapability(
          true, ExecutionResult.failure('Test failure'));
      final orchestrator = AssistantOrchestrator([spotifyCapability]);

      final command = SpotifyOpenCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Test failure'));
    });

    test('does not execute unrelated capability for Spotify command', () async {
      final platform = MockAssistantPlatform();
      // First capability says it can't handle the command
      final incapable = TestCapability(false, ExecutionResult.success());
      // Second capability says it can handle and returns success
      final capable = TestCapability(true, ExecutionResult.success());
      final orchestrator = AssistantOrchestrator([incapable, capable]);

      final command = SpotifyOpenCommand();
      final result = await orchestrator.executeCommand(command);

      expect(result.isSuccess, isTrue);
    });
  });
}