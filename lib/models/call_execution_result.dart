enum CallExecutionStatus {
  confirmationRequired,
  numberSelectionRequired,
  permissionRequired,
  confirmationDeclined,
  calling,
  invalidTarget,
  contactNotFound,
  contactNumberMismatch,
  expiredConfirmation,
  callFailed,
}

class CallExecutionResult {
  const CallExecutionResult({
    required this.status,
    required this.message,
    this.confirmationToken,
    this.displayName,
    this.phoneNumber,
    this.availableNumbers = const [],
  });

  final CallExecutionStatus status;
  final String message;
  final String? confirmationToken;
  final String? displayName;
  final String? phoneNumber;
  final List<String> availableNumbers;

  bool get requiresConfirmation =>
      status == CallExecutionStatus.confirmationRequired;
  bool get isTerminalFailure => switch (status) {
    CallExecutionStatus.invalidTarget ||
    CallExecutionStatus.contactNotFound ||
    CallExecutionStatus.contactNumberMismatch ||
    CallExecutionStatus.expiredConfirmation ||
    CallExecutionStatus.callFailed => true,
    _ => false,
  };

  factory CallExecutionResult.fromMap(Map<Object?, Object?> map) {
    final statusName = map['status'] as String;
    final rawNumbers = map['availableNumbers'] as List<Object?>? ?? const [];
    return CallExecutionResult(
      status: CallExecutionStatus.values.byName(statusName),
      message: map['message'] as String,
      confirmationToken: map['confirmationToken'] as String?,
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      availableNumbers: rawNumbers.cast<String>(),
    );
  }
}
