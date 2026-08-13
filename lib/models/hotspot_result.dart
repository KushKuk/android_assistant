enum HotspotStatus { enabled, disabled, unavailable, permissionRequired, configureRequired }

class HotspotStatusResult {
  final HotspotStatus status;
  final String? message;

  const HotspotStatusResult({
    required this.status,
    this.message,
  });

  factory HotspotStatusResult.fromMap(Map<String, dynamic> map) {
    return HotspotStatusResult(
      status: HotspotStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}

enum HotspotActionStatus { success, failure, permissionRequired, userActionRequired, unsupported }

class HotspotActionResult {
  final HotspotActionStatus status;
  final String? message;

  const HotspotActionResult({
    required this.status,
    this.message,
  });

  factory HotspotActionResult.fromMap(Map<String, dynamic> map) {
    return HotspotActionResult(
      status: HotspotActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'message': message,
      };
}