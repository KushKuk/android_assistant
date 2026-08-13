enum WifiStatus { enabled, disabled, unavailable, permissionRequired }

class WifiStatusResult {
  final WifiStatus status;
  final String? message;

  const WifiStatusResult({
    required this.status,
    this.message,
  });

  factory WifiStatusResult.fromMap(Map<String, dynamic> map) {
    return WifiStatusResult(
      status: WifiStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}

enum WifiActionStatus { success, failure, permissionRequired, userActionRequired, unsupported }

class WifiActionResult {
  final WifiActionStatus status;
  final String? message;

  const WifiActionResult({
    required this.status,
    this.message,
  });

  factory WifiActionResult.fromMap(Map<String, dynamic> map) {
    return WifiActionResult(
      status: WifiActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}