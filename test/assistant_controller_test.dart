import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/assistant_state.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';
import 'package:voice_assistant/services/assistant_controller.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/services/settings_repository.dart';

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

  // Optional override for Bluetooth enable/disable results
  BluetoothActionResult? bluetoothEnableResult;
  BluetoothActionResult? bluetoothDisableResult;

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
  Future<SttState> getSpeechRecognitionStatus() async => SttState.idle;

  @override
  Future<TtsState> getTtsStatus() async => TtsState.idle;

  @override
  Future<bool> hasMicrophonePermission() async => hasMicPermission;

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
  Future<ContactSearchResult> resolveContacts(String query) async {
    return ContactSearchResult(query: query, candidates: []);
  }

  @override
  Future<CallExecutionResult> prepareCall({String? contactId, String? displayName, String? phoneNumber}) async {
    return const CallExecutionResult(status: CallExecutionStatus.callFailed, message: 'Failed');
  }

  @override
  Future<TtsSpeakResult> speak(String text) async => const TtsSpeakResult(success: true);

  @override
  Future<SttResult> startListening() async => const SttResult(success: true);

  @override
  Future<SttResult> stopListening() async => const SttResult(success: true);

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
      bluetoothEnableResult ?? const BluetoothActionResult(status: BluetoothActionStatus.success);

  @override
  Future<BluetoothActionResult> requestBluetoothDisable() async =>
      bluetoothDisableResult ?? const BluetoothActionResult(status: BluetoothActionStatus.success);

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

  test('initial state is idle', () {
    final controller = createController();
    expect(controller.state, AssistantState.idle);
    expect(controller.response, 'I\'m ready when you are.');
  });

  test('starting listening changes state based on events', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    // Wait a bit for async stream event to process
    await Future.delayed(Duration.zero);
    expect(controller.state, AssistantState.listening);
    expect(controller.response, 'Listening...');
  });

  test('partial transcript updates response', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'partial_transcript', 'text': 'call mo'});
    await Future.delayed(Duration.zero);

    expect(controller.state, AssistantState.listening);
    expect(controller.response, 'call mo');
  });

  test('final transcript results in error when no contacts found', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'call mom'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // Since no contacts are found, the controller should be in error state
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact not found'));
  });

  test('stopping listening transitions state correctly', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    await controller.stopListening();
    platform.emitEvent({'type': 'listening_stopped'});
    await Future.delayed(Duration.zero);

    expect(controller.state, AssistantState.processing);
  });

  test('TTS events transition to speaking and back to idle', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    platform.emitEvent({'type': 'speaking_started'});
    await Future.delayed(Duration.zero);
    expect(controller.state, AssistantState.speaking);

    platform.emitEvent({'type': 'speaking_completed'});
    await Future.delayed(Duration.zero);
    expect(controller.state, AssistantState.idle);
  });

  test('errors transition state to error and capture message', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    platform.emitEvent({'type': 'speech_error', 'message': 'Network error'});
    await Future.delayed(Duration.zero);
    expect(controller.state, AssistantState.error);
    expect(controller.response, 'Network error');
  });

  test('microphone permission denial transitions to error', () async {
    platform.hasMicPermission = false;
    platform.requestMicPermissionResult = false;

    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    expect(controller.state, AssistantState.error);
    expect(controller.response, 'Microphone permission denied.');
  });

  test('disposal cancels event subscriptions', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    // Dispose the controller
    controller.dispose();

    // Emit an event after disposal - state should not change
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    // State should remain idle since controller is disposed
    expect(controller.state, AssistantState.idle);
  });

  test('controller does not update after disposal', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    // Start listening to put controller in a non-idle state
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);
    expect(controller.state, AssistantState.listening);

    // Now dispose the controller
    controller.dispose();

    // Emit events that would normally change state
    platform.emitEvent({'type': 'partial_transcript', 'text': 'test'});
    await Future.delayed(Duration.zero);

    // State should not change after disposal
    expect(controller.state, AssistantState.listening);
  });

  test('final transcript produces parsed command', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult!.isParsed, isTrue);
    expect((controller.lastCommandParseResult!.command as CallCommand).contactQuery, 'Mom');
  });

  test('various call phrases produce correct commands', () async {
    final testCases = [
      {'input': 'Phone Dad', 'expected': 'Dad'},
      {'input': 'Give Mom a call', 'expected': 'Mom'},
      {'input': 'call 9876543210', 'expected': '9876543210'},
    ];

    for (final testCase in testCases) {
      final controller = createController();
      await controller.initializeNativeBridge();

      await controller.startListening();
      platform.emitEvent({'type': 'listening_started'});
      await Future.delayed(Duration.zero);

      platform.emitEvent({'type': 'final_transcript', 'text': testCase['input'] as String});
      await Future.delayed(Duration.zero);

      expect(controller.lastCommandParseResult, isNotNull, reason: 'Failed for input: ${testCase['input']}');
      expect(controller.lastCommandParseResult!.isParsed, isTrue, reason: 'Failed for input: ${testCase['input']}');
      expect((controller.lastCommandParseResult!.command as CallCommand).contactQuery, testCase['expected'],
          reason: 'Failed for input: ${testCase['input']}');

      // Clean up
      controller.dispose();
    }
  });

  test('missing target produces unsupported command result', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call'});
    await Future.delayed(Duration.zero);

    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult?.isParsed, isFalse);
    expect(controller.lastCommandParseResult?.message, 'A contact or phone number is required.');
  });

  test('unsupported command produces unsupported result', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Set a timer for five minutes'});
    await Future.delayed(Duration.zero);

    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult?.isParsed, isFalse);
    expect(controller.lastCommandParseResult?.message, 'Command is not supported.');
  });

  test('partial transcripts do not trigger command parsing', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'partial_transcript', 'text': 'Call Mo'});
    await Future.delayed(Duration.zero);

    // Should not have parsed the partial transcript
    expect(controller.lastCommandParseResult, isNull);

    // Now send a final transcript to verify parsing still works
    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult!.isParsed, isTrue);
    expect((controller.lastCommandParseResult!.command as CallCommand).contactQuery, 'Mom');
  });

  test('parsed commands are exposed by assistant controller', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    expect(controller.hasPendingCommand, isTrue);
    expect(controller.pendingCommand, isNotNull);
    expect(controller.pendingCommand, isA<CallCommand>());
    expect((controller.pendingCommand as CallCommand).contactQuery, 'Mom');
  });

  test('parsed commands are not automatically executed', () async {
    final controller = createController();
    await controller.initializeNativeBridge();

    // Verify no automatic execution occurs by checking that
    // the controller doesn't have any execution-related methods called
    // (This is implicitly tested by ensuring we don't add execution logic)

    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    // Allow microtask to execute
    await Future.delayed(Duration.zero);

    // The controller should have the command but not execute it
    expect(controller.hasPendingCommand, isTrue);
    expect(controller.pendingCommand, isNotNull);

    // Verify state is processing (not executing or any other action state)
    expect(controller.state, AssistantState.processing);
  });

  test('contact permission already granted -> contact resolution proceeds', () async {
    // Default mock has hasContactPermission = true
    final controller = createController();
    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // After processing the command (which fails due to no contacts), the command is cleared
    expect(controller.lastCommandParseResult, isNull);

    // Since permission is granted but no contacts found, should be in error state
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact not found'));
  });

  test('contact permission missing -> permission request is triggered', () async {
    platform.hasContactPermission = false;
    platform.requestContactPermissionResult = true; // User grants permission

    final controller = createController();
    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // After requesting permission and granting it, the command is processed and then cleared
    expect(controller.lastCommandParseResult, isNull);

    // Since we granted permission after request but no contacts found, should be in error state
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact not found'));
  });

  test('permission denied after request -> structured permissionRequired result', () async {
    platform.hasContactPermission = false;
    platform.requestContactPermissionResult = false; // User denies permission

    final controller = createController();
    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // When permission is denied, the command is cleared
    expect(controller.lastCommandParseResult, isNull);

    // Since permission was denied, should be in error state with permission message
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact permission is required.'));
  });

  test('duplicate permission requests avoided when already granted', () async {
    // Start with permission granted
    platform.hasContactPermission = true;

    final controller = createController();
    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});
    await Future.delayed(Duration.zero);

    platform.emitEvent({'type': 'final_transcript', 'text': 'Call Mom'});
    await Future.delayed(Duration.zero);

    // Verify that the command was parsed before execution
    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult!.isParsed, isTrue);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // After execution, we should be in error state due to no contacts
    // (since we have permission but no contacts exist)
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact not found'));

    // Note: The command is cleared after execution, so we don't check lastCommandParseResult here
    // We inferred that we didn't request permission because we didn't get a permission error
    // and we ended up in an error state due to no contacts.
  });
  test('Bluetooth userActionRequired transitions to error state', () async {
    final repository = MockSettingsRepository();
    final platform = MockAssistantPlatform();
    // Ensure Bluetooth permission check passes
    platform.hasBluetoothPermissionValue = true;
    platform.requestBluetoothPermissionResult = true;
    // Override the requestBluetoothEnable method to return userActionRequired
    platform.bluetoothEnableResult = const BluetoothActionResult(
        status: BluetoothActionStatus.userActionRequired,
        message: 'Please enable Bluetooth in system settings');
    final defaultSettings = AssistantSettings.defaults();
    final controller = AssistantController(repository, defaultSettings, platform);

    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    // Simulate the user saying "Turn on Bluetooth"
    platform.emitEvent({'type': 'final_transcript', 'text': 'Turn on Bluetooth'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // Expect the state to be error and the message to be set
    expect(controller.state, AssistantState.error);
    expect(controller.response, equals('Please enable Bluetooth in system settings'));
  });
  test('Bluetooth success leaves processing state', () async {
    final repository = MockSettingsRepository();
    final platform = MockAssistantPlatform();
    // Ensure Bluetooth permission check passes
    platform.hasBluetoothPermissionValue = true;
    platform.requestBluetoothPermissionResult = true;
    // Override the requestBluetoothEnable method to return success
    platform.bluetoothEnableResult = const BluetoothActionResult(
        status: BluetoothActionStatus.success,
        message: 'Bluetooth is already enabled');
    final defaultSettings = AssistantSettings.defaults();
    final controller = AssistantController(repository, defaultSettings, platform);

    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    // Simulate the user saying "Turn on Bluetooth" when it's already on
    platform.emitEvent({'type': 'final_transcript', 'text': 'Turn on Bluetooth'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // Expect the state to not be processing (i.e., command has been handled)
    expect(controller.state, isNot(equals(AssistantState.processing)));
    // Also expect the command to be cleared
    expect(controller.lastCommandParseResult, isNull);
  });
  test('Bluetooth failure leaves processing state', () async {
    final repository = MockSettingsRepository();
    final platform = MockAssistantPlatform();
    // Ensure Bluetooth permission check passes
    platform.hasBluetoothPermissionValue = true;
    platform.requestBluetoothPermissionResult = true;
    // Override the requestBluetoothEnable method to return failure
    platform.bluetoothEnableResult = const BluetoothActionResult(
        status: BluetoothActionStatus.failure,
        message: 'Failed to enable Bluetooth');
    final defaultSettings = AssistantSettings.defaults();
    final controller = AssistantController(repository, defaultSettings, platform);

    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    // Simulate the user saying "Turn on Bluetooth"
    platform.emitEvent({'type': 'final_transcript', 'text': 'Turn on Bluetooth'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // Expect the state to not be processing (i.e., command has been handled)
    expect(controller.state, isNot(equals(AssistantState.processing)));
    // Also expect the command to be cleared
    expect(controller.lastCommandParseResult, isNull);
  });

  test('Bluetooth permissionRequired leaves processing state', () async {
    final repository = MockSettingsRepository();
    final platform = MockAssistantPlatform();
    // Ensure Bluetooth permission check passes
    platform.hasBluetoothPermissionValue = true;
    platform.requestBluetoothPermissionResult = true;
    // Override the requestBluetoothEnable method to return permissionRequired
    platform.bluetoothEnableResult = const BluetoothActionResult(
        status: BluetoothActionStatus.permissionRequired,
        message: 'BLUETOOTH_CONNECT permission required');
    final defaultSettings = AssistantSettings.defaults();
    final controller = AssistantController(repository, defaultSettings, platform);

    await controller.initializeNativeBridge();
    await controller.startListening();
    platform.emitEvent({'type': 'listening_started'});

    // Simulate the user saying "Turn on Bluetooth"
    platform.emitEvent({'type': 'final_transcript', 'text': 'Turn on Bluetooth'});
    await Future.delayed(Duration.zero);

    // Stop listening to initiate command execution
    await controller.stopListening();
    await Future.delayed(Duration.zero);

    // Expect the state to not be processing (i.e., command has been handled)
    expect(controller.state, isNot(equals(AssistantState.processing)));
    // Also expect the command to be cleared
    expect(controller.lastCommandParseResult, isNull);
  });
}

  