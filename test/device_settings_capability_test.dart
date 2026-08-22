import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/capabilities/device_settings_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/device_settings_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
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
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/execution_result.dart';

/// A minimal mock platform for testing DeviceSettingsCapability
class MockPlatformForDeviceSettings implements AssistantPlatform {
  final Map<String, String?> _results = {};

  MockPlatformForDeviceSettings({Map<String, String?>? results}) {
    if (results != null) _results.addAll(results);
  }

  @override
  Future<String?> executeSystemOperation(String operation, String action,
      {Map<String, dynamic>? args}) {
    final key = '$operation.$action';
    return Future.value(_results[key]);
  }

  void setResult(String operation, String action, String? result) {
    final key = '$operation.$action';
    _results[key] = result;
  }

  // Dummy implementations for other required methods - shouldn't be called in our tests
  @override
  Future<bool> pingSystemService() => Future.value(false);

  @override
  Future<String?> getSystemServiceVersion() => Future.value(null);

  @override
  Future<String?> getSystemServiceStatus() => Future.value(null);

  @override
  Future<AssistantIntegrationStatus> getIntegrationStatus() =>
      Future.value(const AssistantIntegrationStatus.unavailable());

  @override
  Future<bool> hasContactsPermission() => Future.value(false);

  @override
  Future<bool> requestContactsPermission() => Future.value(false);

  @override
  Future<ContactSearchResult> resolveContacts(String query) =>
      throw UnimplementedError();

  @override
  Future<bool> hasCallPermission() => Future.value(false);

  @override
  Future<bool> requestCallPermission() => Future.value(false);

  @override
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  }) =>
      throw UnimplementedError();

  @override
  Future<TtsSpeakResult> speak(String text) =>
      throw UnimplementedError();

  @override
  Future<void> stopSpeaking() async => throw UnimplementedError();

  @override
  Future<TtsState> getTtsStatus() async =>
      throw UnimplementedError();

  @override
  Future<bool> hasMicrophonePermission() => Future.value(false);

  @override
  Future<bool> requestMicrophonePermission() => Future.value(false);

  @override
  Future<SttResult> startListening() =>
      throw UnimplementedError();

  @override
  Future<SttResult> stopListening() =>
      throw UnimplementedError();

  @override
  Future<SttResult> cancelListening() =>
      throw UnimplementedError();

  @override
  Future<SttState> getSpeechRecognitionStatus() =>
      throw UnimplementedError();

  @override
  Stream<Map<Object?, Object?>> get events =>
      const Stream.empty(); // Return empty stream

  @override
  Future<void> syncSettings(AssistantSettings settings) =>
      throw UnimplementedError();

  @override
  Future<bool> hasBluetoothPermission() => Future.value(false);

  @override
  Future<bool> requestBluetoothPermission() => Future.value(false);

  @override
  Future<BluetoothStatusResult> getBluetoothStatus() =>
      throw UnimplementedError();

  @override
  Future<BluetoothActionResult> requestBluetoothEnable() =>
      throw UnimplementedError();

  @override
  Future<BluetoothActionResult> requestBluetoothDisable() =>
      throw UnimplementedError();

  @override
  Future<BluetoothDeviceListResult> getBluetoothDevices({bool onlyBonded = false}) =>
      throw UnimplementedError();

  @override
  Future<BluetoothActionResult> connectBluetoothDevice(String deviceAddress) =>
      throw UnimplementedError();

  @override
  Future<BluetoothActionResult> disconnectBluetoothDevice(String deviceAddress) =>
      throw UnimplementedError();

  @override
  Future<WifiStatusResult> getWifiStatus() =>
      throw UnimplementedError();

  @override
  Future<WifiActionResult> setWifiEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<MobileDataStatusResult> getMobileDataStatus() =>
      throw UnimplementedError();

  @override
  Future<MobileDataActionResult> setMobileDataEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<HotspotStatusResult> getHotspotStatus() =>
      throw UnimplementedError();

  @override
  Future<HotspotActionResult> setHotspotEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<SettingsActionResult> openWifiSettings() =>
      throw UnimplementedError();

  @override
  Future<SettingsActionResult> openMobileDataSettings() =>
      throw UnimplementedError();

  @override
  Future<SettingsActionResult> openHotspotSettings() =>
      throw UnimplementedError();

  @override
  Future<FlashlightAvailabilityResult> getFlashlightAvailability() =>
      throw UnimplementedError();

  @override
  Future<FlashlightActionResult> setFlashlightEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<ScreenshotActionResult> takeScreenshot() =>
      throw UnimplementedError();

  @override
  Future<void> startWakeWordDetection() =>
      throw UnimplementedError();

  @override
  Future<void> stopWakeWordDetection() =>
      throw UnimplementedError();

  @override
  Future<bool> isWhatsAppAvailable() => Future.value(false);

  @override
  Future<Object> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) =>
      throw UnimplementedError();

  @override
  Future<Object> makeWhatsAppCall({
    required String phoneNumber,
    required bool isVideo,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> isSpotifyInstalled() => Future.value(false);

  @override
  Future<void> openSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> playSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> pauseSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> resumeSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> nextSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> previousSpotify() =>
      throw UnimplementedError();

  @override
  Future<void> searchAndPlayTrack(String query) =>
      throw UnimplementedError();

  @override
  Future<void> searchAndPlayArtist(String query) =>
      throw UnimplementedError();

  @override
  Future<void> searchAndPlayPlaylist(String query) =>
      throw UnimplementedError();
}

void main() {
  group('DeviceSettingsCapability', () {
    late MockPlatformForDeviceSettings mockPlatform;
    late DeviceSettingsCapability capability;

    setUp(() {
      mockPlatform = MockPlatformForDeviceSettings();
      capability = DeviceSettingsCapability(mockPlatform);
    });

    test('canHandle returns true for DeviceSettingsCommand', () {
      final command = DeviceSettingsCommand(
        settingsType: DeviceSettingsType.volumeMedia,
        action: DeviceSettingsAction.getStatus,
      );
      expect(capability.canHandle(command), isTrue);
    });

    test('canHandle returns false for non-DeviceSettingsCommand', () {
      final command = CallCommand(contactQuery: 'Mom');
      expect(capability.canHandle(command), isFalse);
    });

    group('volume media', () {
      test('get returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.volume.media",
            "message": "Volume retrieved successfully",
            "silent": true,
            "requiresUserAction": false,
            "currentValue": 50
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.volume.media');
        expect(deviceResult.message, 'Volume retrieved successfully');
        expect(deviceResult.silent, isTrue);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 50);
      });

      test('set returns success', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.volume.media",
            "message": "Volume set to 75%",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.set,
          value: 75,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.volume.media');
        expect(deviceResult.message, 'Volume set to 75%');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
      });
    });

    group('brightness', () {
      test('get returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.brightness',
          'get',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.brightness",
            "message": "Brightness retrieved successfully",
            "silent": true,
            "requiresUserAction": false,
            "currentValue": 60
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.brightness,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.brightness');
        expect(deviceResult.message, 'Brightness retrieved successfully');
        expect(deviceResult.silent, isTrue);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 60);
      });

      test('set returns permissionRequired when WRITE_SETTINGS missing', () async {
        mockPlatform.setResult(
          'settings.brightness',
          'set',
          '''
          {
            "status": "PERMISSION_REQUIRED",
            "operation": "settings.brightness",
            "message": "WRITE_SETTINGS permission required",
            "silent": false,
            "requiresUserAction": true
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.brightness,
          action: DeviceSettingsAction.set,
          value: 70,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.permissionRequired));
        expect(result.message, contains('WRITE_SETTINGS permission required'));
      });
    });

    group('flashlight', () {
      test('get returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.flashlight',
          'get',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.flashlight",
            "message": "Flashlight status retrieved",
            "silent": true,
            "requiresUserAction": false,
            "currentValue": "OFF"
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.flashlight,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.flashlight');
        expect(deviceResult.message, 'Flashlight status retrieved');
        expect(deviceResult.silent, isTrue);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 'OFF');
      });

      test('set on returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.flashlight',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.flashlight",
            "message": "Flashlight enabled",
            "silent": false,
            "requiresUserAction": false,
            "currentValue": "ON"
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.flashlight,
          action: DeviceSettingsAction.set,
          value: true,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.flashlight');
        expect(deviceResult.message, 'Flashlight enabled');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 'ON');
      });

      test('set off returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.flashlight',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.flashlight",
            "message": "Flashlight disabled",
            "silent": false,
            "requiresUserAction": false,
            "currentValue": "OFF"
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.flashlight,
          action: DeviceSettingsAction.set,
          value: false,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.flashlight');
        expect(deviceResult.message, 'Flashlight disabled');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 'OFF');
      });

      test('toggle returns success', () async {
        mockPlatform.setResult(
          'settings.flashlight',
          'toggle',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.flashlight",
            "message": "Flashlight toggled",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.flashlight,
          action: DeviceSettingsAction.toggle,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.flashlight');
        expect(deviceResult.message, 'Flashlight toggled');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
      });

      test('unsupported device returns unsupported', () async {
        mockPlatform.setResult(
          'settings.flashlight',
          'get',
          '''
          {
            "status": "UNSUPPORTED",
            "operation": "settings.flashlight",
            "message": "Device lacks flashlight hardware",
            "silent": true,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.flashlight,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.unsupported));
        expect(result.message, equals('Device lacks flashlight hardware'));
      });
    });

    group('ringer mode', () {
      test('get returns success with currentValue', () async {
        mockPlatform.setResult(
          'settings.ringer',
          'get',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.ringer",
            "message": "Ringer mode retrieved successfully",
            "silent": true,
            "requiresUserAction": false,
            "currentValue": "VIBRATE"
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.ringerMode,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.ringer');
        expect(deviceResult.message, 'Ringer mode retrieved successfully');
        expect(deviceResult.silent, isTrue);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 'VIBRATE');
      });

      test('set to silent returns success', () async {
        mockPlatform.setResult(
          'settings.ringer',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.ringer",
            "message": "Ringer mode set to SILENT",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.ringerMode,
          action: DeviceSettingsAction.set,
          value: 'SILENT',
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.ringer');
        expect(deviceResult.message, 'Ringer mode set to SILENT');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
      });

      test('set to normal returns success', () async {
        mockPlatform.setResult(
          'settings.ringer',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.ringer",
            "message": "Ringer mode set to NORMAL",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.ringerMode,
          action: DeviceSettingsAction.set,
          value: 'NORMAL',
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.ringer');
        expect(deviceResult.message, 'Ringer mode set to NORMAL');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
      });
    });

    group('do not disturb', () {
      test('get returns success with currentValue when permission granted', () async {
        mockPlatform.setResult(
          'settings.dnd',
          'get',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.dnd",
            "message": "DND status retrieved successfully",
            "silent": true,
            "requiresUserAction": false,
            "currentValue": "ENABLED"
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.dnd,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.dnd');
        expect(deviceResult.message, 'DND status retrieved successfully');
        expect(deviceResult.silent, isTrue);
        expect(deviceResult.requiresUserAction, isFalse);
        expect(deviceResult.currentValue, 'ENABLED');
      });

      test('get returns userActionRequired when permission missing', () async {
        mockPlatform.setResult(
          'settings.dnd',
          'get',
          '''
          {
            "status": "USER_ACTION_REQUIRED",
            "operation": "settings.dnd",
            "message": "Notification Policy Access permission required",
            "silent": false,
            "requiresUserAction": true
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.dnd,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.userActionRequired));
        expect(result.message,
            contains('Notification Policy Access permission required'));
      });

      test('set returns success', () async {
        mockPlatform.setResult(
          'settings.dnd',
          'set',
          '''
          {
            "status": "SUCCESS",
            "operation": "settings.dnd",
            "message": "DND enabled",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.dnd,
          action: DeviceSettingsAction.set,
          value: true,
        );

        final result = await capability.execute(command);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<DeviceSettingsResult>());
        final deviceResult = result.data as DeviceSettingsResult;
        expect(deviceResult.status, 'SUCCESS');
        expect(deviceResult.operation, 'settings.dnd');
        expect(deviceResult.message, 'DND enabled');
        expect(deviceResult.silent, isFalse);
        expect(deviceResult.requiresUserAction, isFalse);
      });
    });

    group('error handling', () {
      test('unsupported operation returns unsupported', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          '''
          {
            "status": "UNSUPPORTED",
            "operation": "settings.volume.media",
            "message": "Operation not supported",
            "silent": true,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.unsupported));
        expect(result.message, equals('Operation not supported'));
      });

      test('failed operation returns failure', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          '''
          {
            "status": "FAILED",
            "operation": "settings.volume.media",
            "message": "Volume operation failed",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.failure));
        expect(result.message, equals('Volume operation failed'));
      });

      test('denied operation returns failure', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          '''
          {
            "status": "DENIED",
            "operation": "settings.volume.media",
            "message": "Operation denied by system",
            "silent": false,
            "requiresUserAction": false
          }
          ''',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.failure)); // DENIED maps to failure
        expect(result.message, equals('Operation denied by system'));
      });

      test('null result returns failure', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          null,
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.failure));
        expect(result.message,
            equals('System operation returned null result'));
      });

      test('invalid JSON returns failure', () async {
        mockPlatform.setResult(
          'settings.volume.media',
          'get',
          'invalid json',
        );

        final command = DeviceSettingsCommand(
          settingsType: DeviceSettingsType.volumeMedia,
          action: DeviceSettingsAction.getStatus,
        );

        final result = await capability.execute(command);

        expect(result.status, equals(ExecutionStatus.failure));
        expect(result.message,
            contains('Failed to parse system operation result'));
      });
    });
  });
}