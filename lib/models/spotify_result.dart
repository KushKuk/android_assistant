enum SpotifyActionStatus { success, failure, permissionRequired, userActionRequired, unsupported }

class SpotifyActionResult {
  final SpotifyActionStatus status;
  final String? message;

  const SpotifyActionResult({
    required this.status,
    this.message,
  });

  factory SpotifyActionResult.fromMap(Map<String, dynamic> map) {
    return SpotifyActionResult(
      status: SpotifyActionStatus.values.firstWhere(
        (e) => e.toString() == 'SpotifyActionStatus.${map['status']}',
        orElse: () => SpotifyActionStatus.failure,
      ),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString().split('.').last,
      'message': message,
    };
  }
}