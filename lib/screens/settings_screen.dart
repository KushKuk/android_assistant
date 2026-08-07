import 'package:flutter/material.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/services/assistant_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AssistantController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _wakeWordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.settings.assistantName,
    );
    _wakeWordController = TextEditingController(
      text: widget.controller.settings.wakeWord,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  Future<void> _saveTextFields() async {
    final name = _nameController.text.trim();
    final wakeWord = _wakeWordController.text.trim();
    if (name.isEmpty || wakeWord.isEmpty) return;
    await widget.controller.updateSettings(
      widget.controller.settings.copyWith(
        assistantName: name,
        wakeWord: wakeWord,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _SectionTitle('GENERAL'),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Assistant name',
              helperText: 'Used in the app and assistant responses.',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            onSubmitted: (_) => _saveTextFields(),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Voice',
            value: settings.voice,
            icon: Icons.record_voice_over_outlined,
          ),
          _SettingsTile(
            title: 'Language',
            value: settings.language,
            icon: Icons.language_rounded,
          ),
          const _SectionTitle('VOICE'),
          TextField(
            controller: _wakeWordController,
            decoration: const InputDecoration(
              labelText: 'Wake word',
              helperText: 'Changing this does not change a wake-word model.',
              prefixIcon: Icon(Icons.graphic_eq_rounded),
            ),
            onSubmitted: (_) => _saveTextFields(),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable wake word'),
            subtitle: const Text(
              'Configuration only — detection is not yet integrated.',
            ),
            value: settings.wakeWordEnabled,
            onChanged: (value) => widget.controller.updateSettings(
              settings.copyWith(wakeWordEnabled: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice feedback'),
            value: settings.voiceFeedbackEnabled,
            onChanged: (value) => widget.controller.updateSettings(
              settings.copyWith(voiceFeedbackEnabled: value),
            ),
          ),
          const _SectionTitle('CALLING'),
          SegmentedButton<CallingMode>(
            segments: const [
              ButtonSegment(
                value: CallingMode.safe,
                label: Text('Safe'),
                icon: Icon(Icons.verified_user_outlined),
              ),
              ButtonSegment(
                value: CallingMode.direct,
                label: Text('Direct'),
                icon: Icon(Icons.phone_forwarded_outlined),
              ),
            ],
            selected: {settings.callingMode},
            onSelectionChanged: (selection) => widget.controller.updateSettings(
              settings.copyWith(callingMode: selection.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Safe mode always asks for confirmation before a call.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const _SectionTitle('CONTACTS'),
          _SettingsTile(
            title: 'Manage contact aliases',
            value: 'Coming next',
            icon: Icons.contacts_outlined,
          ),
          const _SectionTitle('PRIVACY'),
          _SettingsTile(
            title: 'Permissions',
            value: 'Not requested yet',
            icon: Icons.shield_outlined,
          ),
          const _SectionTitle('DATA'),
          _SettingsTile(
            title: 'Command history',
            value: 'No history yet',
            icon: Icons.history_rounded,
          ),
          const _SectionTitle('ABOUT'),
          _SettingsTile(
            title: 'Assistant version',
            value: '0.1.0 (Phase 1)',
            icon: Icons.info_outline_rounded,
          ),
          _SettingsTile(
            title: 'Android integration',
            value: widget.controller.integrationStatus.label,
            icon: Icons.android_rounded,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
