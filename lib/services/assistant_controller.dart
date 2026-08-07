import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/assistant_state.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/services/settings_repository.dart';

class AssistantController extends ChangeNotifier {
  AssistantController(this._repository, this._settings, this._platform);

  final SettingsRepository _repository;
  final AssistantPlatform _platform;
  AssistantSettings _settings;
  final AssistantState _state = AssistantState.idle;
  AssistantIntegrationStatus _integrationStatus =
      const AssistantIntegrationStatus.unavailable();
  StreamSubscription<Map<Object?, Object?>>? _eventSubscription;

  AssistantSettings get settings => _settings;
  AssistantState get state => _state;
  AssistantIntegrationStatus get integrationStatus => _integrationStatus;
  String get response => 'I\'m ready when you are.';

  Future<void> initializeNativeBridge() async {
    _integrationStatus = await _platform.getIntegrationStatus();
    try {
      await _platform.syncSettings(_settings);
      _eventSubscription = _platform.events.listen(_handleNativeEvent);
    } on PlatformException {
      // Flutter settings remain available during non-Android development.
    } on MissingPluginException {
      // Flutter settings remain available during non-Android development.
    }
    notifyListeners();
  }

  Future<void> updateSettings(AssistantSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _repository.save(settings);
    try {
      await _platform.syncSettings(settings);
    } on PlatformException {
      // Flutter persistence is retained if the Android side is not available.
    } on MissingPluginException {
      // Flutter persistence is retained if the Android side is not available.
    }
  }

  void _handleNativeEvent(Map<Object?, Object?> event) {
    if (event['type'] == 'bridge_ready') {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
