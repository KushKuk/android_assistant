import 'package:flutter/material.dart';
import 'package:voice_assistant/models/assistant_state.dart';
import 'package:voice_assistant/services/assistant_controller.dart';
import 'package:voice_assistant/screens/settings_screen.dart';
import 'package:voice_assistant/widgets/assistant_orb.dart';

class AssistantHomeScreen extends StatelessWidget {
  const AssistantHomeScreen({super.key, required this.controller});

  final AssistantController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(controller.settings.assistantName),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(controller: controller),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            children: [
              Text(
                'YOUR PERSONAL ASSISTANT',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Hello, I\'m ${controller.settings.assistantName}.',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (controller.state == AssistantState.listening) {
                      controller.stopListening();
                    } else {
                      controller.startListening();
                    }
                  },
                  child: AssistantOrb(
                    isActive: controller.state == AssistantState.listening ||
                        controller.settings.wakeWordEnabled,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(child: _StatusPill(label: controller.state.label)),
              const SizedBox(height: 36),
              _ResponseCard(response: controller.response),
              const SizedBox(height: 28),
              Text('RECENT ACTIVITY', style: theme.textTheme.labelMedium),
              const SizedBox(height: 12),
              const _EmptyHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 9),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    ),
  );
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response});
  final String response;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              response,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.history_rounded),
          SizedBox(width: 14),
          Expanded(child: Text('Command history will appear here.')),
        ],
      ),
    ),
  );
}
