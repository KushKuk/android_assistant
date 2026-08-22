import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/capabilities/spotify_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/services/settings_repository.dart';

class MockAssistantPlatform implements AssistantPlatform {
  final _eventController = StreamController<Map<Object?, Object?>>.broadcast();

  bool isSpotifyInstalledValue = true;
  bool openSpotifyCalled = false;
  bool playSpotifyCalled = false;
  bool pauseSpotifyCalled = false;
  bool resumeSpotifyCalled = false;
  bool nextSpotifyCalled = false;
  bool previousSpotifyCalled = false;
  bool openSpotifyShouldThrow = false;
  bool hasBluetoothPermissionValue = false;
  bool requestBluetoothPermissionResult = false;
  String? lastTrackQuery;
  String? lastArtistQuery;
  String? lastPlaylistQuery;

  // System Service methods
  bool pingSystemServiceValue = true;
  String? systemServiceVersion = "1.0.0-prototype";
  String? systemServiceStatus = "OK";

  @override
  Stream<Map<Object?, Object?>> get events => _eventController
      .stream
      .where((event) => event is Map)
      .map((event) => Map<Object?, Object?>.from(event as Map));

  @override
  Future<AssistantIntegrationStatus> getIntegrationStatus() async {
    return const AssistantIntegrationStatus.unavailable();
  }

  @override
  Future<void> syncSettings(AssistantSettings settings) async {}

  @override
  Future<bool> hasContactsPermission() async => true;

  @override
  Future<bool> requestContactsPermission() async => true;

  @override
  Future<ContactSearchResult> resolveContacts(String query) async =>
      ContactSearchResult(query: query, candidates: []);

  @override
  Future<bool> hasCallPermission() async => true;

  @override
  Future<bool> requestCallPermission() async => true;

  @override
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  }) async =>
      CallExecutionResult(status: CallExecutionStatus.callFailed, message: 'Failed');

  @override
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  }) async =>
      CallExecutionResult(status: CallExecutionStatus.callFailed, message: 'Failed');

  @override
  Future<TtsSpeakResult> speak(String text) async =>
      const TtsSpeakResult(success: false, message: 'Not implemented');

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<TtsState> getTtsStatus() async => TtsState.idle;

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<bool> hasBluetoothPermission() async => hasBluetoothPermissionValue;

  @override
  Future<bool> requestBluetoothPermission() async => requestBluetoothPermissionResult;

  @override
  Future<SttResult> startListening() async => const SttResult(success: false, message: 'Not implemented');

  @override
  Future<SttResult> stopListening() async => const SttResult(success: false, message: 'Not implemented');

  @override
  Future<SttResult> cancelListening() async => const SttResult(success: false, message: 'Not implemented');

  @override
  Future<SttState> getSpeechRecognitionStatus() async => SttState.idle;

  @override
  Future<void> startWakeWordDetection() async {}

  @override
  Future<void> stopWakeWordDetection() async {}

  // Spotify methods
  @override
  Future<bool> isSpotifyInstalled() async => isSpotifyInstalledValue;

  @override
  Future<void> openSpotify() async {
    if (openSpotifyShouldThrow) {
      throw Exception('Test exception');
    }
    openSpotifyCalled = true;
  }

  @override
  Future<void> playSpotify() async => playSpotifyCalled = true;

  @override
  Future<void> pauseSpotify() async => pauseSpotifyCalled = true;

  @override
  Future<void> resumeSpotify() async => resumeSpotifyCalled = true;

  @override
  Future<void> nextSpotify() async => nextSpotifyCalled = true;

  @override
  Future<void> previousSpotify() async => previousSpotifyCalled = true;

  @override
  Future<void> searchAndPlayTrack(String query) async {
    lastTrackQuery = query;
  }

  @override
  Future<void> searchAndPlayArtist(String query) async {
    lastArtistQuery = query;
  }

  @override
  Future<void> searchAndPlayPlaylist(String query) async {
    lastPlaylistQuery = query;
  }

  // System Service methods
  @override
  Future<bool> pingSystemService() async => pingSystemServiceValue;

  @override
  Future<String?> getSystemServiceVersion() async => systemServiceVersion;

  @override
  Future<String?> getSystemServiceStatus() async => systemServiceStatus;

  @override
  Future<String?> executeSystemOperation(String operation, String action, {Map<String, dynamic>? args}) async {
    // Return a dummy JSON result for testing
    return '{"status":"SUCCESS","operation":"$operation","message":"Test successful","silent":true,"requiresUserAction":false}';
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
}

void main() {
  group('SpotifyCapability', () {
    test('returns true for SpotifyOpenCommand', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyOpenCommand();

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlaybackCommand play', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.play);

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlaybackCommand pause', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.pause);

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlaybackCommand resume', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.resume);

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlaybackCommand next', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.next);

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlaybackCommand previous', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.previous);

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlayTrackCommand', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayTrackCommand(query: 'test song');

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlayArtistCommand', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayArtistCommand(query: 'test artist');

      expect(capability.canHandle(command), isTrue);
    });

    test('returns true for SpotifyPlayPlaylistCommand', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayPlaylistCommand(query: 'test playlist');

      expect(capability.canHandle(command), isTrue);
    });

    test('returns false for non-Spotify command', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = CallCommand(contactQuery: 'Mom');

      expect(capability.canHandle(command), isFalse);
    });

    test('executes SpotifyOpenCommand successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyOpenCommand();

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Opening Spotify'));
      expect(platform.openSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlaybackCommand play successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.play);

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Playing Spotify'));
      expect(platform.playSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlaybackCommand pause successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.pause);

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Pausing Spotify'));
      expect(platform.pauseSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlaybackCommand resume successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.resume);

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Resuming Spotify'));
      expect(platform.resumeSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlaybackCommand next successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.next);

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Skipping to next track'));
      expect(platform.nextSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlaybackCommand previous successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlaybackCommand(action: SpotifyPlaybackAction.previous);

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Skipping to previous track'));
      expect(platform.previousSpotifyCalled, isTrue);
    });

    test('executes SpotifyPlayTrackCommand successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayTrackCommand(query: 'Blinding Lights');

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Playing track: Blinding Lights'));
      expect(platform.lastTrackQuery, equals('Blinding Lights'));
    });

    test('executes SpotifyPlayArtistCommand successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayArtistCommand(query: 'The Weeknd');

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Playing artist: The Weeknd'));
      expect(platform.lastArtistQuery, equals('The Weeknd'));
    });

    test('executes SpotifyPlayPlaylistCommand successfully', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = SpotifyPlayPlaylistCommand(query: 'Workout');

      final result = await capability.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Playing playlist: Workout'));
      expect(platform.lastPlaylistQuery, equals('Workout'));
    });

    test('returns invalidArguments for non-Spotify command', () async {
      final platform = MockAssistantPlatform();
      final capability = SpotifyCapability(platform);
      final command = CallCommand(contactQuery: 'Mom');

      final result = await capability.execute(command);

      expect(result.status, equals(ExecutionStatus.invalidArguments));
      expect(result.message, contains('SpotifyCapability can only handle SpotifyCommand'));
    });

    test('returns failure when platform throws exception', () async {
      final platform = MockAssistantPlatform();
      // Set the flag to make openSpotify throw an exception
      platform.openSpotifyShouldThrow = true;
      final capability = SpotifyCapability(platform);
      final command = SpotifyOpenCommand();

      final result = await capability.execute(command);

      expect(result.status, equals(ExecutionStatus.failure));
      expect(result.message, equals('Spotify execution failed: Exception: Test exception'));

      // Reset the flag for other tests (if any)
      platform.openSpotifyShouldThrow = false;
    });

    test('returns unavailable when Spotify is not installed', () async {
      final platform = MockAssistantPlatform();
      platform.isSpotifyInstalledValue = false; // Spotify not installed
      final capability = SpotifyCapability(platform);
      final command = SpotifyOpenCommand();

      final result = await capability.execute(command);

      expect(result.status, equals(ExecutionStatus.unavailable));
      expect(result.message, contains('Spotify is not installed'));
    });
  });
}