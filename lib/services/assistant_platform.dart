import 'package:flutter/services.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/contact_candidate.dart';

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

  @override
  Future<bool> hasContactsPermission() async {
    return await _methodChannel.invokeMethod<bool>('hasContactsPermission') ??
        false;
  }

  @override
  Future<bool> requestContactsPermission() async {
    final result = await _methodChannel.invokeMethod<Object?>(
      'requestContactsPermission',
    );
    return result is Map && result['granted'] == true;
  }

  @override
  Future<ContactSearchResult> resolveContacts(String query) async {
    final result = await _methodChannel.invokeMethod<Object?>(
      'resolveContacts',
      {'query': query},
    );
    if (result is! Map) {
      throw PlatformException(
        code: 'invalid_contact_response',
        message: 'Android returned an invalid contact search result.',
      );
    }
    return ContactSearchResult.fromMap(Map<Object?, Object?>.from(result));
  }

  @override
  Future<bool> hasCallPermission() async {
    return await _methodChannel.invokeMethod<bool>('hasCallPermission') ??
        false;
  }

  @override
  Future<bool> requestCallPermission() async {
    final result = await _methodChannel.invokeMethod<Object?>(
      'requestCallPermission',
    );
    return result is Map && result['granted'] == true;
  }

  @override
  Future<CallExecutionResult> prepareCall({
    String? contactId,
    String? phoneNumber,
    String? displayName,
  }) {
    return _invokeCallResult('prepareCall', {
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
    });
  }

  @override
  Future<CallExecutionResult> confirmCall({
    required String confirmationToken,
    required bool confirmed,
  }) {
    return _invokeCallResult('confirmCall', {
      'confirmationToken': confirmationToken,
      'confirmed': confirmed,
    });
  }

  Future<CallExecutionResult> _invokeCallResult(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final result = await _methodChannel.invokeMethod<Object?>(
      method,
      arguments,
    );
    if (result is! Map) {
      throw PlatformException(
        code: 'invalid_call_response',
        message: 'Android returned an invalid call result.',
      );
    }
    return CallExecutionResult.fromMap(Map<Object?, Object?>.from(result));
  }
}
