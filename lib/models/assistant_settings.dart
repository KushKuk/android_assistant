class AssistantSettings {
  const AssistantSettings({
    required this.assistantName,
    required this.wakeWord,
    required this.voice,
    required this.speechRate,
    required this.speechPitch,
    required this.language,
    required this.wakeWordEnabled,
    required this.voiceFeedbackEnabled,
  });

  static const defaultAssistantName = 'JARVIS';

  factory AssistantSettings.defaults() => const AssistantSettings(
    assistantName: defaultAssistantName,
    wakeWord: 'Hey JARVIS',
    voice: 'Default',
    speechRate: 1,
    speechPitch: 1,
    language: 'English',
    wakeWordEnabled: true,
    voiceFeedbackEnabled: true,
  );

  final String assistantName;
  final String wakeWord;
  final String voice;
  final double speechRate;
  final double speechPitch;
  final String language;
  final bool wakeWordEnabled;
  final bool voiceFeedbackEnabled;

  AssistantSettings copyWith({
    String? assistantName,
    String? wakeWord,
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
      voice: voice ?? this.voice,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      language: language ?? this.language,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      voiceFeedbackEnabled: voiceFeedbackEnabled ?? this.voiceFeedbackEnabled,
    );
  }
}
