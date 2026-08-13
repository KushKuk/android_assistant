import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/call_execution_result.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:flutter/services.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling CallCommand execution.
///
/// This capability encapsulates the existing call execution logic and delegates
/// to the AssistantPlatform for actual implementation, preserving all existing
/// safety mechanisms and validation.
class CallCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  CallCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: CallCapability.canHandle() called with command: $command');
    final result = command is CallCommand;
    print('DIAG: CallCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: CallCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: CallCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'CallCapability can only handle CallCommand');
    }

    final callCommand = command as CallCommand;
    print('DIAG: CallCapability about to execute _executeCallCommand');
    final result = await _executeCallCommand(callCommand);
    print('DIAG: CallCapability._executeCallCommand returned: $result');
    return result;
  }

  Future<ExecutionResult> _executeCallCommand(CallCommand command) async {
    print('DIAG: CallCapability._executeCallCommand() entered with command: $command');
    try {
      // Reset any previous call flow state would be handled by the caller
      // Start resolving the contact
      print('DIAG: CallCapability about to call _platform.resolveContacts');
      final resolveResult = await _platform.resolveContacts(command.contactQuery);
      print('DIAG: CallCapability._executeCallCommand got resolveResult: $resolveResult');

      if (resolveResult.hasNoMatches) {
        print('DIAG: CallCapability._executeCallCommand no matches found');
        return ExecutionResult.failure(
            'Contact not found: "${resolveResult.query}"');
      }

      if (resolveResult.hasMultipleMatches) {
        // Multiple contacts found - require user to select
        print('DIAG: CallCapability._executeCallCommand multiple matches found');
        // Convert ContactCandidate objects to maps for compatibility with controller
        final candidateMaps = resolveResult.candidates
            .map((candidate) => candidate.toMap())
            .toList();
        return ExecutionResult.userActionRequired(
            'Multiple contacts found. Please select one.',
            data: {
              'actionType': 'numberSelectionRequired',
              'candidates': candidateMaps
            });
      }

      // Exactly one contact
      final candidate = resolveResult.candidates.first;
      print('DIAG: CallCapability._executeCallCommand got candidate: $candidate');
      if (candidate.phoneNumbers.isEmpty) {
        print('DIAG: CallCapability._executeCallCommand candidate has no phone numbers');
        return ExecutionResult.failure(
            'Contact "${candidate.displayName}" has no phone numbers');
      }

      if (candidate.phoneNumbers.length == 1) {
        // Single phone number, proceed to prepareCall
        print('DIAG: CallCapability._executeCallCommand single phone number, preparing call');
        return await _handlePrepareCall(
            candidate.contactId, candidate.phoneNumbers.first, candidate.displayName);
      } else {
        // Multiple phone numbers for the same contact
        print('DIAG: CallCapability._executeCallCommand multiple phone numbers for contact');
        return ExecutionResult.userActionRequired(
            'Multiple phone numbers found. Please select one.',
            data: {
              'actionType': 'numberSelectionRequired',
              'phoneNumbers': candidate.phoneNumbers,
              'contactId': candidate.contactId,
              'displayName': candidate.displayName
            });
      }
    } on PlatformException catch (e) {
      print('DIAG: CallCapability._executeCallCommand caught PlatformException: $e');
      if (e.code == 'contacts_permission_required') {
        print('DIAG: CallCapability._executeCallCommand handling contacts permission required');
        return ExecutionResult.permissionRequired(e.message ?? 'Contacts permission is required.');
      }
      print('DIAG: CallCapability._executeCallCommand handling other PlatformException: $e');
      return ExecutionResult.failure('Call execution failed: $e');
    } catch (e) {
      print('DIAG: CallCapability._executeCallCommand caught exception: $e');
      return ExecutionResult.failure('Call execution failed: $e');
    }
  }

  Future<ExecutionResult> _handlePrepareCall(
      String contactId, String phoneNumber, String displayName) async {
    print('DIAG: CallCapability._handlePrepareCall() entered with contactId: $contactId, phoneNumber: $phoneNumber, displayName: $displayName');
    try {
      print('DIAG: CallCapability about to call _platform.prepareCall');
      final result = await _platform.prepareCall(
          contactId: contactId,
          phoneNumber: phoneNumber,
          displayName: displayName,
      );
      print('DIAG: CallCapability._handlePrepareCall got result: $result');
      final converted = _convertCallExecutionResult(result);
      print('DIAG: CallCapability._handlePrepareCall converted result: $converted');
      return converted;
    } catch (e) {
      print('DIAG: CallCapability._handlePrepareCall caught exception: $e');
      return ExecutionResult.failure('Prepare call failed: $e');
    }
  }

  ExecutionResult _convertCallExecutionResult(CallExecutionResult result) {
    print('DIAG: CallCapability._convertCallExecutionResult() entered with result: $result');
    switch (result.status) {
      case CallExecutionStatus.confirmationRequired:
        print('DIAG: CallCapability._convertCallExecutionResult returning userActionRequired for confirmation');
        return ExecutionResult.userActionRequired(
            result.message,
            data: {
              'actionType': 'confirmationRequired',
              'confirmationToken': result.confirmationToken
            });
      case CallExecutionStatus.numberSelectionRequired:
        print('DIAG: CallCapability._convertCallExecutionResult returning userActionRequired for number selection');
        return ExecutionResult.userActionRequired(
            result.message,
            data: {
              'actionType': 'numberSelectionRequired',
              'availableNumbers': result.availableNumbers
            });
      case CallExecutionStatus.permissionRequired:
        print('DIAG: CallCapability._convertCallExecutionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(result.message);
      case CallExecutionStatus.callFailed:
        print('DIAG: CallCapability._convertCallExecutionResult returning failure');
        return ExecutionResult.failure(result.message);
      case CallExecutionStatus.calling:
        print('DIAG: CallCapability._convertCallExecutionResult returning success');
        return ExecutionResult.success();
      default:
        print('DIAG: CallCapability._convertCallExecutionResult returning failure for unexpected status');
        return ExecutionResult.failure(
            'Unexpected prepareCall result: ${result.status}');
    }
  }
}