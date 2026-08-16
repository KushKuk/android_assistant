import 'package:flutter/services.dart';
import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling WhatsAppCommand execution.
///
/// This capability encapsulates WhatsApp messaging and calling logic and delegates
/// to the AssistantPlatform for actual implementation.
class WhatsAppCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  WhatsAppCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: WhatsAppCapability.canHandle() called with command: $command');
    final result = command is WhatsAppMessageCommand ||
        command is WhatsAppAudioCallCommand ||
        command is WhatsAppVideoCallCommand;
    print('DIAG: WhatsAppCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: WhatsAppCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: WhatsAppCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'WhatsAppCapability can only handle WhatsAppMessageCommand, WhatsAppAudioCallCommand, or WhatsAppVideoCallCommand');
    }

    if (command is WhatsAppMessageCommand) {
      print('DIAG: WhatsAppCapability about to execute _executeWhatsAppMessage');
      final result = await _executeWhatsAppMessage(command as WhatsAppMessageCommand);
      print('DIAG: WhatsAppCapability._executeWhatsAppMessage returned: $result');
      return result;
    } else if (command is WhatsAppAudioCallCommand) {
      print('DIAG: WhatsAppCapability about to execute _executeWhatsAppAudioCall');
      final result = await _executeWhatsAppAudioCall(command as WhatsAppAudioCallCommand);
      print('DIAG: WhatsAppCapability._executeWhatsAppAudioCall returned: $result');
      return result;
    } else if (command is WhatsAppVideoCallCommand) {
      print('DIAG: WhatsAppCapability about to execute _executeWhatsAppVideoCall');
      final result = await _executeWhatsAppVideoCall(command as WhatsAppVideoCallCommand);
      print('DIAG: WhatsAppCapability._executeWhatsAppVideoCall returned: $result');
      return result;
    } else {
      // This shouldn't happen due to canHandle check, but just in case
      return ExecutionResult.unsupported('Unsupported WhatsApp command type');
    }
  }

  Future<ExecutionResult> _executeWhatsAppMessage(
      WhatsAppMessageCommand command) async {
    print('DIAG: WhatsAppCapability._executeWhatsAppMessage() entered with command: $command');
    try {
      // Require explicit confirmation before sending message
      if (!command.confirmed) {
        print('DIAG: WhatsAppCapability confirmation required for message');
        return ExecutionResult.userActionRequired(
            'Send WhatsApp message to ${command.contactQuery}: "${command.message}"?',
            data: {
              'contactQuery': command.contactQuery,
              'message': command.message,
              'actionType': 'confirmationRequired'
            });
      }

      // First resolve the contact using existing infrastructure
      print('DIAG: WhatsAppCapability resolving contact for query: ${command.contactQuery}');
      final contactResult = await _platform.resolveContacts(command.contactQuery);
      print('DIAG: WhatsAppCapability contact resolution complete. Candidates count: ${contactResult.candidates.length}, hasNoMatches: ${contactResult.hasNoMatches}');

      if (contactResult.hasNoMatches) {
        // No contacts found
        print('DIAG: WhatsAppCapability no contacts found');
        return ExecutionResult.failure('Contact not found: "${command.contactQuery}"');
      }

      // Check for multiple matches
      if (contactResult.candidates.length > 1) {
        // Multiple contacts found - require disambiguation
        print('DIAG: WhatsAppCapability multiple contacts found');
        return ExecutionResult.userActionRequired(
            'Multiple contacts found for "${command.contactQuery}". Please be more specific.',
            data: {
              'contactQuery': command.contactQuery,
              'candidates': contactResult.candidates.map((c) => {
                'contactId': c.contactId,
                'displayName': c.displayName,
                'phoneNumbers': c.phoneNumbers,
              }).toList(),
              'actionType': 'disambiguateContact'
            });
      }

      final candidate = contactResult.candidates.first;

      // Check if contact has phone numbers
      if (candidate.phoneNumbers.isEmpty) {
        print('DIAG: WhatsAppCapability contact has no phone numbers');
        return ExecutionResult.failure('Contact "${candidate.displayName}" has no phone numbers');
      }

      // Check if contact has multiple phone numbers
      if (candidate.phoneNumbers.length > 1) {
        print('DIAG: WhatsAppCapability contact has multiple phone numbers');
        return ExecutionResult.userActionRequired(
            'Contact "${candidate.displayName}" has multiple phone numbers. Please specify which number to use.',
            data: {
              'contactId': candidate.contactId,
              'displayName': candidate.displayName,
              'phoneNumbers': candidate.phoneNumbers,
              'actionType': 'selectPhoneNumber'
            });
      }

      // Get the phone number
      final phoneNumber = candidate.phoneNumbers.first;

      // Check WhatsApp availability/support
      print('DIAG: WhatsAppCapability checking WhatsApp availability');
      final whatsAppAvailable = await _platform.isWhatsAppAvailable();
      if (!whatsAppAvailable) {
        print('DIAG: WhatsAppCapability WhatsApp not available');
        return ExecutionResult.unavailable('WhatsApp is not installed or not available on this device');
      }

      // Send the WhatsApp message
      print('DIAG: WhatsAppCapability sending WhatsApp message to $phoneNumber');
      final result = await _platform.sendWhatsAppMessage(
        phoneNumber: phoneNumber,
        message: command.message,
      );

      print('DIAG: WhatsAppCapability sendWhatsAppMessage result: $result');
      return _convertWhatsAppSendResult(result);
    } on PlatformException catch (e) { // Missing from try block - need to add
      print('DIAG: WhatsAppCapability._executeWhatsAppMessage caught PlatformException: $e');
      return ExecutionResult.failure('WhatsApp message failed: ${e.message}');
    } catch (e) {
      print('DIAG: WhatsAppCapability._executeWhatsAppMessage caught exception: $e');
      return ExecutionResult.failure('WhatsApp message failed: $e');
    }
  }

  Future<ExecutionResult> _executeWhatsAppAudioCall(
      WhatsAppAudioCallCommand command) async {
    print('DIAG: WhatsAppCapability._executeWhatsAppAudioCall() entered with command: $command');
    try {
      // Require explicit confirmation before making call
      if (!command.confirmed) {
        print('DIAG: WhatsAppCapability confirmation required for audio call');
        return ExecutionResult.userActionRequired(
            'Make WhatsApp audio call to ${command.contactQuery}?',
            data: {
              'contactQuery': command.contactQuery,
              'actionType': 'confirmationRequired'
            });
      }

      // First resolve the contact using existing infrastructure
      print('DIAG: WhatsAppCapability resolving contact for query: ${command.contactQuery}');
      final contactResult = await _platform.resolveContacts(command.contactQuery);
      print('DIAG: WhatsAppCapability contact resolution complete. Candidates count: ${contactResult.candidates.length}, hasNoMatches: ${contactResult.hasNoMatches}');

      if (contactResult.hasNoMatches) {
        // No contacts found
        print('DIAG: WhatsAppCapability no contacts found');
        return ExecutionResult.failure('Contact not found: "${command.contactQuery}"');
      }

      // Check for multiple matches
      if (contactResult.candidates.length > 1) {
        // Multiple contacts found - require disambiguation
        print('DIAG: WhatsAppCapability multiple contacts found');
        return ExecutionResult.userActionRequired(
            'Multiple contacts found for "${command.contactQuery}". Please be more specific.',
            data: {
              'contactQuery': command.contactQuery,
              'candidates': contactResult.candidates.map((c) => {
                'contactId': c.contactId,
                'displayName': c.displayName,
                'phoneNumbers': c.phoneNumbers,
              }).toList(),
              'actionType': 'disambiguateContact'
            });
      }

      final candidate = contactResult.candidates.first;

      // Check if contact has phone numbers
      if (candidate.phoneNumbers.isEmpty) {
        print('DIAG: WhatsAppCapability contact has no phone numbers');
        return ExecutionResult.failure('Contact "${candidate.displayName}" has no phone numbers');
      }

      // Check if contact has multiple phone numbers
      if (candidate.phoneNumbers.length > 1) {
        print('DIAG: WhatsAppCapability contact has multiple phone numbers');
        return ExecutionResult.userActionRequired(
            'Contact "${candidate.displayName}" has multiple phone numbers. Please specify which number to use.',
            data: {
              'contactId': candidate.contactId,
              'displayName': candidate.displayName,
              'phoneNumbers': candidate.phoneNumbers,
              'actionType': 'selectPhoneNumber'
            });
      }

      // Get the phone number
      final phoneNumber = candidate.phoneNumbers.first;

      // Check WhatsApp availability/support
      print('DIAG: WhatsAppCapability checking WhatsApp availability');
      final whatsAppAvailable = await _platform.isWhatsAppAvailable();
      if (!whatsAppAvailable) {
        print('DIAG: WhatsAppCapability WhatsApp not available');
        return ExecutionResult.unavailable('WhatsApp is not installed or not available on this device');
      }

      // Make the WhatsApp audio call
      print('DIAG: WhatsAppCapability making WhatsApp audio call to $phoneNumber');
      final result = await _platform.makeWhatsAppCall(
        phoneNumber: phoneNumber,
        isVideo: false,
      );

      print('DIAG: WhatsAppCapability makeWhatsAppCall result: $result');
      return _convertWhatsAppCallResult(result);
    } on PlatformException catch (e) { // Missing from try block - need to add
      print('DIAG: WhatsAppCapability._executeWhatsAppAudioCall caught PlatformException: $e');
      return ExecutionResult.failure('WhatsApp audio call failed: ${e.message}');
    } catch (e) {
      print('DIAG: WhatsAppCapability._executeWhatsAppAudioCall caught exception: $e');
      return ExecutionResult.failure('WhatsApp audio call failed: $e');
    }
  }

  Future<ExecutionResult> _executeWhatsAppVideoCall(
      WhatsAppVideoCallCommand command) async {
    print('DIAG: WhatsAppCapability._executeWhatsAppVideoCall() entered with command: $command');
    try {
      // Require explicit confirmation before making call
      if (!command.confirmed) {
        print('DIAG: WhatsAppCapability confirmation required for video call');
        return ExecutionResult.userActionRequired(
            'Make WhatsApp video call to ${command.contactQuery}?',
            data: {
              'contactQuery': command.contactQuery,
              'actionType': 'confirmationRequired'
            });
      }

      // First resolve the contact using existing infrastructure
      print('DIAG: WhatsAppCapability resolving contact for query: ${command.contactQuery}');
      final contactResult = await _platform.resolveContacts(command.contactQuery);
      print('DIAG: WhatsAppCapability contact resolution complete. Candidates count: ${contactResult.candidates.length}, hasNoMatches: ${contactResult.hasNoMatches}');

      if (contactResult.hasNoMatches) {
        // No contacts found
        print('DIAG: WhatsAppCapability no contacts found');
        return ExecutionResult.failure('Contact not found: "${command.contactQuery}"');
      }

      // Check for multiple matches
      if (contactResult.candidates.length > 1) {
        // Multiple contacts found - require disambiguation
        print('DIAG: WhatsAppCapability multiple contacts found');
        return ExecutionResult.userActionRequired(
            'Multiple contacts found for "${command.contactQuery}". Please be more specific.',
            data: {
              'contactQuery': command.contactQuery,
              'candidates': contactResult.candidates.map((c) => {
                'contactId': c.contactId,
                'displayName': c.displayName,
                'phoneNumbers': c.phoneNumbers,
              }).toList(),
              'actionType': 'disambiguateContact'
            });
      }

      final candidate = contactResult.candidates.first;

      // Check if contact has phone numbers
      if (candidate.phoneNumbers.isEmpty) {
        print('DIAG: WhatsAppCapability contact has no phone numbers');
        return ExecutionResult.failure('Contact "${candidate.displayName}" has no phone numbers');
      }

      // Check if contact has multiple phone numbers
      if (candidate.phoneNumbers.length > 1) {
        print('DIAG: WhatsAppCapability contact has multiple phone numbers');
        return ExecutionResult.userActionRequired(
            'Contact "${candidate.displayName}" has multiple phone numbers. Please specify which number to use.',
            data: {
              'contactId': candidate.contactId,
              'displayName': candidate.displayName,
              'phoneNumbers': candidate.phoneNumbers,
              'actionType': 'selectPhoneNumber'
            });
      }

      // Get the phone number
      final phoneNumber = candidate.phoneNumbers.first;

      // Check WhatsApp availability/support
      print('DIAG: WhatsAppCapability checking WhatsApp availability');
      final whatsAppAvailable = await _platform.isWhatsAppAvailable();
      if (!whatsAppAvailable) {
        print('DIAG: WhatsAppCapability WhatsApp not available');
        return ExecutionResult.unavailable('WhatsApp is not installed or not available on this device');
      }

      // Make the WhatsApp video call
      print('DIAG: WhatsAppCapability making WhatsApp video call to $phoneNumber');
      final result = await _platform.makeWhatsAppCall(
        phoneNumber: phoneNumber,
        isVideo: true,
      );

      print('DIAG: WhatsAppCapability makeWhatsAppCall result: $result');
      return _convertWhatsAppCallResult(result);
    } on PlatformException catch (e) { // Missing from try block - need to add
      print('DIAG: WhatsAppCapability._executeWhatsAppVideoCall caught PlatformException: $e');
      return ExecutionResult.failure('WhatsApp video call failed: ${e.message}');
    } catch (e) {
      print('DIAG: WhatsAppCapability._executeWhatsAppVideoCall caught exception: $e');
      return ExecutionResult.failure('WhatsApp video call failed: $e');
    }
  }

  ExecutionResult _convertWhatsAppSendResult(Object result) {
    print('DIAG: WhatsAppCapability._convertWhatsAppSendResult() entered with result: $result');
    // Assuming the platform returns a boolean or similar success indicator
    // For now, we'll treat any non-null result as success since failures throw exceptions
    return ExecutionResult.success(data: result);
  }

  ExecutionResult _convertWhatsAppCallResult(Object result) {
    print('DIAG: WhatsAppCapability._convertWhatsAppCallResult() entered with result: $result');
    // Assuming the platform returns a boolean or similar success indicator
    // For now, we'll treat any non-null result as success since failures throw exceptions
    return ExecutionResult.success(data: result);
  }
}