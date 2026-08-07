class AssistantIntegrationStatus {
  const AssistantIntegrationStatus({
    required this.isAvailable,
    required this.platform,
    required this.androidApiLevel,
    required this.voiceInteractionServiceRegistered,
  });

  const AssistantIntegrationStatus.unavailable()
    : isAvailable = false,
      platform = 'Unavailable',
      androidApiLevel = null,
      voiceInteractionServiceRegistered = false;

  final bool isAvailable;
  final String platform;
  final int? androidApiLevel;
  final bool voiceInteractionServiceRegistered;

  String get label {
    if (!isAvailable) return 'Bridge unavailable';
    return 'Connected · Android ${androidApiLevel ?? 'unknown'}';
  }

  factory AssistantIntegrationStatus.fromMap(Map<Object?, Object?> map) {
    return AssistantIntegrationStatus(
      isAvailable: map['isAvailable'] == true,
      platform: map['platform'] as String? ?? 'Android',
      androidApiLevel: map['androidApiLevel'] as int?,
      voiceInteractionServiceRegistered:
          map['voiceInteractionServiceRegistered'] == true,
    );
  }
}
