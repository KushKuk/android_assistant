import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/services/assistant_controller.dart';
import 'package:voice_assistant/services/settings_repository.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';
import 'package:voice_assistant/models/assistant_state.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  Future<void> save(AssistantSettings settings) async {}

  @override
  AssistantSettings load() => AssistantSettings.defaults();
}

class MockAssistantPlatform implements AssistantPlatform {
  final _eventController = StreamController<Map<Object?, Object?>>.broadcast();

  bool hasMicPermission = true;
  bool requestMicPermissionResult = true;
  bool hasContactPermission = true;
  bool requestContactPermissionResult = true;
  bool hasBluetoothPermissionValue = false;
  bool requestBluetoothPermissionResult = false;

  @override
  Stream<Map<Object?, Object?>> get events => _eventController.stream;

  void emitEvent(Map<String, dynamic> event) {
    _eventController.add(event);
  }

  @override
  Future<SttResult> cancelListening() async => const SttResult(success: true);

  @override
  Future<CallExecutionResult> confirmCall({required String confirmationToken, required bool confirmed}) async {
    return const CallExecutionResult(status: CallExecutionStatus.callFailed, message: 'Failed');
  }

  @override
  Future<AssistantIntegrationStatus> getIntegrationStatus() async {
    return const AssistantIntegrationStatus.unavailable();
  }

  @override
  Future<TtsState> getTtsStatus() async => TtsState.idle;

  @override
  Future<bool> hasMicrophonePermission() async => hasMicPermission;

  @override
  Future<SttState> getSpeechRecognitionStatus() async => SttState.idle;

  @override
  Future<bool> requestMicrophonePermission() async => requestMicPermissionResult;

  @override
  Future<bool> hasCallPermission() async => true;

  @override
  Future<bool> hasContactsPermission() async => hasContactPermission;

  @override
  Future<bool> requestCallPermission() async => true;

  @override
  Future<bool> requestContactsPermission() async => requestContactPermissionResult;

  // Bluetooth permission methods
  @override
  Future<bool> hasBluetoothPermission() async => hasBluetoothPermissionValue;

  @override
  Future<bool> requestBluetoothPermission() async => requestBluetoothPermissionResult;

  @override
  Future<CallExecutionResult> prepareCall({String? contactId, String? phoneNumber, String? displayName}) async {
    // Simulate a successful prepareCall that requires confirmation
    return CallExecutionResult(
      status: CallExecutionStatus.confirmationRequired,
      message: 'Call confirmation required',
      confirmationToken: 'test-token-123',
    );
  }

  @override
  Future<ContactSearchResult> resolveContacts(String query) async {
    // Return a mock contact for "Mom"
    if (query.toLowerCase().contains('mom')) {
      return ContactSearchResult(
        query: query,
        candidates: [
          ContactCandidate(
            contactId: '1',
            displayName: 'Mom',
            phoneNumbers: ['555-0123'],
            isExactNameMatch: true,
          )
        ],
      );
    }
    return ContactSearchResult(query: query, candidates: []);
  }

  @override
  Future<TtsSpeakResult> speak(String text) async => const TtsSpeakResult(success: true);

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> syncSettings(AssistantSettings settings) async {}

  @override
  Future<SttResult> startListening() async {
    // Simulate platform starting to listen
    return const SttResult(success: true);
  }

  @override
  Future<SttResult> stopListening() async {
    // Simulate platform stopping to listen
    return const SttResult(success: true);
  }

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

  // Wake word methods
  @override
  Future<void> startWakeWordDetection() async {}

  @override
  Future<void> stopWakeWordDetection() async {}

  // Spotify methods
  @override
  Future<bool> isSpotifyInstalled() async => true;

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
}

void main() {
  group('Command Execution Benchmark', () {
    late MockSettingsRepository repository;
    late MockAssistantPlatform platform;
    late AssistantSettings defaultSettings;

    setUp(() {
      repository = MockSettingsRepository();
      platform = MockAssistantPlatform();
      defaultSettings = AssistantSettings.defaults();
    });

    AssistantController createController() {
      final controller = AssistantController(repository, defaultSettings, platform);
      return controller;
    }

    test('benchmark CallMom end-to-end latency', () async {
      final controller = createController();
      await controller.initializeNativeBridge();

      // Clear any existing events
      await Future.delayed(Duration.zero);

      // Start listening (simulates wake word detection)
      final listenStart = DateTime.now().millisecondsSinceEpoch;
      print('BENCHMARK: [TIMESTAMP] startListening() called at: $listenStart');
      await controller.startListening();
      platform.emitEvent({'type': 'listening_started'});
      await Future.delayed(Duration.zero);

      // Simulate final transcript for "Call Mom"
      final transcriptStart = DateTime.now().millisecondsSinceEpoch;
      print('BENCHMARK: [TIMESTAMP] final_transcript event emitted at: $transcriptStart');
      platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});

      // Wait for processing to complete
      await Future.delayed(const Duration(milliseconds: 100));

      final transcriptEnd = DateTime.now().millisecondsSinceEpoch;
      print('BENCHMARK: [TIMESTAMP] Processing completed at: $transcriptEnd, total: ${transcriptEnd - transcriptStart} ms');

      // Check state
      expect(controller.state, AssistantState.processing);
      expect(controller.hasPendingCommand, isTrue);

      // Now trigger command execution by stopping listening
      final stopStart = DateTime.now().millisecondsSinceEpoch;
      print('BENCHMARK: [TIMESTAMP] stopListening() called at: $stopStart');
      await controller.stopListening();
      await Future.delayed(const Duration(milliseconds: 100));

      final stopEnd = DateTime.now().millisecondsSinceEpoch;
      print('BENCHMARK: [TIMESTAMP] Command execution completed at: $stopEnd, stop-to-complete: ${stopEnd - stopStart} ms');

      // Should be in calling state after successful execution
      // Note: With our mock, prepareCall returns confirmationRequired, then we immediately confirm
      // which should lead to calling state
      print('BENCHMARK: Final state: ${controller.state}');

      // Clean up
      controller.dispose();
    });
  });
}