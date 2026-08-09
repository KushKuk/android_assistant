import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/contact_candidate.dart';

void main() {
  test('defaults use the JARVIS identity', () {
    final settings = AssistantSettings.defaults();

    expect(settings.assistantName, 'JARVIS');
    expect(settings.wakeWord, 'Hey JARVIS');
    expect(settings.callingMode, CallingMode.safe);
  });

  test('settings can change the assistant name independently', () {
    final changed = AssistantSettings.defaults().copyWith(
      assistantName: 'Atlas',
    );

    expect(changed.assistantName, 'Atlas');
    expect(changed.wakeWord, 'Hey JARVIS');
  });

  test('contact search results preserve candidate phone numbers', () {
    final result = ContactSearchResult.fromMap({
      'query': 'Mom',
      'candidates': [
        {
          'contactId': '42',
          'displayName': 'Mom',
          'phoneNumbers': ['+91 9876543210'],
          'isExactNameMatch': true,
        },
      ],
    });

    expect(result.hasNoMatches, isFalse);
    expect(result.hasMultipleMatches, isFalse);
    expect(result.candidates.single.phoneNumbers.single, '+91 9876543210');
  });

  test(
    'call results expose the confirmation token without executing a call',
    () {
      final result = CallExecutionResult.fromMap({
        'status': 'confirmationRequired',
        'message': 'Confirm call to Mom.',
        'confirmationToken': 'pending-token',
        'displayName': 'Mom',
        'phoneNumber': '+919876543210',
        'availableNumbers': const <String>[],
      });

      expect(result.requiresConfirmation, isTrue);
      expect(result.confirmationToken, 'pending-token');
      expect(result.isTerminalFailure, isFalse);
    },
  );
}
