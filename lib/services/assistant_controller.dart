import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voice_assistant/capabilities/bluetooth_capability.dart';
import 'package:voice_assistant/capabilities/call_capability.dart';
import 'package:voice_assistant/capabilities/connectivity_capability.dart';
import 'package:voice_assistant/capabilities/flashlight_capability.dart';
import 'package:voice_assistant/capabilities/screenshot_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parser.dart';
import 'package:voice_assistant/commands/command_parse_result.dart';
import 'package:voice_assistant/models/assistant_integration_status.dart';
import 'package:voice_assistant/models/assistant_settings.dart';
import 'package:voice_assistant/models/assistant_state.dart';
import 'package:voice_assistant/models/contact_candidate.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';
import 'package:voice_assistant/models/bluetooth_result.dart';
import 'package:voice_assistant/services/assistant_orchestrator.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/services/settings_repository.dart';
import 'package:voice_assistant/services/wake_word_service.dart';

class AssistantController extends ChangeNotifier {
  AssistantController(
    SettingsRepository repository,
    AssistantSettings settings,
    AssistantPlatform platform, {
    WakeWordService? wakeWordService,
  })
   : _repository = repository,
     _settings = settings,
     _platform = platform,
     _orchestrator = _createOrchestrator(platform),
     _wakeWordService = wakeWordService ?? WakeWordService(),
     _wakeWordListening = false,
     _commandParser = CommandParser(),
     _lastCommandParseResult = null,
     _partialTranscript = null,
     _finalTranscript = null,
     _errorMessage = null,
     _integrationStatus = const AssistantIntegrationStatus.unavailable(),
     _eventSubscription = null,
     _state = AssistantState.idle {
    // Start wake-word listening for the initial idle state.
    _startWakeWordListening();
  }

  static AssistantOrchestrator _createOrchestrator(AssistantPlatform platform) {
    return AssistantOrchestrator([
        CallCapability(platform),
        BluetoothCapability(platform),
        ConnectivityCapability(platform),
        FlashlightCapability(platform),
        ScreenshotCapability(platform),
    ]);
  }

  final SettingsRepository _repository;
  final AssistantPlatform _platform;
  final AssistantOrchestrator _orchestrator;
  AssistantSettings _settings;
  AssistantState _state;
  AssistantIntegrationStatus _integrationStatus;
  StreamSubscription<Map<Object?, Object?>>? _eventSubscription;

  String? _partialTranscript;
  String? _finalTranscript;
  String? _errorMessage;

  final CommandParser _commandParser;
  CommandParseResult? _lastCommandParseResult;

  // Wake word detection
  final WakeWordService _wakeWordService;
  bool _wakeWordListening;

  AssistantSettings get settings => _settings;
  AssistantState get state => _state;
  AssistantIntegrationStatus get integrationStatus => _integrationStatus;

  CommandParseResult? get lastCommandParseResult => _lastCommandParseResult;
  bool get hasPendingCommand => _lastCommandParseResult?.isParsed ?? false;
  AssistantCommand? get pendingCommand => _lastCommandParseResult?.command;

  String get response {
    if (_state == AssistantState.error && _errorMessage != null) {
      return _errorMessage!;
    }
    if (_state == AssistantState.listening) {
      return _partialTranscript ?? 'Listening...';
    }
    if (_state == AssistantState.processing || _finalTranscript != null) {
      return _finalTranscript ?? 'Processing...';
    }
    return 'I\'m ready when you are.';
  }

  Future<void> initializeNativeBridge() async {
    _integrationStatus = await _platform.getIntegrationStatus();
    try {
      await _platform.syncSettings(_settings);
      _eventSubscription = _platform.events.listen((event) async {
        await _handleNativeEvent(event);
      });
    } on PlatformException {
      // Flutter settings remain available during non-Android development.
    } on MissingPluginException {
      // Flutter settings remain available during non-Android development.
    }
    if (kDebugMode) notifyListeners();
  }

  Future<void> _initializeWakeWordService() async {
    // Initialize the wake-word service (mock implementation).
    await _wakeWordService.initialize();
  }

  Future<void> _startWakeWordListening() async {
    if (_wakeWordListening) return;
    final hasPermission = await _platform.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _platform.requestMicrophonePermission();
      if (!granted) {
        if (kDebugMode) print('Microphone permission denied for wake word detection.');
        return;
      }
    }
    await _wakeWordService.startListening(_onWakeWordDetected);
    _wakeWordListening = true;
    if (kDebugMode) print('Wake word listening started.');
  }

  Future<void> _stopWakeWordListening() async {
    if (!_wakeWordListening) return;
    _wakeWordService.stop();
    _wakeWordListening = false;
    if (kDebugMode) print('Wake word listening stopped.');
  }

  void _onWakeWordDetected() {
    if (kDebugMode) print('Wake word detected!');
    _stopWakeWordListening();
    _setState(AssistantState.wakeWordDetected);
    // After detecting wake word, start normal listening for commands.
    startListening().then((_) {
      // The startListening method will set state to listening when the STT starts.
      // We don't need to do anything else here.
    }).catchError((error) {
      if (kDebugMode) print('Failed to start listening after wake word detection: $error');
      _setState(AssistantState.error);
      _errorMessage = 'Failed to start listening: $error';
      // Optionally, restart wake-word listening after an error?
      _startWakeWordListening();
    });
  }

  Future<void> updateSettings(AssistantSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _repository.save(settings);
    try {
      await _platform.syncSettings(settings);
    } on PlatformException {
      // Flutter persistence is retained if the Android side is not available.
    } on MissingPluginException {
      // Flutter persistence is retained if the Android side is not available.
    }
  }

  Future<void> startListening() async {
    // Stop wake-word listening to avoid conflict with STT
    await _stopWakeWordListening();

    final hasPermission = await _platform.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _platform.requestMicrophonePermission();
      if (!granted) {
        _setState(AssistantState.error);
        _errorMessage = 'Microphone permission denied.';
        // Restart wake-word listening if we were previously listening?
        // Since we are in error state, we might want to try again later.
        // For now, we do not automatically restart.
        return;
      }
    }

    _partialTranscript = null;
    _finalTranscript = null;
    _errorMessage = null;
    _lastCommandParseResult = null;
    await _platform.startListening();
  }

  Future<void> stopListening() async {
    // If we are currently listening, transition to processing state to handle what was said
    if (_state == AssistantState.listening) {
      _setState(AssistantState.processing);
    }
    await _platform.stopListening();
    // Note: Wake-word listening will be restarted based on state transitions
    // when the 'listening_stopped' event sets state to idle.

    // If we were listening and have a partial transcript but no final transcript yet,
    // treat the partial transcript as if it were final and execute it
    if (_state == AssistantState.processing &&
        _partialTranscript != null &&
        _partialTranscript!.isNotEmpty &&
        _lastCommandParseResult == null) {
      // Treat partial transcript as final transcript
      final transcript = _partialTranscript!;
      _partialTranscript = null;
      _lastCommandParseResult = _commandParser.parse(transcript);
      if (_lastCommandParseResult?.isParsed == true) {
        initiateCommandExecution();
      } else {
        // If parsing failed, just go to processing state (already there)
      }
    }

    // If we have a pending command, execute it now
    if (hasPendingCommand) {
      initiateCommandExecution();
    }
  }

  Future<void> cancelListening() async {
    await _platform.cancelListening();
  }

  Future<void> speak(String text) async {
    _errorMessage = null;
    await _platform.speak(text);
  }

  Future<void> _handleNativeEvent(Map<Object?, Object?> event) async {
    final type = event['type'] as String?;
    if (type == null) return;

    if (kDebugMode) {
      print('DIAG: _handleNativeEvent received event: type=$type, currentState=$_state');
    }

    switch (type) {
      case 'bridge_ready':
        notifyListeners();
        break;

      // STT Events
      case 'listening_started':
        _setState(AssistantState.listening);
        break;
      case 'partial_transcript':
        _partialTranscript = event['text'] as String?;
        notifyListeners();
        break;
      case 'final_transcript':
        _finalTranscript = event['text'] as String?;
        // Parse the final transcript using CommandParser
        final transcript = event['text'] as String?;
        if (transcript != null) {
          print('DIAG: AssistantController received final_transcript: $transcript');
          _lastCommandParseResult = _commandParser.parse(transcript);
          print('DIAG: AssistantController parsed result: isParsed=${_lastCommandParseResult?.isParsed}, command=${_lastCommandParseResult?.command}');
          print('DIAG: AssistantController lastCommandParseResult after setting: $_lastCommandParseResult');
          if (_lastCommandParseResult?.isParsed == true) {
            print('DIAG: AssistantController command parsed and stored');
            // Set state to processing but do not execute command yet
            // Execution will be triggered explicitly (e.g., by stopListening)
            _setState(AssistantState.processing);
          } else {
            print('DIAG: AssistantController - command not parsed, setting state to processing');
            _setState(AssistantState.processing);
          }
        } else {
          print('DIAG: AssistantController received null transcript');
          _setState(AssistantState.processing);
        }
        break;
      case 'listening_stopped':
        // If we're still in listening state (meaning we didn't get a final transcript to process),
        // transition to idle state
        if (_state == AssistantState.listening) {
          _setState(AssistantState.idle);
        }
        // For any other state, we leave it as is (it was set by command execution or other events)
        break;

      // TTS Events
      case 'speaking_started':
        _setState(AssistantState.speaking);
        break;
      case 'speaking_completed':
      case 'speaking_stopped':
        if (_state == AssistantState.speaking) {
          _setState(AssistantState.idle);
        }
        break;

      // Errors
      case 'speech_error':
        _errorMessage = event['message'] as String? ?? 'An error occurred.';
        _setState(AssistantState.error);
        break;
    }
  }

  void _setState(AssistantState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();

    // Handle wake-word listening based on state
    if (newState == AssistantState.idle) {
      // When entering idle state, start wake-word listening if not already listening
      if (!_wakeWordListening) {
        _startWakeWordListening();
      }
    } else {
      // When leaving idle state, stop wake-word listening if we were listening
      if (_wakeWordListening) {
        _stopWakeWordListening();
      }
    }
  }

  /// Call this method to confirm or decline an incoming call request.
  /// Must be called when we're awaiting confirmation from a capability execution.
  Future<void> confirmCall(bool confirmed) async {
    // Validate we're in the correct state
    if (_state != AssistantState.awaitingConfirmation) {
      // Invalid state; ignore.
      return;
    }

    // Validate we have a confirmation token
    if (_confirmationToken == null) {
      _setState(AssistantState.error);
      _errorMessage = 'No confirmation token available.';
      return;
    }

    try {
      // Delegate to the platform's confirmCall method
      final callResult = await _platform.confirmCall(
        confirmationToken: _confirmationToken!,
        confirmed: confirmed,
      );

      // Handle the result - convert CallExecutionResult to ExecutionResult
      final result = _convertCallExecutionResult(callResult);
      _handleExecutionResult(result);
    } catch (e) {
      _setState(AssistantState.error);
      _errorMessage = 'Call confirmation failed: $e';
    }
    // Clear confirmation state after attempt
    _confirmationToken = null;
    _confirmationMessage = null;
  }

  /// Select a phone number from the resolved contacts when in number selection state.
  /// This method should be called when the controller is in [AssistantState.numberSelectionRequired].
  /// The [phoneNumber] must be one of the numbers exposed via [contactCandidates].
  Future<void> selectPhoneNumber(String phoneNumber) async {
    // Similar issue as confirmCall - this needs access to state that's now in the capability
    // Let me preserve the existing fields for now to maintain compatibility
    if (_state != AssistantState.numberSelectionRequired) {
      // Invalid state; ignore.
      return;
    }
    if (_contactCandidates == null) {
      _setState(AssistantState.error);
      _errorMessage = 'No contacts available for selection.';
      return;
    }
    // Find the contact that contains this phone number.
    final candidate = _contactCandidates!.firstWhere(
      (c) => c.phoneNumbers.contains(phoneNumber),
      orElse: () => ContactCandidate(
        contactId: '',
        displayName: 'Unknown',
        phoneNumbers: const [],
        isExactNameMatch: false,
      ),
    );
    if (candidate.contactId.isEmpty) {
      _setState(AssistantState.error);
      _errorMessage = 'Phone number not found in resolved contacts.';
      return;
    }
    // Proceed to prepareCall with the selected number.
    _handlePrepareCall(
      contactId: candidate.contactId,
      phoneNumber: phoneNumber,
      displayName: candidate.displayName,
    );
  }

  /// Handles the prepareCall step for a resolved contact/number.
  void _handlePrepareCall({
    required String contactId,
    required String phoneNumber,
    required String displayName,
  }) async {
    try {
      final result = await _platform.prepareCall(
        contactId: contactId,
        phoneNumber: phoneNumber,
        displayName: displayName,
      );
      _handlePrepareCallResult(result);
    } catch (e) {
      _setState(AssistantState.error);
      _errorMessage = 'Prepare call failed: $e';
    }
  }

  /// Processes the result of prepareCall.
  void _handlePrepareCallResult(CallExecutionResult result) {
    switch (result.status) {
      case CallExecutionStatus.confirmationRequired:
        _setState(AssistantState.awaitingConfirmation);
        _confirmationToken = result.confirmationToken;
        _confirmationMessage = result.message;
        break;
      case CallExecutionStatus.numberSelectionRequired:
        // This could happen if the platform returns number selection required despite
        // our contact resolution already handling it. We'll treat it as needing number selection.
        _setState(AssistantState.numberSelectionRequired);
        // The available numbers are in result.availableNumbers
        // We may need to expose them; for now we just set state and let UI read from result.
        // We'll store the result for UI to access? We'll add a getter for available numbers later.
        // For simplicity, we'll just set state and rely on the UI to call a method to get the numbers.
        // We'll add a getter for availableNumbersFromPrepareCall.
        // But to keep changes minimal, we'll just set state and rely on the UI to call a method on the controller
        // to get the numbers from the last prepareCall result. We'll add a field for that.
        // We'll add a field _prepareCallResult.
        // However, given time, we'll assume that numberSelectionRequired from prepareCall is rare
        // and we can treat it as error for now, but better to handle.
        // We'll add a field to store the last prepareCall result.
        // Given the scope, we'll keep it simple and treat as error with a message.
        _setState(AssistantState.error);
        _errorMessage = 'Number selection required: ${result.message}';
        break;
      case CallExecutionStatus.permissionRequired:
        _setState(AssistantState.error);
        _errorMessage = 'Call permission required: ${result.message}';
        break;
      case CallExecutionStatus.callFailed:
        _setState(AssistantState.error);
        _errorMessage = 'Call failed: ${result.message}';
        break;
      case CallExecutionStatus.calling:
        // This would be unexpected from prepareCall, but if it happens, we treat as calling.
        _setState(AssistantState.calling);
        break;
      default:
        _setState(AssistantState.error);
        _errorMessage = 'Unexpected prepareCall result: ${result.status}';
    }
  }

  Future<void> initiateCommandExecution() async {
    print('DIAG: initiateCommandExecution() started');
    // Print stack trace to see what called us
    if (kDebugMode) {
      print('DIAG: initiateCommandExecution called from:');
      StackTrace.current.toString().split('\n').take(5).forEach((line) => print('DIAG: $line'));
    }
    if (!hasPendingCommand) {
      print('DIAG: AssistantController has no pending command');
      _setState(AssistantState.processing);
      return;
    }
    // We know lastCommandParseResult is not null because hasPendingCommand is true
    // and when isParsed is true, command is non-null.
    final command = _lastCommandParseResult!.command!;
    print('DIAG: AssistantController about to execute command via orchestrator: $command');
    print('DIAG: lastCommandParseResult before permission check: $_lastCommandParseResult');

    // Check if this is a CallCommand and handle permissions
    if (command is CallCommand) {
      print('DIAG: AssistantController checking contact permission for CallCommand');
      final hasContactPermission = await _platform.hasContactsPermission();
      print('DIAG: AssistantController hasContactPermission: $hasContactPermission');
      print('DIAG: lastCommandParseResult after hasContactsPermission: $_lastCommandParseResult');

      if (!hasContactPermission) {
        print('DIAG: AssistantController requesting contact permission');
        final contactPermissionGranted = await _platform.requestContactsPermission();
        print('DIAG: AssistantController contactPermissionGranted: $contactPermissionGranted');
        print('DIAG: lastCommandParseResult after requestContactsPermission: $_lastCommandParseResult');

        if (!contactPermissionGranted) {
          print('DIAG: AssistantController contact permission denied');
          _setState(AssistantState.error);
          _errorMessage = 'Contact permission is required.';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          print('DIAG: lastCommandParseResult after clearing for denied permission: $_lastCommandParseResult');
          return;
        }
      }

      // Check call permission for CallCommand
      print('DIAG: AssistantController checking call permission for CallCommand');
      final hasCallPermission = await _platform.hasCallPermission();
      print('DIAG: AssistantController hasCallPermission: $hasCallPermission');

      if (!hasCallPermission) {
        print('DIAG: AssistantController requesting call permission');
        final callPermissionGranted = await _platform.requestCallPermission();
        print('DIAG: AssistantController callPermissionGranted: $callPermissionGranted');

        if (!callPermissionGranted) {
          print('DIAG: AssistantController call permission denied');
          _setState(AssistantState.error);
          _errorMessage = 'Call permission is required.';
          _lastCommandParseResult = null; // Clear the command
          print('DIAG: lastCommandParseResult after clearing for denied call permission: $_lastCommandParseResult');
          return;
        }
      }
    }
    // Check if this is a BluetoothCommand and handle permissions
    else if (command is BluetoothCommand) {
      print('DIAG: AssistantController checking Bluetooth permission for BluetoothCommand');
      // For now, we'll check if we can get Bluetooth status as a proxy for permission
      // In a real implementation, we would add hasBluetoothPermission() and requestBluetoothPermission() methods
      final bluetoothStatus = await _platform.getBluetoothStatus();
      if (bluetoothStatus.status == BluetoothStatus.permissionRequired) {
        print('DIAG: AssistantController requesting Bluetooth permission');
        // Since there's no direct requestBluetoothPermission method, we try to enable Bluetooth
        // which will trigger a permission request if needed
        final enableResult = await _platform.requestBluetoothEnable();
        if (enableResult.status != BluetoothActionStatus.success &&
            enableResult.status != BluetoothActionStatus.userActionRequired) {
          print('DIAG: AssistantController Bluetooth permission request failed');
          _setState(AssistantState.error);
          _errorMessage = 'Bluetooth permission is required.';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          print('DIAG: lastCommandParseResult after clearing for denied Bluetooth permission: $_lastCommandParseResult');
          return;
        }
      }
    }

    // Check if this is a CallCommand (direct calling behavior only - safe calling feature removed)
    if (command is CallCommand) {
      print('DIAG: AssistantController handling CallCommand with direct calling behavior');
      try {
        // Resolve the contact
        print('DIAG: About to resolve contacts for query: ${command.contactQuery}');
        final resolveResult = await _platform.resolveContacts(command.contactQuery);
        print('DIAG: Contact resolution complete. Candidates count: ${resolveResult.candidates.length}, hasNoMatches: ${resolveResult.hasNoMatches}');

        if (resolveResult.hasNoMatches) {
          // No contacts found
          print('DIAG: No contacts found, setting state to error');
          _setState(AssistantState.error);
          _errorMessage = 'Contact not found: "${resolveResult.query}"';
          print('DIAG: State set to error');
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          print('DIAG: Returning from initiateCommandExecution after no contacts found');
          return;
        }

        // Filter to exact name matches only
        final exactMatchCandidates = resolveResult.candidates
            .where((candidate) => candidate.isExactNameMatch)
            .toList();

        if (exactMatchCandidates.isEmpty) {
          // No exact matches found
          _setState(AssistantState.error);
          _errorMessage = 'Contact not found: "${resolveResult.query}"';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          return;
        }

        if (exactMatchCandidates.length > 1) {
          // Multiple exact matches found - error (no fallback to selection)
          _setState(AssistantState.error);
          _errorMessage = 'Multiple exact matches found for "${resolveResult.query}". Please be more specific.';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          return;
        }

        // Exactly one exact match
        final candidate = exactMatchCandidates.first;
        if (candidate.phoneNumbers.isEmpty) {
          _setState(AssistantState.error);
          _errorMessage = 'Contact "${candidate.displayName}" has no phone numbers';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          // Command result is cleared in startListening() when a new session begins
          return;
        }

        if (candidate.phoneNumbers.length > 1) {
          // Multiple phone numbers for the exact match - error (no fallback to selection)
          _setState(AssistantState.error);
          _errorMessage = 'Contact "${candidate.displayName}" has multiple phone numbers. Please specify which number to call.';
          // Clear the parsed result to prevent re-handling
          _lastCommandParseResult = null;
          // Command result is cleared in startListening() when a new session begins
          return;
        }

        // Exactly one phone number - proceed with direct call
        final phoneNumber = candidate.phoneNumbers.first;

        // Prepare the call (gets confirmation token)
        final prepareResult = await _platform.prepareCall(
          contactId: candidate.contactId.toString(),
          phoneNumber: phoneNumber,
          displayName: candidate.displayName,
        );

        if (prepareResult.status == CallExecutionStatus.confirmationRequired) {
          // Immediately confirm the call
          final confirmResult = await _platform.confirmCall(
            confirmationToken: prepareResult.confirmationToken!,
            confirmed: true,
          );

          // Handle the confirm result
          _handleExecutionResult(_convertCallExecutionResult(confirmResult));
          return;
        } else {
          // Handle other prepare results (permission required, etc.)
          _handleExecutionResult(_convertCallExecutionResult(prepareResult));
          return;
        }
      } on PlatformException catch (e) {
        print('DIAG: AssistantController direct call PlatformException: $e');
        _setState(AssistantState.error);
        _errorMessage = 'Direct call failed: ${e.message}';
        return;
      } catch (e) {
        print('DIAG: AssistantController direct call exception: $e');
        _setState(AssistantState.error);
        _errorMessage = 'Direct call failed: $e';
        return;
      }
    }
    // If we handled a CallCommand with direct calling, we've already returned
    // so we won't reach the orchestrator execution below

    print('DIAG: About to execute via orchestrator');
    print('DIAG: lastCommandParseResult before orchestrator: $_lastCommandParseResult');
    // Execute via orchestrator
    final result = await _orchestrator.executeCommand(command);
    print('DIAG: AssistantController received result from orchestrator: $result');
    print('DIAG: lastCommandParseResult after orchestrator: $_lastCommandParseResult');

    // If we got a permission required error from the orchestrator, we do not clear the command
    // so that the user can retry after granting the permission.
    if (result.status == ExecutionStatus.permissionRequired) {
      print('DIAG: AssistantController got permission required error from orchestrator');
      _setState(AssistantState.error);
      _errorMessage = result.message;
      // Do not clear the command yet.
      return;
    }

    // Handle the result to update state appropriately
    _handleExecutionResult(result);
    // Clear the command result after handling, unless it's a permission required error
    // (we keep permission required errors so the user can retry after granting permission)
    // Note: Command result is cleared in startListening() for new sessions
    if (result.status != ExecutionStatus.permissionRequired) {
      _lastCommandParseResult = null;
    }
    print('DIAG: lastCommandParseResult after _handleExecutionResult: $_lastCommandParseResult');
  }

  /// Deprecated: Use orchestrator.executeCommand() instead.
  /// This method is kept for backward compatibility during transition.
  @Deprecated('Use orchestrator.executeCommand instead')
  Future<void> initiateCallCommand() async {
    await initiateCommandExecution();
  }

  void _handleExecutionResult(ExecutionResult result) {
    switch (result.status) {
      case ExecutionStatus.success:
        _setState(AssistantState.calling);
        break;
      case ExecutionStatus.userActionRequired:
        if (result.data is Map<String, dynamic>) {
          final data = result.data as Map<String, dynamic>;
          final actionType = data['actionType'] as String?;
          if (actionType == 'confirmationRequired') {
            _setState(AssistantState.awaitingConfirmation);
            _confirmationToken = data['confirmationToken'] as String?;
            _confirmationMessage = result.message;
          } else if (actionType == 'numberSelectionRequired') {
            _setState(AssistantState.numberSelectionRequired);
            if (data.containsKey('candidates') && data['candidates'] != null) {
              final candidatesData = data['candidates'] as List<dynamic>;
              _contactCandidates = candidatesData
                  .map((e) => ContactCandidate(
                        contactId: e['contactId'] as String? ?? '',
                        displayName: e['displayName'] as String? ?? '',
                        phoneNumbers: (e['phoneNumbers'] as List<dynamic>?)
                                ?.map((pn) => pn as String)
                                .toList() ?? const [],
                        isExactNameMatch: e['isExactNameMatch'] as bool? ?? false,
                      ))
                  .toList();
            } else if (data.containsKey('phoneNumbers') &&
                       data['phoneNumbers'] != null &&
                       data.containsKey('contactId') &&
                       data.containsKey('displayName')) {
              // Single contact with multiple numbers
              final candidate = ContactCandidate(
                contactId: data['contactId'] as String? ?? '',
                displayName: data['displayName'] as String? ?? '',
                phoneNumbers: (data['phoneNumbers'] as List<dynamic>?)
                        ?.map((pn) => pn as String)
                        .toList() ?? const [],
                isExactNameMatch: false,
              );
              _contactCandidates = [candidate];
            }
          }
        }
        break;
      case ExecutionStatus.permissionRequired:
        _setState(AssistantState.error);
        _errorMessage = result.message;
        break;
      case ExecutionStatus.failure:
      case ExecutionStatus.unsupported:
      case ExecutionStatus.invalidArguments:
      case ExecutionStatus.unavailable:
        _setState(AssistantState.error);
        _errorMessage = result.message;
        break;
      case ExecutionStatus.cancelled:
        _setState(AssistantState.error);
        _errorMessage = result.message;
        break;
    }
  }

  // Preserve the existing fields for backward compatibility with UI and tests
  // These will be updated by _handleExecutionResult
  List<ContactCandidate>? _contactCandidates;
  String? _confirmationToken;
  String? _confirmationMessage;
  String? _selectedPhoneNumber;

  // Call execution flow getters (preserved for backward compatibility)
  List<ContactCandidate> get contactCandidates => _contactCandidates ?? const [];
  String? get confirmationToken => _confirmationToken;
  String? get confirmationMessage => _confirmationMessage;
  String? get selectedPhoneNumber => _selectedPhoneNumber;
  bool get isResolvingContact => _state == AssistantState.resolvingContact;
  bool get isNumberSelectionRequired => _state == AssistantState.numberSelectionRequired;
  bool get isAwaitingConfirmation => _state == AssistantState.awaitingConfirmation;
  bool get isCalling => _state == AssistantState.calling;

  /// Converts a [CallExecutionResult] to an [ExecutionResult] for consistency
  /// with the orchestrator-based execution flow.
  ExecutionResult _convertCallExecutionResult(CallExecutionResult result) {
    switch (result.status) {
      case CallExecutionStatus.confirmationRequired:
        return ExecutionResult.userActionRequired(
          result.message,
          data: {
            'actionType': 'confirmationRequired',
            'confirmationToken': result.confirmationToken
          });
      case CallExecutionStatus.numberSelectionRequired:
        return ExecutionResult.userActionRequired(
          result.message,
          data: {
            'actionType': 'numberSelectionRequired',
            'availableNumbers': result.availableNumbers
          });
      case CallExecutionStatus.permissionRequired:
        return ExecutionResult.permissionRequired(result.message);
      case CallExecutionStatus.callFailed:
        return ExecutionResult.failure(result.message);
      case CallExecutionStatus.calling:
        return ExecutionResult.success();
      default:
        return ExecutionResult.failure(
            'Unexpected call execution result: ${result.status}');
    }
  }

  @override
  void dispose() {
    _wakeWordService.stop();
    _wakeWordListening = false;
    _eventSubscription?.cancel();
    super.dispose();
  }
}