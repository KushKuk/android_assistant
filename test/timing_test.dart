import 'dart:async';
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/services/assistant_controller.dart';
import 'package:voice_assistant/services/settings_repository.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';

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
  Future<bool> hasBluetoothPermission() async => true;

  @override
  Future<bool> requestBluetoothPermission() async => true;

  @override
  Future<bool> hasCallPermission() async => true;

  @override
  Future<bool> hasContactsPermission() async => hasContactPermission;

  @override
  Future<bool> requestCallPermission() async => true;

  @override
  Future<bool> requestContactsPermission() async => requestContactPermissionResult;

  @override
  Future<CallExecutionResult> prepareCall({String? contactId, String? displayName, String? phoneNumber}) async {
    return const CallExecutionResult(status: CallExecutionStatus.callFailed, message: 'Failed');
  }

  @override
  Future<bool> requestMicrophonePermission() async => requestMicPermissionResult;

  @override
  Future<ContactSearchResult> resolveContacts(String query) async {
    return ContactSearchResult(query: query, candidates: []);
  }

  @override
  Future<TtsSpeakResult> speak(String text) async => const TtsSpeakResult(success: true);

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> syncSettings(AssistantSettings settings) async {}

  @override
  Future<SttResult> startListening() async => const SttResult(success: true);

  @override
  Future<SttResult> stopListening() async => const SttResult(success: true);

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

  @override
  Future<SttState> getSpeechRecognitionStatus() async => SttState.idle;

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
  Future<void> openSpotify() async {}

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
  test('timing test', () async {
    final repository = MockSettingsRepository();
    final platform = MockAssistantPlatform();
    final defaultSettings = AssistantSettings.defaults();
    final controller = AssistantController(repository, defaultSettings, platform);

    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    // Add a slight delay to let things settle
    await Future.delayed(const Duration(milliseconds: 10));

    print('State: ${controller.state}');
    print('Has pending command: ${controller.hasPendingCommand}');
    print('Last command parse result: ${controller.lastCommandParseResult}');
    if (controller.lastCommandParseResult != null) {
      print('Is parsed: ${controller.lastCommandParseResult!.isParsed}');
      if (controller.lastCommandParseResult!.isParsed) {
        print('Command: ${controller.lastCommandParseResult!.command}');
      }
    }
  });
}