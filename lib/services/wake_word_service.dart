import 'dart:async';

import 'package:flutter/foundation.dart';

/// WakeWordService handles wake-word detection.
/// This is a mock implementation for testing purposes.
/// In a real implementation, this would use an offline wake-word engine
/// like Porcupine to detect the wake word without sending audio to the cloud.
class WakeWordService {
  WakeWordService();

  bool _isListening = false;
  Timer? _timer;
  Function()? _onWakeWordDetected;

  /// Initializes the wake-word service.
  /// In a real implementation, this would load the wake-word model.
  /// For the mock, we do nothing.
  Future<void> initialize({
    String? accessKey, // Ignored in mock
    List<String>? wakeWordPaths, // Ignored in mock
    List<double>? sensitivities, // Ignored in mock
  }) async {
    // Mock initialization
    if (kDebugMode) {
      print('WakeWordService: Initialized (mock)');
    }
  }

  /// Starts listening for the wake word.
  /// [onWakeWordDetected] is called when the wake word is detected.
  /// In the mock, we simulate detection after a short delay.
  Future<void> startListening(Function() onWakeWordDetected) async {
    if (_isListening) return;
    _isListening = true;
    _onWakeWordDetected = onWakeWordDetected;

    // Simulate wake-word detection after 2 seconds for testing.
    // In a real implementation, this would be triggered by actual audio input.
    _timer = Timer(const Duration(seconds: 2), () {
      if (_isListening) {
        _isListening = false;
        _onWakeWordDetected?.call();
        _onWakeWordDetected = null;
      }
    });

    if (kDebugMode) {
      print('WakeWordService: Started listening for wake word (mock)');
    }
  }

  /// Stops the wake-word detection and releases resources.
  void stop() {
    _isListening = false;
    _timer?.cancel();
    _timer = null;
    _onWakeWordDetected = null;
    if (kDebugMode) {
      print('WakeWordService: Stopped listening (mock)');
    }
  }

  /// Releases any resources.
  Future<void> dispose() async {
    stop();
  }

  /// Returns whether the service is currently listening for the wake word.
  bool get isListening => _isListening;
}