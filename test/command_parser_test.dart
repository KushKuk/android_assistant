import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';

void main() {
  const parser = CommandParser();

  test('parses supported call phrases deterministically', () {
    final examples = <String, String>{
      'Call Mom': 'Mom',
      'Phone Dad': 'Dad',
      'Give Mom a call': 'Mom',
      'call 9876543210.': '9876543210',
    };

    for (final entry in examples.entries) {
      final result = parser.parse(entry.key);

      expect(result.isParsed, isTrue, reason: entry.key);
      expect((result.command! as CallCommand).contactQuery, entry.value);
    }
  });

  test('rejects calls without a target and unsupported commands', () {
    final missingTarget = parser.parse('Call');
    final unsupported = parser.parse('Set a timer for five minutes');

    expect(missingTarget.isParsed, isFalse);
    expect(missingTarget.message, 'A contact or phone number is required.');
    expect(unsupported.isParsed, isFalse);
    expect(unsupported.message, 'Command is not supported.');
  });

  test('parses supported connectivity phrases deterministically', () {
    final examples = <String, Object>{
      // Wi-Fi commands
      'Turn on Wi-Fi': {'type': ConnectivityType.wifi, 'action': ConnectivityAction.enable},
      'Turn off Wi-Fi': {'type': ConnectivityType.wifi, 'action': ConnectivityAction.disable},
      'Open Wi-Fi settings': {'type': ConnectivityType.wifi, 'action': ConnectivityAction.openSettings},
      'Wi-Fi status': {'type': ConnectivityType.wifi, 'action': ConnectivityAction.getStatus},

      // Mobile data commands
      'Turn on mobile data': {'type': ConnectivityType.mobileData, 'action': ConnectivityAction.enable},
      'Turn off mobile data': {'type': ConnectivityType.mobileData, 'action': ConnectivityAction.disable},
      'Open mobile data settings': {'type': ConnectivityType.mobileData, 'action': ConnectivityAction.openSettings},
      'Mobile data status': {'type': ConnectivityType.mobileData, 'action': ConnectivityAction.getStatus},

      // Hotspot commands
      'Turn on hotspot': {'type': ConnectivityType.hotspot, 'action': ConnectivityAction.enable},
      'Turn off hotspot': {'type': ConnectivityType.hotspot, 'action': ConnectivityAction.disable},
      'Open hotspot settings': {'type': ConnectivityType.hotspot, 'action': ConnectivityAction.openSettings},
      'Hotspot status': {'type': ConnectivityType.hotspot, 'action': ConnectivityAction.getStatus},
    };

    for (final entry in examples.entries) {
      final result = parser.parse(entry.key);
      expect(result.isParsed, isTrue, reason: entry.key);
      final command = result.command! as ConnectivityCommand;
      expect(command.type, (entry.value as Map<String, dynamic>)['type']);
      expect(command.action, (entry.value as Map<String, dynamic>)['action']);
    }
  });
}
