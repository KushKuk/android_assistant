sealed class AssistantCommand {
  const AssistantCommand();
}

class CallCommand extends AssistantCommand {
  const CallCommand({required this.contactQuery});

  final String contactQuery;
}
