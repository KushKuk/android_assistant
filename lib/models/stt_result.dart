/// Represents the current state of the native STT engine.
enum SttState {
  idle,
  listening,
  processing,
  error,
  unavailable,
  permissionRequired;

  /// Parses a status name from the native layer.
  /// Returns [SttState.unavailable] for unrecognized values.
  static SttState fromName(String name) {
    for (final state in SttState.values) {
      if (state.name == name) return state;
    }
    return SttState.unavailable;
  }
}

/// The result of a start/stop request to the native STT engine.
class SttResult {
  const SttResult({required this.success, this.message});

  final bool success;
  final String? message;

  factory SttResult.fromMap(Map<Object?, Object?> map) {
    return SttResult(
      success: map['success'] == true,
      message: map['message'] as String?,
    );
  }
}
