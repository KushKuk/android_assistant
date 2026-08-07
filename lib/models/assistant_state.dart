enum AssistantState {
  idle,
  listeningForWakeWord,
  wakeWordDetected,
  listening,
  processing,
  confirming,
  executing,
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
    AssistantState.confirming => 'Awaiting confirmation',
    AssistantState.executing => 'Executing',
    AssistantState.speaking => 'Speaking',
    AssistantState.error => 'Needs attention',
  };
}
