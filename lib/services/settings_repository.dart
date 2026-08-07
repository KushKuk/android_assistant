import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/models/assistant_settings.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _assistantName = 'assistant_name';
  static const _wakeWord = 'wake_word';
  static const _callingMode = 'calling_mode';
  static const _voice = 'voice';
  static const _speechRate = 'speech_rate';
  static const _speechPitch = 'speech_pitch';
  static const _language = 'language';
  static const _wakeWordEnabled = 'wake_word_enabled';
  static const _voiceFeedbackEnabled = 'voice_feedback_enabled';

  AssistantSettings load() {
    final defaults = AssistantSettings.defaults();
    return AssistantSettings(
      assistantName:
          _preferences.getString(_assistantName) ?? defaults.assistantName,
      wakeWord: _preferences.getString(_wakeWord) ?? defaults.wakeWord,
      callingMode: (_preferences.getString(_callingMode) ?? 'safe') == 'direct'
          ? CallingMode.direct
          : CallingMode.safe,
      voice: _preferences.getString(_voice) ?? defaults.voice,
      speechRate: _preferences.getDouble(_speechRate) ?? defaults.speechRate,
      speechPitch: _preferences.getDouble(_speechPitch) ?? defaults.speechPitch,
      language: _preferences.getString(_language) ?? defaults.language,
      wakeWordEnabled:
          _preferences.getBool(_wakeWordEnabled) ?? defaults.wakeWordEnabled,
      voiceFeedbackEnabled:
          _preferences.getBool(_voiceFeedbackEnabled) ??
          defaults.voiceFeedbackEnabled,
    );
  }

  Future<void> save(AssistantSettings settings) async {
    await Future.wait([
      _preferences.setString(_assistantName, settings.assistantName),
      _preferences.setString(_wakeWord, settings.wakeWord),
      _preferences.setString(_callingMode, settings.callingMode.name),
      _preferences.setString(_voice, settings.voice),
      _preferences.setDouble(_speechRate, settings.speechRate),
      _preferences.setDouble(_speechPitch, settings.speechPitch),
      _preferences.setString(_language, settings.language),
      _preferences.setBool(_wakeWordEnabled, settings.wakeWordEnabled),
      _preferences.setBool(
        _voiceFeedbackEnabled,
        settings.voiceFeedbackEnabled,
      ),
    ]);
  }
}
