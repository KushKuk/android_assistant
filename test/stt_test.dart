import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/models/stt_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SttResult', () {
    test('parses a successful response', () {
      final result = SttResult.fromMap({
        'success': true,
      });

      expect(result.success, isTrue);
      expect(result.message, isNull);
    });

    test('parses an error response with message', () {
      final result = SttResult.fromMap({
        'success': false,
        'message': 'Speech recognition is not available.',
      });

      expect(result.success, isFalse);
      expect(result.message, 'Speech recognition is not available.');
    });
  });

  group('SttState', () {
    test('parses all known status names', () {
      expect(SttState.fromName('idle'), SttState.idle);
      expect(SttState.fromName('listening'), SttState.listening);
      expect(SttState.fromName('processing'), SttState.processing);
      expect(SttState.fromName('error'), SttState.error);
      expect(SttState.fromName('unavailable'), SttState.unavailable);
      expect(SttState.fromName('permissionRequired'), SttState.permissionRequired);
    });

    test('defaults to unavailable for unrecognized names', () {
      expect(SttState.fromName('unknown'), SttState.unavailable);
      expect(SttState.fromName(''), SttState.unavailable);
    });
  });

  group('STT MethodChannel forwarding', () {
    test('startListening returns permission error when exception is thrown', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        (call) async {
          throw PlatformException(code: 'permission_required');
        },
      );

      final platform = MethodChannelAssistantPlatform();
      final result = await platform.startListening();

      expect(result.success, isFalse);
      expect(result.message, contains('Microphone permission'));

      // Clean up.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        null,
      );
    });

    test('stopListening forwards to the platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        (call) async {
          expect(call.method, 'stopListening');
          return {'success': true};
        },
      );

      final platform = MethodChannelAssistantPlatform();
      final result = await platform.stopListening();

      expect(result.success, isTrue);

      // Clean up.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        null,
      );
    });

    test('cancelListening forwards to the platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        (call) async {
          expect(call.method, 'cancelListening');
          return {'success': true};
        },
      );

      final platform = MethodChannelAssistantPlatform();
      final result = await platform.cancelListening();

      expect(result.success, isTrue);

      // Clean up.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.voice_assistant/assistant'),
        null,
      );
    });
  });
}
