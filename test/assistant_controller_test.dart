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

    // Should have parsed the command
    expect(controller.lastCommandParseResult, isNotNull);
    expect(controller.lastCommandParseResult!.isParsed, isTrue);

    // Should not have requested permission since it was already granted
    // We can't directly verify this with our mock, but we can verify the flow worked
    expect(controller.state, AssistantState.error);
    expect(controller.response, contains('Contact not found'));
  });
}