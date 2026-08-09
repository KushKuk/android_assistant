import 'package:voice_assistant/models/call_execution_result.dart';

/// Generic execution result that represents the outcome of executing a capability.
class ExecutionResult {
  const ExecutionResult({
    required this.status,
    required this.message,
    this.data,
  });

  /// Successful execution with optional data.
  const ExecutionResult.success({this.data})
      : status = ExecutionStatus.success,
        message = 'Success';

  /// Execution failed due to missing permissions.
  const ExecutionResult.permissionRequired(String message)
      : status = ExecutionStatus.permissionRequired,
        message = message,
        data = null;

  /// Execution requires user action (e.g., confirmation, selection).
  const ExecutionResult.userActionRequired(String message, {this.data})
      : status = ExecutionStatus.userActionRequired,
        message = message;

  /// Execution failed due to invalid arguments.
  const ExecutionResult.invalidArguments(String message)
      : status = ExecutionStatus.invalidArguments,
        message = message,
        data = null;

  /// Execution failed because the capability is unavailable.
  const ExecutionResult.unavailable(String message)
      : status = ExecutionStatus.unavailable,
        message = message,
        data = null;

  /// Execution was cancelled.
  const ExecutionResult.cancelled({this.data})
      : status = ExecutionStatus.cancelled,
        message = 'Cancelled';

  /// Execution failed due to an internal error.
  const ExecutionResult.failure(String message, {this.data})
      : status = ExecutionStatus.failure,
        message = message;

  /// Indicates that the command is not supported by any capability.
  const ExecutionResult.unsupported(String message)
      : status = ExecutionStatus.unsupported,
        message = message,
        data = null;

  final ExecutionStatus status;
  final String message;
  final Object? data;

  /// Whether the result indicates a successful execution.
  bool get isSuccess => status == ExecutionStatus.success;

  /// Whether the result indicates that user action is required.
  bool get requiresUserAction =>
      status == ExecutionStatus.userActionRequired;

  /// Whether the result indicates a permission is required.
  bool get requiresPermission =>
      status == ExecutionStatus.permissionRequired;

  /// Whether the result indicates a terminal state (success or failure).
  bool get isTerminal =>
      status == ExecutionStatus.success ||
      status == ExecutionStatus.failure ||
      status == ExecutionStatus.cancelled;

  /// Converts this generic result to a call-specific result if applicable.
  CallExecutionResult toCallExecutionResult() {
    switch (status) {
      case ExecutionStatus.success:
        return CallExecutionResult(
          status: CallExecutionStatus.calling,
          message: message,
        );
      case ExecutionStatus.permissionRequired:
        return CallExecutionResult(
          status: CallExecutionStatus.permissionRequired,
          message: message,
        );
      case ExecutionStatus.userActionRequired:
        // Check if it's confirmation required or number selection required
        if (data is Map<String, dynamic>) {
          final dataMap = data as Map<String, dynamic>;
          final actionType = dataMap['actionType'] as String?;
          if (actionType == 'confirmationRequired') {
            return CallExecutionResult(
              status: CallExecutionStatus.confirmationRequired,
              message: message,
              confirmationToken: dataMap['confirmationToken'] as String?,
            );
          } else if (actionType == 'numberSelectionRequired') {
            return CallExecutionResult(
              status: CallExecutionStatus.numberSelectionRequired,
              message: message,
              availableNumbers: (dataMap['availableNumbers'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ?? const [],
            );
          }
        }
        // Fallback to call failed for unknown user action types
        return CallExecutionResult(
          status: CallExecutionStatus.callFailed,
          message: message,
        );
      case ExecutionStatus.failure:
        return CallExecutionResult(
          status: CallExecutionStatus.callFailed,
          message: message,
        );
      case ExecutionStatus.cancelled:
        return CallExecutionResult(
          status: CallExecutionStatus.expiredConfirmation,
          message: message,
        );
      case ExecutionStatus.unsupported:
        return CallExecutionResult(
          status: CallExecutionStatus.callFailed,
          message: message,
        );
      case ExecutionStatus.invalidArguments:
        return CallExecutionResult(
          status: CallExecutionStatus.invalidTarget,
          message: message,
        );
      case ExecutionStatus.unavailable:
        return CallExecutionResult(
          status: CallExecutionStatus.callFailed,
          message: message,
        );
    }
  }
}

/// Status of an execution result.
enum ExecutionStatus {
  success,
  failure,
  permissionRequired,
  userActionRequired,
  invalidArguments,
  unavailable,
  cancelled,
  unsupported,
}