import 'package:flutter/foundation.dart';

/// Represents the result of a screenshot action.
enum ScreenshotActionStatus { success, failure, unavailable, permissionRequired, userActionRequired, unsupported }

class ScreenshotActionResult {
  const ScreenshotActionResult({
    required this.status,
    this.message,
    this.filePath,
  });

  final ScreenshotActionStatus status;
  final String? message;
  final String? filePath; // Path to the saved screenshot image

  factory ScreenshotActionResult.fromMap(Map<String, dynamic> map) {
    return ScreenshotActionResult(
      status: ScreenshotActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
      filePath: map['filePath'] as String?,
    );
  }
}