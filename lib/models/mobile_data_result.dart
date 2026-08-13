enum MobileDataStatus { enabled, disabled, unavailable, permissionRequired, restricted }

class MobileDataStatusResult {
  final MobileDataStatus status;
  final String? message;

  const MobileDataStatusResult({
    required this.status,
    this.message,
  });

  factory MobileDataStatusResult.fromMap(Map<String, dynamic> map) {
    return MobileDataStatusResult(
      status: MobileDataStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}

enum MobileDataActionStatus { success, failure, permissionRequired, userActionRequired, unsupported }

class MobileDataActionResult {
  final MobileDataActionStatus status;
  final String? message;

  const MobileDataActionResult({
    required this.status,
    this.message,
  });

  factory MobileDataActionResult.fromMap(Map<String, dynamic> map) {
    return MobileDataActionResult(
      status: MobileDataActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}