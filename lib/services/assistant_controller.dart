import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';
import 'package:voice_assistant/commands/command_parse_result.dart';
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
  AssistantState _state = AssistantState.idle;
  AssistantIntegrationStatus _integrationStatus =
      const AssistantIntegrationStatus.unavailable();
  StreamSubscription<Map<Object?, Object?>>? _eventSubscription;

  String? _partialTranscript;
  String? _finalTranscript;
  String? _errorMessage;

  final CommandParser _commandParser = CommandParser();
  CommandParseResult? _lastCommandParseResult;

  AssistantSettings get settings => _settings;
  AssistantState get state => _state;
  AssistantIntegrationStatus get integrationStatus => _integrationStatus;

  CommandParseResult? get lastCommandParseResult => _lastCommandParseResult;
  bool get hasPendingCommand => _lastCommandParseResult?.isParsed ?? false;
  AssistantCommand? get pendingCommand => _lastCommandParseResult?.command;

  String get response {
    if (_state == AssistantState.error && _errorMessage != null) {
      return _errorMessage!;
    }
    if (_state == AssistantState.listening) {
      return _partialTranscript ?? 'Listening...';
    }
    if (_state == AssistantState.processing || _finalTranscript != null) {
      return _finalTranscript ?? 'Processing...';
    }
    return 'I\'m ready when you are.';
  }

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

  Future<void> startListening() async {
    final hasPermission = await _platform.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _platform.requestMicrophonePermission();
      if (!granted) {
        _setState(AssistantState.error);
        _errorMessage = 'Microphone permission denied.';
        return;
      }
    }

    _partialTranscript = null;
    _finalTranscript = null;
    _errorMessage = null;
    await _platform.startListening();
  }

  Future<void> stopListening() async {
    await _platform.stopListening();
  }

  Future<void> cancelListening() async {
    await _platform.cancelListening();
  }

  Future<void> speak(String text) async {
    _errorMessage = null;
    await _platform.speak(text);
  }

  void _handleNativeEvent(Map<Object?, Object?> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'bridge_ready':
        notifyListeners();
        break;

      // STT Events
      case 'listening_started':
        _setState(AssistantState.listening);
        break;
      case 'partial_transcript':
        _partialTranscript = event['text'] as String?;
        notifyListeners();
        break;
      case 'final_transcript':
        _finalTranscript = event['text'] as String?;
        // Parse the final transcript using CommandParser
        final transcript = event['text'] as String?;
        if (transcript != null) {
          _lastCommandParseResult = _commandParser.parse(transcript);
        }
        _setState(AssistantState.processing);
        break;
      case 'listening_stopped':
        // When listening stops, we transition to processing to handle the final results
        // If we were actively listening, move to processing state
        if (_state == AssistantState.listening) {
          _setState(AssistantState.processing);
        }
        // If we're already processing (e.g., from a prior stopListening call) and have
        // a final transcript to process, remain in processing state
        else if (_state == AssistantState.processing && _finalTranscript != null) {
          // Stay in processing state to handle the final transcript
        }
        // For any other state (idle, unavailable, permission required, etc.) that's not an error,
        // return to idle state
        else if (_state != AssistantState.error) {
          _setState(AssistantState.idle);
        }
        // If we're in error state, remain in error state (no state change)
        break;

      // TTS Events
      case 'speaking_started':
        _setState(AssistantState.speaking);
        break;
      case 'speaking_completed':
      case 'speaking_stopped':
        if (_state == AssistantState.speaking) {
          _setState(AssistantState.idle);
        }
        break;

      // Errors
      case 'speech_error':
        _errorMessage = event['message'] as String? ?? 'An error occurred.';
        _setState(AssistantState.error);
        break;
    }
  }

  void _setState(AssistantState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
