import 'package:flutter/foundation.dart';

/// Represents the availability of the flashlight on the device.
enum FlashlightStatus { available, unavailable }

class FlashlightAvailabilityResult {
  const FlashlightAvailabilityResult({
    required this.status,
    this.message,
  });

  final FlashlightStatus status;
  final String? message;

  factory FlashlightAvailabilityResult.fromMap(Map<String, dynamic> map) {
    return FlashlightAvailabilityResult(
      status: FlashlightStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }
}

/// Represents the result of a flashlight action (enable/disable).
enum FlashlightActionStatus { success, failure, unavailable, unsupported }

class FlashlightActionResult {
  const FlashlightActionResult({
    required this.status,
    this.message,
  });

  final FlashlightActionStatus status;
  final String? message;

  factory FlashlightActionResult.fromMap(Map<String, dynamic> map) {
    return FlashlightActionResult(
      status: FlashlightActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }
}