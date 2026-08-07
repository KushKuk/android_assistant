enum CallingMode { safe, direct }

class AssistantSettings {
  const AssistantSettings({
    required this.assistantName,
    required this.wakeWord,
    required this.callingMode,
    required this.voice,
    required this.speechRate,
    required this.speechPitch,
    required this.language,
    required this.wakeWordEnabled,
    required this.voiceFeedbackEnabled,
  });

  static const defaultAssistantName = 'Chinaar';

  factory AssistantSettings.defaults() => const AssistantSettings(
    assistantName: defaultAssistantName,
    wakeWord: 'Hey Chinaar',
    callingMode: CallingMode.safe,
    voice: 'Default',
    speechRate: 1,
    speechPitch: 1,
    language: 'English',
    wakeWordEnabled: true,
    voiceFeedbackEnabled: true,
  );

  final String assistantName;
  final String wakeWord;
  final CallingMode callingMode;
  final String voice;
  final double speechRate;
  final double speechPitch;
  final String language;
  final bool wakeWordEnabled;
  final bool voiceFeedbackEnabled;

  AssistantSettings copyWith({
    String? assistantName,
    String? wakeWord,
    CallingMode? callingMode,
    String? voice,
    double? speechRate,
    double? speechPitch,
    String? language,
    bool? wakeWordEnabled,
    bool? voiceFeedbackEnabled,
  }) {
    return AssistantSettings(
      assistantName: assistantName ?? this.assistantName,
      wakeWord: wakeWord ?? this.wakeWord,
      callingMode: callingMode ?? this.callingMode,
      voice: voice ?? this.voice,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      language: language ?? this.language,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      voiceFeedbackEnabled: voiceFeedbackEnabled ?? this.voiceFeedbackEnabled,
    );
  }
}
