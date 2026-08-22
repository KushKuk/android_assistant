/*
 * Device settings result model.
 * Mirrors the SystemOperationResult from the Android side.
 */
class DeviceSettingsResult {
  final String status;
  final String operation;
  final String message;
  final bool silent;
  final bool requiresUserAction;
  final dynamic currentValue; // Can be int, double, String, etc. depending on the operation

  DeviceSettingsResult({
    required this.status,
    required this.operation,
    required this.message,
    this.silent = true,
    this.requiresUserAction = false,
    this.currentValue,
  });

  factory DeviceSettingsResult.fromMap(Map<String, dynamic> map) {
    return DeviceSettingsResult(
      status: map['status'] as String,
      operation: map['operation'] as String,
      message: map['message'] as String,
      silent: map['silent'] as bool? ?? true,
      requiresUserAction: map['requiresUserAction'] as bool? ?? false,
      currentValue: map['currentValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'operation': operation,
      'message': message,
      'silent': silent,
      'requiresUserAction': requiresUserAction,
      'currentValue': currentValue,
    };
  }
}