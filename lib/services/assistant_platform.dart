import 'package:flutter/services.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'package:voice_assistant/models/flashlight_result.dart';
import 'package:voice_assistant/models/screenshot_result.dart';

abstract interface class AssistantPlatform {
  Future<AssistantIntegrationStatus> getIntegrationStatus();
  Future<void> syncSettings(AssistantSettings settings);
  Future<bool> hasContactsPermission();
  Future<bool> requestContactsPermission();
  Future<ContactSearchResult> resolveContacts(String query);
  Future<bool> hasCallPermission();
  Future<bool> requestCallPermission();
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  });
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  });
  Future<TtsSpeakResult> speak(String text);
  Future<void> stopSpeaking();
  Future<TtsState> getTtsStatus();
  Future<bool> hasMicrophonePermission();
  Future<bool> requestMicrophonePermission();
  Future<SttResult> startListening();
  Future<SttResult> stopListening();
  Future<SttResult> cancelListening();
  Future<SttState> getSpeechRecognitionStatus();
  Stream<Map<Object?, Object?>> get events;

  // Bluetooth permission methods
  Future<bool> hasBluetoothPermission();
  Future<bool> requestBluetoothPermission();

  // Wake word methods
  Future<void> startWakeWordDetection();
  Future<void> stopWakeWordDetection();

  // Bluetooth methods
  Future<BluetoothStatusResult> getBluetoothStatus();
  Future<BluetoothActionResult> requestBluetoothEnable();
  Future<BluetoothActionResult> requestBluetoothDisable();
  Future<BluetoothDeviceListResult> getBluetoothDevices({
    bool onlyBonded = false,
  });
  Future<BluetoothActionResult> connectBluetoothDevice(String deviceAddress);
  Future<BluetoothActionResult> disconnectBluetoothDevice(String deviceAddress);

  // Connectivity methods
  Future<WifiStatusResult> getWifiStatus();
  Future<WifiActionResult> setWifiEnabled(bool enabled);
  Future<MobileDataStatusResult> getMobileDataStatus();
  Future<MobileDataActionResult> setMobileDataEnabled(bool enabled);
  Future<HotspotStatusResult> getHotspotStatus();
  Future<HotspotActionResult> setHotspotEnabled(bool enabled);
  Future<SettingsActionResult> openWifiSettings();
  Future<SettingsActionResult> openMobileDataSettings();
  Future<SettingsActionResult> openHotspotSettings();

  // Flashlight methods
  Future<FlashlightAvailabilityResult> getFlashlightAvailability();
  Future<FlashlightActionResult> setFlashlightEnabled(bool enabled);

  // Screenshot methods
  Future<ScreenshotActionResult> takeScreenshot();

  // WhatsApp methods
  Future<bool> isWhatsAppAvailable();
  Future<Object> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  });
  Future<Object> makeWhatsAppCall({
    required String phoneNumber,
    required bool isVideo,
  });

  // Spotify methods
  Future<bool> isSpotifyInstalled();
  Future<void> openSpotify();
  Future<void> playSpotify();
  Future<void> pauseSpotify();
  Future<void> resumeSpotify();
  Future<void> nextSpotify();
  Future<void> previousSpotify();
  Future<void> searchAndPlayTrack(String query);
  Future<void> searchAndPlayArtist(String query);
  Future<void> searchAndPlayPlaylist(String query);
}

class MethodChannelAssistantPlatform implements AssistantPlatform {
  static const _methodChannel = MethodChannel(
    'com.example.voice_assistant/assistant',
  );
  static const _eventChannel = EventChannel(
    'com.example.voice_assistant/assistant_events',
  );

  @override
  Stream<Map<Object?, Object?>> get events => _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => Map<Object?, Object?>.from(event as Map));

  @override
  Future<AssistantIntegrationStatus> getIntegrationStatus() async {
    print('DIAG: Platform.getIntegrationStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
        'getIntegrationStatus',
      );
      print('DIAG: Platform.getIntegrationStatus() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getIntegrationStatus() result not Map, returning unavailable');
        return const AssistantIntegrationStatus.unavailable();
      }
      final status = AssistantIntegrationStatus.fromMap(
        Map<Object?, Object?>.from(result),
      );
      print('DIAG: Platform.getIntegrationStatus() returning: $status');
      return status;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getIntegrationStatus() PlatformException: $e');
      return const AssistantIntegrationStatus.unavailable();
    } on MissingPluginException {
      print('DIAG: Platform.getIntegrationStatus() MissingPluginException');
      return const AssistantIntegrationStatus.unavailable();
    }
  }

  @override
  Future<void> syncSettings(AssistantSettings settings) {
    print('DIAG: Platform.syncSettings() entered');
    return _methodChannel.invokeMethod<void>('syncSettings', {
      'assistantName': settings.assistantName,
      'wakeWord': settings.wakeWord,
      'voice': settings.voice,
      'speechRate': settings.speechRate,
      'speechPitch': settings.speechPitch,
      'language': settings.language,
      'wakeWordEnabled': settings.wakeWordEnabled,
      'voiceFeedbackEnabled': settings.voiceFeedbackEnabled,
    }).then((_) {
      print('DIAG: Platform.syncSettings() completed');
    }).catchError((e) {
      print('DIAG: Platform.syncSettings() error: $e');
      throw e;
    });
  }

  @override
  Future<bool> hasContactsPermission() async {
    print('DIAG: Platform.hasContactsPermission() entered');
    final result = await _methodChannel.invokeMethod<bool>('hasContactsPermission') ??
        false;
    print('DIAG: Platform.hasContactsPermission() returning: $result');
    return result;
  }

  @override
  Future<bool> requestContactsPermission() async {
    print('DIAG: Platform.requestContactsPermission() entered');
    final result = await _methodChannel.invokeMethod<Object?>(
      'requestContactsPermission',
    );
    final granted = result is Map && result['granted'] == true;
    print('DIAG: Platform.requestContactsPermission() returning: $granted');
    return granted;
  }

  @override
  Future<ContactSearchResult> resolveContacts(String query) async {
    print('DIAG: Platform.resolveContacts() entered with query: $query');
    final result = await _methodChannel.invokeMethod<Object?>(
      'resolveContacts',
      {'query': query},
    );
    print('DIAG: Platform.resolveContacts() got result: $result');
    if (result is! Map) {
      print('DIAG: Platform.resolveContacts() result not Map, throwing PlatformException');
      throw PlatformException(
        code: 'invalid_contact_response',
        message: 'Android returned an invalid contact search result.',
      );
    }
    final contactResult = ContactSearchResult.fromMap(Map<Object?, Object?>.from(result));
    print('DIAG: Platform.resolveContacts() returning: $contactResult');
    return contactResult;
  }

  @override
  Future<bool> hasCallPermission() async {
    print('DIAG: Platform.hasCallPermission() entered');
    final result = await _methodChannel.invokeMethod<bool>('hasCallPermission') ??
        false;
    print('DIAG: Platform.hasCallPermission() returning: $result');
    return result;
  }

  @override
  Future<bool> requestCallPermission() async {
    print('DIAG: Platform.requestCallPermission() entered');
    final result = await _methodChannel.invokeMethod<Object?>(
      'requestCallPermission',
    );
    final granted = result is Map && result['granted'] == true;
    print('DIAG: Platform.requestCallPermission() returning: $granted');
    return granted;
  }

  @override
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  }) {
    print('DIAG: Platform.prepareCall() entered with contactId: $contactId, phoneNumber: $phoneNumber, displayName: $displayName');
    final result = _invokeCallResult('prepareCall', {
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
    });
    print('DIAG: Platform.prepareCall() got result: $result');
    return result;
  }

  @override
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  }) {
    print('DIAG: Platform.confirmCall() entered with token: $confirmationToken, confirmed: $confirmed');
    final result = _invokeCallResult('confirmCall', {
      'confirmationToken': confirmationToken,
      'confirmed': confirmed,
    });
    print('DIAG: Platform.confirmCall() got result: $result');
    return result;
  }

  Future<CallExecutionResult> _invokeCallResult(
    String method,
    Map<String, Object?> arguments,
  ) async {
    print('DIAG: Platform._invokeCallResult() entered with method: $method, arguments: $arguments');
    final result = await _methodChannel.invokeMethod<Object?>(
      method,
      arguments,
    );
    print('DIAG: Platform._invokeCallResult() got result: $result');
    if (result is! Map) {
      print('DIAG: Platform._invokeCallResult() result not Map, throwing PlatformException');
      throw PlatformException(
        code: 'invalid_call_response',
        message: 'Android returned an invalid call result.',
      );
    }
    final callResult = CallExecutionResult.fromMap(Map<Object?, Object?>.from(result));
    print('DIAG: Platform._invokeCallResult() returning: $callResult');
    return callResult;
  }

  @override
  Future<TtsSpeakResult> speak(String text) async {
    print('DIAG: Platform.speak() entered with text: $text');
    if (text.trim().isEmpty) {
      print('DIAG: Platform.speak() empty text');
      return const TtsSpeakResult(
        success: false,
        message: 'Text must not be empty.',
      );
    }
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
        'speak',
        {'text': text},
      );
      print('DIAG: Platform.speak() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.speak() result not Map');
        return const TtsSpeakResult(
          success: false,
          message: 'Invalid TTS response from Android.',
        );
      }
      final speakResult = TtsSpeakResult.fromMap(Map<Object?, Object?>.from(result));
      print('DIAG: Platform.speak() returning: $speakResult');
      return speakResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.speak() PlatformException: $e');
      return TtsSpeakResult(
        success: false,
        message: e.message ?? 'TTS request failed.',
      );
    }
  }

  @override
  Future<void> stopSpeaking() async {
    print('DIAG: Platform.stopSpeaking() entered');
    try {
      await _methodChannel.invokeMethod<void>('stopSpeaking');
      print('DIAG: Platform.stopSpeaking() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.stopSpeaking() PlatformException: $e');
      // Best-effort: speech may have already completed.
    } on MissingPluginException {
      print('DIAG: Platform.stopSpeaking() MissingPluginException');
      // Non-Android platform.
    }
  }

  @override
  Future<TtsState> getTtsStatus() async {
    print('DIAG: Platform.getTtsStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<String>('getTtsStatus');
      print('DIAG: Platform.getTtsStatus() got result: $result');
      final status = TtsState.fromName(result ?? 'unavailable');
      print('DIAG: Platform.getTtsStatus() returning: $status');
      return status;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getTtsStatus() PlatformException: $e');
      return TtsState.unavailable;
    } on MissingPluginException {
      print('DIAG: Platform.getTtsStatus() MissingPluginException');
      return TtsState.unavailable;
    }
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    print('DIAG: Platform.hasMicrophonePermission() entered');
    final result = await _methodChannel.invokeMethod<bool>('hasMicrophonePermission') ??
        false;
    print('DIAG: Platform.hasMicrophonePermission() returning: $result');
    return result;
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    print('DIAG: Platform.requestMicrophonePermission() entered');
    final result = await _methodChannel.invokeMethod<Object?>(
      'requestMicrophonePermission',
    );
    final granted = result is Map && result['granted'] == true;
    print('DIAG: Platform.requestMicrophonePermission() returning: $granted');
    return granted;
  }

  @override
  Future<bool> hasBluetoothPermission() async {
    print('DIAG: Platform.hasBluetoothPermission() entered');
    final result = await _methodChannel.invokeMethod<bool>('hasBluetoothPermission') ?? false;
    print('DIAG: Platform.hasBluetoothPermission() returning: $result');
    return result;
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    print('DIAG: Platform.requestBluetoothPermission() entered');
    final result = await _methodChannel.invokeMethod<Object?>('requestBluetoothPermission');
    final granted = result is Map && result['granted'] == true;
    print('DIAG: Platform.requestBluetoothPermission() returning: $granted');
    return granted;
  }

  @override
  Future<SttResult> startListening() async {
    print('DIAG: Platform.startListening() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('startListening');
      print('DIAG: Platform.startListening() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.startListening() result not Map');
        return const SttResult(
          success: false,
          message: 'Invalid STT response from Android.',
        );
      }
      final sttResult = SttResult.fromMap(Map<Object?, Object?>.from(result));
      print('DIAG: Platform.startListening() returning: $sttResult');
      return sttResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.startListening() PlatformException: $e');
      if (e.code == 'permission_required') {
        return const SttResult(
          success: false,
          message: 'Microphone permission is required.',
        );
      }
      return SttResult(
        success: false,
        message: e.message ?? 'Failed to start listening.',
      );
    }
  }

  @override
  Future<SttResult> stopListening() async {
    print('DIAG: Platform.stopListening() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('stopListening');
      print('DIAG: Platform.stopListening() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.stopListening() result not Map');
        return const SttResult(success: false);
      }
      final sttResult = SttResult.fromMap(Map<Object?, Object?>.from(result));
      print('DIAG: Platform.stopListening() returning: $sttResult');
      return sttResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.stopListening() PlatformException: $e');
      return SttResult(success: false, message: e.message);
    }
  }

  @override
  Future<SttResult> cancelListening() async {
    print('DIAG: Platform.cancelListening() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('cancelListening');
      print('DIAG: Platform.cancelListening() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.cancelListening() result not Map');
        return const SttResult(success: false);
      }
      final sttResult = SttResult.fromMap(Map<Object?, Object?>.from(result));
      print('DIAG: Platform.cancelListening() returning: $sttResult');
      return sttResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.cancelListening() PlatformException: $e');
      return SttResult(success: false, message: e.message);
    }
  }

  @override
  Future<SttState> getSpeechRecognitionStatus() async {
    print('DIAG: Platform.getSpeechRecognitionStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<String>('getSpeechRecognitionStatus');
      print('DIAG: Platform.getSpeechRecognitionStatus() got result: $result');
      final status = SttState.fromName(result ?? 'unavailable');
      print('DIAG: Platform.getSpeechRecognitionStatus() returning: $status');
      return status;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getSpeechRecognitionStatus() PlatformException: $e');
      return SttState.unavailable;
    } on MissingPluginException {
      print('DIAG: Platform.getSpeechRecognitionStatus() MissingPluginException');
      return SttState.unavailable;
    }
  }

  // Bluetooth methods
  @override
  Future<BluetoothStatusResult> getBluetoothStatus() async {
    print('DIAG: Platform.getBluetoothStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getBluetoothStatus');
      print('DIAG: Platform.getBluetoothStatus() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getBluetoothStatus() result not Map');
        return const BluetoothStatusResult(status: BluetoothStatus.disabled, message: 'Invalid response from Android');
      }
      final statusResult = BluetoothStatusResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getBluetoothStatus() returning: $statusResult');
      return statusResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getBluetoothStatus() PlatformException: $e');
      return BluetoothStatusResult(status: BluetoothStatus.disabled, message: e.message ?? 'Failed to get Bluetooth status');
    } on MissingPluginException {
      print('DIAG: Platform.getBluetoothStatus() MissingPluginException');
      return const BluetoothStatusResult(status: BluetoothStatus.unavailable, message: 'Bluetooth not available on this platform');
    }
  }

  @override
  Future<BluetoothActionResult> requestBluetoothEnable() async {
    print('DIAG: Platform.requestBluetoothEnable() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('requestBluetoothEnable');
      print('DIAG: Platform.requestBluetoothEnable() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.requestBluetoothEnable() result not Map');
        return const BluetoothActionResult(status: BluetoothActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = BluetoothActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.requestBluetoothEnable() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.requestBluetoothEnable() PlatformException: $e');
      return BluetoothActionResult(status: BluetoothActionStatus.failure, message: e.message ?? 'Failed to request Bluetooth enable');
    } on MissingPluginException {
      print('DIAG: Platform.requestBluetoothEnable() MissingPluginException');
      return const BluetoothActionResult(status: BluetoothActionStatus.unsupported, message: 'Bluetooth not available on this platform');
    }
  }

  @override
  Future<BluetoothActionResult> requestBluetoothDisable() async {
    print('DIAG: Platform.requestBluetoothDisable() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('requestBluetoothDisable');
      print('DIAG: Platform.requestBluetoothDisable() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.requestBluetoothDisable() result not Map');
        return const BluetoothActionResult(status: BluetoothActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = BluetoothActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.requestBluetoothDisable() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.requestBluetoothDisable() PlatformException: $e');
      return BluetoothActionResult(status: BluetoothActionStatus.failure, message: e.message ?? 'Failed to request Bluetooth disable');
    } on MissingPluginException {
      print('DIAG: Platform.requestBluetoothDisable() MissingPluginException');
      return const BluetoothActionResult(status: BluetoothActionStatus.unsupported, message: 'Bluetooth not available on this platform');
    }
  }

  @override
  Future<BluetoothDeviceListResult> getBluetoothDevices({
    bool onlyBonded = false,
  }) async {
    print('DIAG: Platform.getBluetoothDevices() entered with onlyBonded: $onlyBonded');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getBluetoothDevices', {
        'onlyBonded': onlyBonded,
      });
      print('DIAG: Platform.getBluetoothDevices() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getBluetoothDevices() result not Map');
        return const BluetoothDeviceListResult(devices: [], message: 'Invalid response from Android');
      }
      final deviceListResult = BluetoothDeviceListResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getBluetoothDevices() returning: $deviceListResult');
      return deviceListResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getBluetoothDevices() PlatformException: $e');
      return BluetoothDeviceListResult(devices: [], message: e.message ?? 'Failed to get Bluetooth devices');
    } on MissingPluginException {
      print('DIAG: Platform.getBluetoothDevices() MissingPluginException');
      return const BluetoothDeviceListResult(devices: [], message: 'Bluetooth not available on this platform');
    }
  }

  @override
  Future<BluetoothActionResult> connectBluetoothDevice(String deviceAddress) async {
    print('DIAG: Platform.connectBluetoothDevice() entered with deviceAddress: $deviceAddress');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('connectBluetoothDevice', {
        'deviceAddress': deviceAddress,
      });
      print('DIAG: Platform.connectBluetoothDevice() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.connectBluetoothDevice() result not Map');
        return const BluetoothActionResult(status: BluetoothActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = BluetoothActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.connectBluetoothDevice() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.connectBluetoothDevice() PlatformException: $e');
      return BluetoothActionResult(status: BluetoothActionStatus.failure, message: e.message ?? 'Failed to connect to Bluetooth device');
    } on MissingPluginException {
      print('DIAG: Platform.connectBluetoothDevice() MissingPluginException');
      return const BluetoothActionResult(status: BluetoothActionStatus.unsupported, message: 'Bluetooth not available on this platform');
    }
  }

  @override
  Future<BluetoothActionResult> disconnectBluetoothDevice(String deviceAddress) async {
    print('DIAG: Platform.disconnectBluetoothDevice() entered with deviceAddress: $deviceAddress');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('disconnectBluetoothDevice', {
        'deviceAddress': deviceAddress,
      });
      print('DIAG: Platform.disconnectBluetoothDevice() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.disconnectBluetoothDevice() result not Map');
        return const BluetoothActionResult(status: BluetoothActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = BluetoothActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.disconnectBluetoothDevice() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.disconnectBluetoothDevice() PlatformException: $e');
      return BluetoothActionResult(status: BluetoothActionStatus.failure, message: e.message ?? 'Failed to disconnect from Bluetooth device');
    } on MissingPluginException {
      print('DIAG: Platform.disconnectBluetoothDevice() MissingPluginException');
      return const BluetoothActionResult(status: BluetoothActionStatus.unsupported, message: 'Bluetooth not available on this platform');
    }
  }

  // Connectivity methods implementation
  @override
  Future<WifiStatusResult> getWifiStatus() async {
    print('DIAG: Platform.getWifiStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getWifiStatus');
      print('DIAG: Platform.getWifiStatus() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getWifiStatus() result not Map');
        return const WifiStatusResult(status: WifiStatus.disabled, message: 'Invalid response from Android');
      }
      final statusResult = WifiStatusResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getWifiStatus() returning: $statusResult');
      return statusResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getWifiStatus() PlatformException: $e');
      return WifiStatusResult(status: WifiStatus.disabled, message: e.message ?? 'Failed to get Wi-Fi status');
    } on MissingPluginException {
      print('DIAG: Platform.getWifiStatus() MissingPluginException');
      return const WifiStatusResult(status: WifiStatus.unavailable, message: 'Wi-Fi not available on this platform');
    }
  }

  @override
  Future<WifiActionResult> setWifiEnabled(bool enabled) async {
    print('DIAG: Platform.setWifiEnabled() entered with enabled: $enabled');
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
          enabled ? 'enableWifi' : 'disableWifi', {});
      print('DIAG: Platform.setWifiEnabled() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.setWifiEnabled() result not Map');
        return const WifiActionResult(status: WifiActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = WifiActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.setWifiEnabled() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.setWifiEnabled() PlatformException: $e');
      return WifiActionResult(status: WifiActionStatus.failure, message: e.message ?? 'Failed to ${enabled ? 'enable' : 'disable'} Wi-Fi');
    } on MissingPluginException {
      print('DIAG: Platform.setWifiEnabled() MissingPluginException');
      return const WifiActionResult(status: WifiActionStatus.unsupported, message: 'Wi-Fi not available on this platform');
    }
  }

  @override
  Future<MobileDataStatusResult> getMobileDataStatus() async {
    print('DIAG: Platform.getMobileDataStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getMobileDataStatus');
      print('DIAG: Platform.getMobileDataStatus() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getMobileDataStatus() result not Map');
        return const MobileDataStatusResult(status: MobileDataStatus.disabled, message: 'Invalid response from Android');
      }
      final statusResult = MobileDataStatusResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getMobileDataStatus() returning: $statusResult');
      return statusResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getMobileDataStatus() PlatformException: $e');
      return MobileDataStatusResult(status: MobileDataStatus.disabled, message: e.message ?? 'Failed to get mobile data status');
    } on MissingPluginException {
      print('DIAG: Platform.getMobileDataStatus() MissingPluginException');
      return const MobileDataStatusResult(status: MobileDataStatus.unavailable, message: 'Mobile data not available on this platform');
    }
  }

  @override
  Future<MobileDataActionResult> setMobileDataEnabled(bool enabled) async {
    print('DIAG: Platform.setMobileDataEnabled() entered with enabled: $enabled');
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
          enabled ? 'enableMobileData' : 'disableMobileData', {});
      print('DIAG: Platform.setMobileDataEnabled() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.setMobileDataEnabled() result not Map');
        return const MobileDataActionResult(status: MobileDataActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = MobileDataActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.setMobileDataEnabled() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.setMobileDataEnabled() PlatformException: $e');
      return MobileDataActionResult(status: MobileDataActionStatus.failure, message: e.message ?? 'Failed to ${enabled ? 'enable' : 'disable'} mobile data');
    } on MissingPluginException {
      print('DIAG: Platform.setMobileDataEnabled() MissingPluginException');
      return const MobileDataActionResult(status: MobileDataActionStatus.unsupported, message: 'Mobile data control not available on this platform');
    }
  }

  @override
  Future<HotspotStatusResult> getHotspotStatus() async {
    print('DIAG: Platform.getHotspotStatus() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getHotspotStatus');
      print('DIAG: Platform.getHotspotStatus() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getHotspotStatus() result not Map');
        return const HotspotStatusResult(status: HotspotStatus.disabled, message: 'Invalid response from Android');
      }
      final statusResult = HotspotStatusResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getHotspotStatus() returning: $statusResult');
      return statusResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getHotspotStatus() PlatformException: $e');
      return HotspotStatusResult(status: HotspotStatus.disabled, message: e.message ?? 'Failed to get hotspot status');
    } on MissingPluginException {
      print('DIAG: Platform.getHotspotStatus() MissingPluginException');
      return const HotspotStatusResult(status: HotspotStatus.unavailable, message: 'Hotspot not available on this platform');
    }
  }

  @override
  Future<HotspotActionResult> setHotspotEnabled(bool enabled) async {
    print('DIAG: Platform.setHotspotEnabled() entered with enabled: $enabled');
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
          enabled ? 'enableHotspot' : 'disableHotspot', {});
      print('DIAG: Platform.setHotspotEnabled() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.setHotspotEnabled() result not Map');
        return const HotspotActionResult(status: HotspotActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = HotspotActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.setHotspotEnabled() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.setHotspotEnabled() PlatformException: $e');
      return HotspotActionResult(status: HotspotActionStatus.failure, message: e.message ?? 'Failed to ${enabled ? 'enable' : 'disable'} hotspot');
    } on MissingPluginException {
      print('DIAG: Platform.setHotspotEnabled() MissingPluginException');
      return const HotspotActionResult(status: HotspotActionStatus.unsupported, message: 'Hotspot control not available on this platform');
    }
  }

  @override
  Future<SettingsActionResult> openWifiSettings() async {
    print('DIAG: Platform.openWifiSettings() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('openWifiSettings');
      print('DIAG: Platform.openWifiSettings() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.openWifiSettings() result not Map');
        return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = SettingsActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.openWifiSettings() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.openWifiSettings() PlatformException: $e');
      return SettingsActionResult(status: SettingsActionStatus.failure, message: e.message ?? 'Failed to open Wi-Fi settings');
    } on MissingPluginException {
      print('DIAG: Platform.openWifiSettings() MissingPluginException');
      return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Settings not available on this platform');
    }
  }

  @override
  Future<SettingsActionResult> openMobileDataSettings() async {
    print('DIAG: Platform.openMobileDataSettings() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('openMobileDataSettings');
      print('DIAG: Platform.openMobileDataSettings() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.openMobileDataSettings() result not Map');
        return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = SettingsActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.openMobileDataSettings() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.openMobileDataSettings() PlatformException: $e');
      return SettingsActionResult(status: SettingsActionStatus.failure, message: e.message ?? 'Failed to open mobile data settings');
    } on MissingPluginException {
      print('DIAG: Platform.openMobileDataSettings() MissingPluginException');
      return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Settings not available on this platform');
    }
  }

  @override
  Future<SettingsActionResult> openHotspotSettings() async {
    print('DIAG: Platform.openHotspotSettings() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('openHotspotSettings');
      print('DIAG: Platform.openHotspotSettings() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.openHotspotSettings() result not Map');
        return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = SettingsActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.openHotspotSettings() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.openHotspotSettings() PlatformException: $e');
      return SettingsActionResult(status: SettingsActionStatus.failure, message: e.message ?? 'Failed to open hotspot settings');
    } on MissingPluginException {
      print('DIAG: Platform.openHotspotSettings() MissingPluginException');
      return const SettingsActionResult(status: SettingsActionStatus.failure, message: 'Settings not available on this platform');
    }
  }

  // Flashlight methods implementation
  @override
  Future<FlashlightAvailabilityResult> getFlashlightAvailability() async {
    print('DIAG: Platform.getFlashlightAvailability() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('getFlashlightAvailability');
      print('DIAG: Platform.getFlashlightAvailability() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.getFlashlightAvailability() result not Map');
        return const FlashlightAvailabilityResult(status: FlashlightStatus.unavailable, message: 'Invalid response from Android');
      }
      final availabilityResult = FlashlightAvailabilityResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.getFlashlightAvailability() returning: $availabilityResult');
      return availabilityResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.getFlashlightAvailability() PlatformException: $e');
      return FlashlightAvailabilityResult(status: FlashlightStatus.unavailable, message: e.message ?? 'Failed to get flashlight availability');
    } on MissingPluginException {
      print('DIAG: Platform.getFlashlightAvailability() MissingPluginException');
      return const FlashlightAvailabilityResult(status: FlashlightStatus.unavailable, message: 'Flashlight not available on this platform');
    }
  }

  @override
  Future<FlashlightActionResult> setFlashlightEnabled(bool enabled) async {
    print('DIAG: Platform.setFlashlightEnabled() entered with enabled: $enabled');
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
          enabled ? 'enableFlashlight' : 'disableFlashlight', {});
      print('DIAG: Platform.setFlashlightEnabled() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.setFlashlightEnabled() result not Map');
        return const FlashlightActionResult(status: FlashlightActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = FlashlightActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.setFlashlightEnabled() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.setFlashlightEnabled() PlatformException: $e');
      return FlashlightActionResult(status: FlashlightActionStatus.failure, message: e.message ?? 'Failed to ${enabled ? 'enable' : 'disable'} flashlight');
    } on MissingPluginException {
      print('DIAG: Platform.setFlashlightEnabled() MissingPluginException');
      return const FlashlightActionResult(status: FlashlightActionStatus.unsupported, message: 'Flashlight not available on this platform');
    }
  }

  // Screenshot methods implementation
  @override
  Future<ScreenshotActionResult> takeScreenshot() async {
    print('DIAG: Platform.takeScreenshot() entered');
    try {
      final result = await _methodChannel.invokeMethod<Object?>('takeScreenshot');
      print('DIAG: Platform.takeScreenshot() got result: $result');
      if (result is! Map) {
        print('DIAG: Platform.takeScreenshot() result not Map');
        return const ScreenshotActionResult(status: ScreenshotActionStatus.failure, message: 'Invalid response from Android');
      }
      final actionResult = ScreenshotActionResult.fromMap(result.cast<String, dynamic>());
      print('DIAG: Platform.takeScreenshot() returning: $actionResult');
      return actionResult;
    } on PlatformException catch (e) {
      print('DIAG: Platform.takeScreenshot() PlatformException: $e');
      return ScreenshotActionResult(status: ScreenshotActionStatus.failure, message: e.message ?? 'Failed to take screenshot');
    } on MissingPluginException {
      print('DIAG: Platform.takeScreenshot() MissingPluginException');
      return const ScreenshotActionResult(status: ScreenshotActionStatus.unsupported, message: 'Screenshot not available on this platform');
    }
  }

  @override
  Future<void> startWakeWordDetection() async {
    print('DIAG: Platform.startWakeWordDetection() entered');
    try {
      await _methodChannel.invokeMethod<void>('startWakeWordDetection');
      print('DIAG: Platform.startWakeWordDetection() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.startWakeWordDetection() PlatformException: $e');
    } on MissingPluginException {
      print('DIAG: Platform.startWakeWordDetection() MissingPluginException');
    }
  }

  @override
  Future<void> stopWakeWordDetection() async {
    print('DIAG: Platform.stopWakeWordDetection() entered');
    try {
      await _methodChannel.invokeMethod<void>('stopWakeWordDetection');
      print('DIAG: Platform.stopWakeWordDetection() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.stopWakeWordDetection() PlatformException: $e');
    } on MissingPluginException {
      print('DIAG: Platform.stopWakeWordDetection() MissingPluginException');
    }
  }

  // WhatsApp methods implementation
  @override
  Future<bool> isWhatsAppAvailable() async {
    print('DIAG: Platform.isWhatsAppAvailable() entered');
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWhatsAppAvailable');
      print('DIAG: Platform.isWhatsAppAvailable() got result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      print('DIAG: Platform.isWhatsAppAvailable() PlatformException: $e');
      return false;
    } on MissingPluginException {
      print('DIAG: Platform.isWhatsAppAvailable() MissingPluginException');
      return false;
    }
  }

  @override
  Future<Object> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    print('DIAG: Platform.sendWhatsAppMessage() entered with phoneNumber: $phoneNumber, message length: ${message.length}');
    try {
      final result = await _methodChannel.invokeMethod<Object>(
        'sendWhatsAppMessage',
        {
          'phoneNumber': phoneNumber,
          'message': message,
        },
      );
      print('DIAG: Platform.sendWhatsAppMessage() got result: $result');
      return result ?? '';
    } on PlatformException catch (e) {
      print('DIAG: Platform.sendWhatsAppMessage() PlatformException: $e');
      throw PlatformException(
        code: 'whatsapp_message_failed',
        message: e.message ?? 'Failed to send WhatsApp message',
      );
    } on MissingPluginException {
      print('DIAG: Platform.sendWhatsAppMessage() MissingPluginException');
      throw PlatformException(
        code: 'whatsapp_not_available',
        message: 'WhatsApp not available on this platform',
      );
    }
  }

  @override
  Future<Object> makeWhatsAppCall({
    required String phoneNumber,
    required bool isVideo,
  }) async {
    print('DIAG: Platform.makeWhatsAppCall() entered with phoneNumber: $phoneNumber, isVideo: $isVideo');
    try {
      final result = await _methodChannel.invokeMethod<Object>(
        'makeWhatsAppCall',
        {
          'phoneNumber': phoneNumber,
          'isVideo': isVideo,
        },
      );
      print('DIAG: Platform.makeWhatsAppCall() got result: $result');
      return result ?? '';
    } on PlatformException catch (e) {
      print('DIAG: Platform.makeWhatsAppCall() PlatformException: $e');
      throw PlatformException(
        code: 'whatsapp_call_failed',
        message: e.message ?? 'Failed to make WhatsApp call',
      );
    } on MissingPluginException {
      print('DIAG: Platform.makeWhatsAppCall() MissingPluginException');
      throw PlatformException(
        code: 'whatsapp_not_available',
        message: 'WhatsApp not available on this platform',
      );
    }
  }

  // Spotify methods
  @override
  Future<bool> isSpotifyInstalled() async {
    print('DIAG: Platform.isSpotifyInstalled() entered');
    try {
      final result = await _methodChannel.invokeMethod<bool>('isSpotifyInstalled');
      print('DIAG: Platform.isSpotifyInstalled() got result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      print('DIAG: Platform.isSpotifyInstalled() PlatformException: $e');
      return false;
    } on MissingPluginException {
      print('DIAG: Platform.isSpotifyInstalled() MissingPluginException');
      return false;
    }
  }

  @override
  Future<void> openSpotify() async {
    print('DIAG: Platform.openSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('openSpotify');
      print('DIAG: Platform.openSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.openSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_open_failed',
        message: e.message ?? 'Failed to open Spotify',
      );
    } on MissingPluginException {
      print('DIAG: Platform.openSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> playSpotify() async {
    print('DIAG: Platform.playSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('playSpotify');
      print('DIAG: Platform.playSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.playSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_play_failed',
        message: e.message ?? 'Failed to play Spotify',
      );
    } on MissingPluginException {
      print('DIAG: Platform.playSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> pauseSpotify() async {
    print('DIAG: Platform.pauseSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('pauseSpotify');
      print('DIAG: Platform.pauseSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.pauseSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_pause_failed',
        message: e.message ?? 'Failed to pause Spotify',
      );
    } on MissingPluginException {
      print('DIAG: Platform.pauseSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> resumeSpotify() async {
    print('DIAG: Platform.resumeSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('resumeSpotify');
      print('DIAG: Platform.resumeSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.resumeSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_resume_failed',
        message: e.message ?? 'Failed to resume Spotify',
      );
    } on MissingPluginException {
      print('DIAG: Platform.resumeSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> nextSpotify() async {
    print('DIAG: Platform.nextSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('nextSpotify');
      print('DIAG: Platform.nextSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.nextSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_next_failed',
        message: e.message ?? 'Failed to skip to next track',
      );
    } on MissingPluginException {
      print('DIAG: Platform.nextSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> previousSpotify() async {
    print('DIAG: Platform.previousSpotify() entered');
    try {
      await _methodChannel.invokeMethod<void>('previousSpotify');
      print('DIAG: Platform.previousSpotify() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.previousSpotify() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_previous_failed',
        message: e.message ?? 'Failed to skip to previous track',
      );
    } on MissingPluginException {
      print('DIAG: Platform.previousSpotify() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> searchAndPlayTrack(String query) async {
    print('DIAG: Platform.searchAndPlayTrack() entered with query: $query');
    try {
      await _methodChannel.invokeMethod<void>(
        'searchAndPlayTrack',
        {'query': query},
      );
      print('DIAG: Platform.searchAndPlayTrack() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.searchAndPlayTrack() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_search_and_play_track_failed',
        message: e.message ?? 'Failed to search and play track',
      );
    } on MissingPluginException {
      print('DIAG: Platform.searchAndPlayTrack() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> searchAndPlayArtist(String query) async {
    print('DIAG: Platform.searchAndPlayArtist() entered with query: $query');
    try {
      await _methodChannel.invokeMethod<void>(
        'searchAndPlayArtist',
        {'query': query},
      );
      print('DIAG: Platform.searchAndPlayArtist() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.searchAndPlayArtist() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_search_and_play_artist_failed',
        message: e.message ?? 'Failed to search and play artist',
      );
    } on MissingPluginException {
      print('DIAG: Platform.searchAndPlayArtist() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }

  @override
  Future<void> searchAndPlayPlaylist(String query) async {
    print('DIAG: Platform.searchAndPlayPlaylist() entered with query: $query');
    try {
      await _methodChannel.invokeMethod<void>(
        'searchAndPlayPlaylist',
        {'query': query},
      );
      print('DIAG: Platform.searchAndPlayPlaylist() completed');
    } on PlatformException catch (e) {
      print('DIAG: Platform.searchAndPlayPlaylist() PlatformException: $e');
      throw PlatformException(
        code: 'spotify_search_and_play_playlist_failed',
        message: e.message ?? 'Failed to search and play playlist',
      );
    } on MissingPluginException {
      print('DIAG: Platform.searchAndPlayPlaylist() MissingPluginException');
      throw PlatformException(
        code: 'spotify_not_available',
        message: 'Spotify not available on this platform',
      );
    }
  }
}
