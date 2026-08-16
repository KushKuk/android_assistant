import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';

void main() {
  const parser = CommandParser();

  group('WhatsApp Command Parsing Tests', () {
    test('WhatsApp is REQUIRED for WhatsApp commands - normal calls should NOT route to WhatsApp', () {
      // These should ALL route to CallCommand, NOT WhatsApp
      final normalCallCases = [
        'Call Mom',
        'Phone Dad',
        'Give Mom a call',
        'call 9876543210',
        'Video call Mom', // Should NOT become WhatsAppVideoCallCommand
        'Call Sara',
        'phone John',
        'Give Jane a call',
      ];

      for (final input in normalCallCases) {
        final result = parser.parse(input);
        expect(result.isParsed, isTrue, reason: 'Failed to parse: $input');
        expect(result.command, isA<CallCommand>(),
            reason: '$input should route to CallCommand, not WhatsApp');
      }
    });

    test('WhatsApp audio call commands require explicit WhatsApp mention', () {
      final whatsappAudioCases = [
        'WhatsApp call Mom',
        'whatsapp call Dad',
        'WHATSAPP CALL JANE',
        'Call Mom on WhatsApp',
        'call Dad on whatsapp',
        'CALL JANE ON WHATSAPP',
      ];

      for (final input in whatsappAudioCases) {
        final result = parser.parse(input);
        expect(result.isParsed, isTrue, reason: 'Failed to parse: $input');
        expect(result.command, isA<WhatsAppAudioCallCommand>(),
            reason: '$input should route to WhatsAppAudioCallCommand');
      }
    });

    test('WhatsApp video call commands require explicit WhatsApp mention', () {
      final whatsappVideoCases = [
        'WhatsApp video call Mom',
        'whatsapp video call Dad',
        'WHATSAPP VIDEO CALL JANE',
        'Video call Mom on WhatsApp',
        'video call Dad on whatsapp',
        'VIDEO CALL JANE ON WHATSAPP',
      ];

      for (final input in whatsappVideoCases) {
        final result = parser.parse(input);
        expect(result.isParsed, isTrue, reason: 'Failed to parse: $input');
        expect(result.command, isA<WhatsAppVideoCallCommand>(),
            reason: '$input should route to WhatsAppVideoCallCommand');
      }
    });

    test('WhatsApp message commands require explicit WhatsApp mention', () {
      final whatsappMessageCases = [
        'WhatsApp Mom saying Hello',
        'whatsapp Dad saying Hi',
        'WHATSAPP JANE saying TEST',
        'Send Mom a WhatsApp saying Hello',
        'send Dad a whatsapp saying Hi',
        'SEND JANE A WHATSAPP saying TEST',
      ];

      for (final input in whatsappMessageCases) {
        final result = parser.parse(input);
        expect(result.isParsed, isTrue, reason: 'Failed to parse: $input');
        expect(result.command, isA<WhatsAppMessageCommand>(),
            reason: '$input should route to WhatsAppMessageCommand');
      }
    });

    test('Case insensitive matching works for WhatsApp commands', () {
      final testCases = [
        'whatsapp call mom',
        'WhatsApp Call Mom',
        'WHATSAPP CALL MOM',
        'WhAtSaPp CaLl MoM',
        'call mom on whatsapp',
        'CALL MOM ON WHATSAPP',
        'Call Mom On Whatsapp',
        'whatsapp video call mom',
        'WhatsApp Video Call Mom',
        'WHATSAPP VIDEO CALL MOM',
        'video call mom on whatsapp',
        'VIDEO CALL MOM ON WHATSAPP',
        'Video Call Mom On Whatsapp',
        'whatsapp mom saying hello',
        'WhatsApp Mom Saying Hello',
        'WHATSAPP MOM SAYING HELLO',
        'send mom a whatsapp saying hello',
        'SEND MOM A WHATSAPP SAYING HELLO',
        'Send Mom A WhatsApp Saying Hello',
      ];

      for (final input in testCases) {
        final result = parser.parse(input);
        expect(result.isParsed, isTrue, reason: 'Failed to parse: $input');
        // Just verify it parses to some WhatsApp command - specific type tested above
        expect(result.command,
          anyOf([
            isA<WhatsAppAudioCallCommand>(),
            isA<WhatsAppVideoCallCommand>(),
            isA<WhatsAppMessageCommand>()
          ]),
          reason: '$input should route to a WhatsApp command');
      }
    });

    test('Empty contact queries are rejected for WhatsApp commands', () {
      final emptyContactCases = [
        'WhatsApp call', // No contact
        'whatsapp call ',
        'Call on WhatsApp', // No contact
        'call on whatsapp ',
        'WhatsApp video call', // No contact
        'whatsapp video call ',
        'Video call on WhatsApp', // No contact
        'video call on whatsapp ',
        'WhatsApp Mom saying', // No message (but has contact)
        'whatsapp Mom saying ',
        'Send Mom a whatsapp saying', // No message
        'send Mom a whatsapp saying ',
      ];

      for (final input in emptyContactCases) {
        final result = parser.parse(input);
        // These should either fail to parse or produce unsupported command
        // Note: Our implementation returns null for empty contacts in WhatsApp parsers
        expect(result.isParsed, isFalse, reason: 'Empty contact should be rejected: $input');
      }
    });

    test('Parser precedence works correctly', () {
      // Test that more specific patterns match first
      final result = parser.parse('WhatsApp video call Mom');
      expect(result.isParsed, isTrue);
      expect(result.command, isA<WhatsAppVideoCallCommand>(),
          reason: 'Should match video call pattern before audio call pattern');

      final result2 = parser.parse('WhatsApp call Mom');
      expect(result2.isParsed, isTrue);
      expect(result2.command, isA<WhatsAppAudioCallCommand>());

      final result3 = parser.parse('WhatsApp Mom saying Hello');
      expect(result3.isParsed, isTrue);
      expect(result3.command, isA<WhatsAppMessageCommand>());
    });
  });
}