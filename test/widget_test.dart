import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/models/assistant_settings.dart';

void main() {
  test('defaults use the Chinaar identity', () {
    final settings = AssistantSettings.defaults();

    expect(settings.assistantName, 'Chinaar');
    expect(settings.wakeWord, 'Hey Chinaar');
    expect(settings.callingMode, CallingMode.safe);
  });

  test('settings can change the assistant name independently', () {
    final changed = AssistantSettings.defaults().copyWith(
      assistantName: 'Atlas',
    );

    expect(changed.assistantName, 'Atlas');
    expect(changed.wakeWord, 'Hey Chinaar');
  });
}
