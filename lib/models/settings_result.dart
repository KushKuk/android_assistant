enum SettingsActionStatus { success, failure }

class SettingsActionResult {
  final SettingsActionStatus status;
  final String? message;

  const SettingsActionResult({
    required this.status,
    this.message,
  });

  factory SettingsActionResult.fromMap(Map<String, dynamic> map) {
    return SettingsActionResult(
      status: SettingsActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}