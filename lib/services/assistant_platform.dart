import 'package:flutter/services.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_settings.dart';

abstract interface class AssistantPlatform {
  Future<AssistantIntegrationStatus> getIntegrationStatus();
  Future<void> syncSettings(AssistantSettings settings);
  Stream<Map<Object?, Object?>> get events;
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
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
        'getIntegrationStatus',
      );
      if (result is! Map) return const AssistantIntegrationStatus.unavailable();
      return AssistantIntegrationStatus.fromMap(
        Map<Object?, Object?>.from(result),
      );
    } on PlatformException {
      return const AssistantIntegrationStatus.unavailable();
    } on MissingPluginException {
      return const AssistantIntegrationStatus.unavailable();
    }
  }

  @override
  Future<void> syncSettings(AssistantSettings settings) {
    return _methodChannel.invokeMethod<void>('syncSettings', {
      'assistantName': settings.assistantName,
      'wakeWord': settings.wakeWord,
      'callingMode': settings.callingMode.name,
      'voice': settings.voice,
      'speechRate': settings.speechRate,
      'speechPitch': settings.speechPitch,
      'language': settings.language,
      'wakeWordEnabled': settings.wakeWordEnabled,
      'voiceFeedbackEnabled': settings.voiceFeedbackEnabled,
    });
  }
}
