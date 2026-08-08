/// Represents the current state of the native TTS engine.
enum TtsState {
  unavailable,
  idle,
  speaking,
  error;

  /// Parses a status name from the native layer.
  /// Returns [TtsState.unavailable] for unrecognized values.
  static TtsState fromName(String name) {
    for (final state in TtsState.values) {
      if (state.name == name) return state;
    }
    return TtsState.unavailable;
  }
}

/// The result of a [speak] request to the native TTS engine.
class TtsSpeakResult {
  const TtsSpeakResult({required this.success, this.utteranceId, this.message});

  final bool success;
  final String? utteranceId;
  final String? message;

  factory TtsSpeakResult.fromMap(Map<Object?, Object?> map) {
    return TtsSpeakResult(
      success: map['success'] == true,
      utteranceId: map['utteranceId'] as String?,
      message: map['message'] as String?,
    );
  }
}
