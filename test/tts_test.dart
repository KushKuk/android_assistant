import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/models/tts_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsSpeakResult', () {
    test('parses a successful speak response', () {
      final result = TtsSpeakResult.fromMap({
        'success': true,
        'utteranceId': 'abc-123',
      });

      expect(result.success, isTrue);
      expect(result.utteranceId, 'abc-123');
      expect(result.message, isNull);
    });

    test('parses an error response with message', () {
      final result = TtsSpeakResult.fromMap({
        'success': false,
        'message': 'TTS engine is not available.',
      });

      expect(result.success, isFalse);
      expect(result.utteranceId, isNull);
      expect(result.message, 'TTS engine is not available.');
    });

    test('treats missing success field as failure', () {
      final result = TtsSpeakResult.fromMap({
        'message': 'Something went wrong.',
      });

      expect(result.success, isFalse);
    });
  });

  group('TtsState', () {
    test('parses all known status names', () {
      expect(TtsState.fromName('unavailable'), TtsState.unavailable);
      expect(TtsState.fromName('idle'), TtsState.idle);
      expect(TtsState.fromName('speaking'), TtsState.speaking);
      expect(TtsState.fromName('error'), TtsState.error);
    });

    test('defaults to unavailable for unrecognized names', () {
      expect(TtsState.fromName('unknown'), TtsState.unavailable);
      expect(TtsState.fromName(''), TtsState.unavailable);
    });
  });

  group('empty text rejection', () {
    test('speak rejects empty text without calling the platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        (call) async {
          fail('Platform should not be called for empty text');
        },
      );

      final platform = MethodChannelAssistantPlatform();

      final empty = await platform.speak('');
      expect(empty.success, isFalse);
      expect(empty.message, contains('empty'));

      final whitespace = await platform.speak('   ');
      expect(whitespace.success, isFalse);
      expect(whitespace.message, contains('empty'));

      // Clean up.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        null,
      );
    });

    test('speak forwards non-empty text to the platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        (call) async {
          expect(call.method, 'speak');
          expect(call.arguments, {'text': 'Hello'});
          return {'success': true, 'utteranceId': 'mock-id'};
        },
      );

      final platform = MethodChannelAssistantPlatform();
      final result = await platform.speak('Hello');

      expect(result.success, isTrue);
      expect(result.utteranceId, 'mock-id');

      // Clean up.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        null,
      );
    });
  });
}
