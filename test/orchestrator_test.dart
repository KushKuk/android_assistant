import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/capabilities/bluetooth_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
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
}