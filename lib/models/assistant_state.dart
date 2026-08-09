enum AssistantState {
  idle,
  listeningForWakeWord,
  wakeWordDetected,
  listening,
  processing,
  resolvingContact,        // Resolving contact from voice command
  numberSelectionRequired, // User must select from multiple numbers
  awaitingConfirmation,    // Waiting for user to confirm the call
  calling,                 // Call is in progress (Android ACTION_CALL initiated)
  confirming,              // Awaiting confirmation (for other operations)
  executing,               // Executing (for other operations)
  speaking,
  error,
}

extension AssistantStateDisplay on AssistantState {
  String get label => switch (this) {
    AssistantState.idle => 'Ready',
    AssistantState.listeningForWakeWord => 'Listening for wake word',
    AssistantState.wakeWordDetected => 'Wake word detected',
    AssistantState.listening => 'Listening',
    AssistantState.processing => 'Processing',
    AssistantState.resolvingContact => 'Resolving contact',
    AssistantState.numberSelectionRequired => 'Select number',
    AssistantState.awaitingConfirmation => 'Awaiting confirmation',
    AssistantState.calling => 'Calling',
    AssistantState.confirming => 'Awaiting confirmation',
    AssistantState.executing => 'Executing',
    AssistantState.speaking => 'Speaking',
    AssistantState.error => 'Needs attention',
  };
}
