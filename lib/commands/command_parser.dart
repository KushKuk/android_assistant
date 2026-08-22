import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/commands/command_parse_result.dart';
import 'package:voice_assistant/models/bluetooth_device_info.dart';

// Marker object to indicate that a WhatsApp pattern matched but validation failed
final Object _invalidWhatsAppMarker = Object();

// Call patterns moved to top-level to avoid static modifier issues
final _callPatterns = <RegExp>[
    RegExp(r'^\s*(?:call|phone)\s+(.+?)\s*$', caseSensitive: false),
    RegExp(r'^\s*give\s+(.+?)\s+a\s+call\s*$', caseSensitive: false),
    RegExp(r'^\s*video\s+call\s+(.+?)\s*$', caseSensitive: false),
  ];

final _callWithoutTarget = RegExp(
  r'^\s*(?:call|phone|video\s+call)\s*[.!?]?\s*$',
  caseSensitive: false,
);

/// Deterministic parsing for supported commands. Execution is intentionally
/// separate and remains the responsibility of the Android call pipeline.
class CommandParser {
  const CommandParser();

  CommandParseResult parse(String input) {
    print('DIAG: CommandParser.parse() entered with input: "$input"');
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      print('DIAG: CommandParser.parse() exiting: empty input');
      return const CommandParseResult.unsupported('No command was provided.');
    }

    // Check if input contains "whatsapp" (case-insensitive) to determine if we should try WhatsApp parsing
    final lowerInput = normalizedInput.toLowerCase();
    final containsWhatsApp = lowerInput.contains('whatsapp');

    if (containsWhatsApp) {
      // Try WhatsApp video call command first (per precedence rules)
      final whatsappVideoCallResult = _whatsappVideoCallTargetWithValidation(normalizedInput);
      if (whatsappVideoCallResult == _invalidWhatsAppMarker) {
        // WhatsApp pattern matched but validation failed - don't fall through to other parsers
        print('DIAG: CommandParser.parse() exiting: WhatsApp video call pattern matched but validation failed');
        return const CommandParseResult.unsupported('Invalid WhatsApp video call command.');
      } else if (whatsappVideoCallResult != null && whatsappVideoCallResult is WhatsAppVideoCallCommand) {
        final command = whatsappVideoCallResult as WhatsAppVideoCallCommand;
        print('DIAG: CommandParser.parse() exiting: parsed WhatsAppVideoCallCommand with contact: ${command.contactQuery}');
        return CommandParseResult.parsed(command);
      }

      // Try WhatsApp audio call command second
      final whatsappAudioCallResult = _whatsappAudioCallTargetWithValidation(normalizedInput);
      if (whatsappAudioCallResult == _invalidWhatsAppMarker) {
        // WhatsApp pattern matched but validation failed - don't fall through to other parsers
        print('DIAG: CommandParser.parse() exiting: WhatsApp audio call pattern matched but validation failed');
        return const CommandParseResult.unsupported('Invalid WhatsApp audio call command.');
      } else if (whatsappAudioCallResult != null && whatsappAudioCallResult is WhatsAppAudioCallCommand) {
        final command = whatsappAudioCallResult as WhatsAppAudioCallCommand;
        print('DIAG: CommandParser.parse() exiting: parsed WhatsAppAudioCallCommand with contact: ${command.contactQuery}');
        return CommandParseResult.parsed(command);
      }

      // Try WhatsApp message command third
      final whatsappMessageResult = _whatsappMessageTargetWithValidation(normalizedInput);
      if (whatsappMessageResult == _invalidWhatsAppMarker) {
        // WhatsApp pattern matched but validation failed - don't fall through to other parsers
        print('DIAG: CommandParser.parse() exiting: WhatsApp message pattern matched but validation failed');
        return const CommandParseResult.unsupported('Invalid WhatsApp message command.');
      } else if (whatsappMessageResult != null && whatsappMessageResult is WhatsAppMessageCommand) {
        final command = whatsappMessageResult as WhatsAppMessageCommand;
        print('DIAG: CommandParser.parse() exiting: parsed WhatsAppMessageCommand with contact: ${command.contactQuery}, message length: ${command.message.length}');
        return CommandParseResult.parsed(command);
      }

      // If we got here, no WhatsApp pattern matched at all (even though input contains "whatsapp")
      // Fall through to normal parsers
      print('DIAG: CommandParser.parse() exiting: contains "whatsapp" but no WhatsApp pattern matched, falling through to normal parsers');
    } else {
      print('DIAG: CommandParser.parse() exiting: does not contain "whatsapp", using normal parsers');
    }

    // Try call command first
    final contactQuery = _callTarget(normalizedInput);
    if (contactQuery != null) {
      if (contactQuery.isEmpty) {
        print('DIAG: CommandParser.parse() exiting: empty contact query');
        return const CommandParseResult.unsupported(
          'A contact or phone number is required.',
        );
      }
      print('DIAG: CommandParser.parse() exiting: parsed CallCommand with query: $contactQuery');
      return CommandParseResult.parsed(CallCommand(contactQuery: contactQuery));
    }

    // Try bluetooth command
    final bluetoothAction = _bluetoothTarget(normalizedInput);
    if (bluetoothAction != null) {
      print('DIAG: CommandParser.parse() exiting: parsed BluetoothCommand with action: $bluetoothAction');
      return CommandParseResult.parsed(BluetoothCommand(action: bluetoothAction, deviceQuery: null, deviceAddress: null));
    }

    // Try connectivity command
    final connectivityCommand = _connectivityTarget(normalizedInput);
    if (connectivityCommand != null) {
      print('DIAG: CommandParser.parse() exiting: parsed ConnectivityCommand with type: ${connectivityCommand.type}, action: ${connectivityCommand.action}');
      return CommandParseResult.parsed(connectivityCommand);
    }

    // Try flashlight command
    final flashlightCommand = _flashlightTarget(normalizedInput);
    if (flashlightCommand != null) {
      print('DIAG: CommandParser.parse() exiting: parsed FlashlightCommand with action: ${flashlightCommand.action}');
      return CommandParseResult.parsed(flashlightCommand);
    }

    // Try screenshot command
    final screenshotCommand = _screenshotTarget(normalizedInput);
    if (screenshotCommand != null) {
      print('DIAG: CommandParser.parse() exiting: parsed ScreenshotCommand');
      return CommandParseResult.parsed(screenshotCommand);
    }

    // Try device settings command
    final deviceSettingsCommand = _deviceSettingsTarget(normalizedInput);
    if (deviceSettingsCommand != null) {
      print('DIAG: CommandParser.parse() exiting: parsed DeviceSettingsCommand with type: ${deviceSettingsCommand.settingsType}, action: ${deviceSettingsCommand.action}');
      return CommandParseResult.parsed(deviceSettingsCommand);
    }

    print('DIAG: CommandParser.parse() exiting: command not supported');
    return const CommandParseResult.unsupported('Command is not supported.');
  }

  DeviceSettingsCommand? _deviceSettingsTarget(String input) {
    print('DIAG: CommandParser._deviceSettingsTarget() entered with input: $input');
    final lower = input.toLowerCase();

    // Volume commands (media, ring, alarm)
    if (RegExp(r'^\s*increase\s+volume\s*$').hasMatch(lower) ||
        RegExp(r'^\s*volume\s+up\s*$').hasMatch(lower) ||
        RegExp(r'^\s*vol\s+up\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume increase');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.increase);
    }

    if (RegExp(r'^\s*decrease\s+volume\s*$').hasMatch(lower) ||
        RegExp(r'^\s*volume\s+down\s*$').hasMatch(lower) ||
        RegExp(r'^\s*vol\s+down\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume decrease');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.decrease);
    }

    if (RegExp(r'^\s*set\s+volume\s+to\s+(\d+)\s*%\s*$').hasMatch(lower)) {
      final match = RegExp(r'^\s*set\s+volume\s+to\s+(\d+)\s*%\s*$').firstMatch(lower);
      if (match != null) {
        final percentage = int.parse(match.group(1)!);
        print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume set to $percentage%');
        return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.set, value: percentage);
      }
    }

    if (RegExp(r'^\s*mute\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume mute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.mute);
    }

    if (RegExp(r'^\s*unmute\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume unmute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.unmute);
    }

    if (RegExp(r'^\s*max\s+volume\s*$').hasMatch(lower) ||
        RegExp(r'^\s*volume\s+max\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume max');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.max);
    }

    if (RegExp(r'^\s*volume\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+volume\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: volume status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeMedia, action: DeviceSettingsAction.getStatus);
    }

    // Ring volume commands
    if (RegExp(r'^\s*increase\s+ring\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume increase');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.increase);
    }

    if (RegExp(r'^\s*decrease\s+ring\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume decrease');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.decrease);
    }

    if (RegExp(r'^\s*set\s+ring\s+volume\s+to\s+(\d+)\s*%\s*$').hasMatch(lower)) {
      final match = RegExp(r'^\s*set\s+ring\s+volume\s+to\s+(\d+)\s*%\s*$').firstMatch(lower);
      if (match != null) {
        final percentage = int.parse(match.group(1)!);
        print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume set to $percentage%');
        return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.set, value: percentage);
      }
    }

    if (RegExp(r'^\s*mute\s+ring\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume mute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.mute);
    }

    if (RegExp(r'^\s*unmute\s+ring\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume unmute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.unmute);
    }

    if (RegExp(r'^\s*max\s+ring\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume max');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.max);
    }

    if (RegExp(r'^\s*ring\s+volume\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ring volume status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeRing, action: DeviceSettingsAction.getStatus);
    }

    // Alarm volume commands
    if (RegExp(r'^\s*increase\s+alarm\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume increase');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.increase);
    }

    if (RegExp(r'^\s*decrease\s+alarm\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume decrease');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.decrease);
    }

    if (RegExp(r'^\s*set\s+alarm\s+volume\s+to\s+(\d+)\s*%\s*$').hasMatch(lower)) {
      final match = RegExp(r'^\s*set\s+alarm\s+volume\s+to\s+(\d+)\s*%\s*$').firstMatch(lower);
      if (match != null) {
        final percentage = int.parse(match.group(1)!);
        print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume set to $percentage%');
        return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.set, value: percentage);
      }
    }

    if (RegExp(r'^\s*mute\s+alarm\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume mute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.mute);
    }

    if (RegExp(r'^\s*unmute\s+alarm\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume unmute');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.unmute);
    }

    if (RegExp(r'^\s*max\s+alarm\s+volume\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume max');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.max);
    }

    if (RegExp(r'^\s*alarm\s+volume\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: alarm volume status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.volumeAlarm, action: DeviceSettingsAction.getStatus);
    }

    // Brightness commands
    if (RegExp(r'^\s*increase\s+brightness\s*$').hasMatch(lower) ||
        RegExp(r'^\s*brightness\s+up\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness increase');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.increase);
    }

    if (RegExp(r'^\s*decrease\s+brightness\s*$').hasMatch(lower) ||
        RegExp(r'^\s*brightness\s+down\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness decrease');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.decrease);
    }

    if (RegExp(r'^\s*set\s+brightness\s+to\s+(\d+)\s*%\s*$').hasMatch(lower)) {
      final match = RegExp(r'^\s*set\s+brightness\s+to\s+(\d+)\s*%\s*$').firstMatch(lower);
      if (match != null) {
        final percentage = int.parse(match.group(1)!);
        print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness set to $percentage%');
        return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.set, value: percentage);
      }
    }

    if (RegExp(r'^\s*max\s+brightness\s*$').hasMatch(lower) ||
        RegExp(r'^\s*brightness\s+max\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness max');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.max);
    }

    if (RegExp(r'^\s*min\s+brightness\s*$').hasMatch(lower) ||
        RegExp(r'^\s*brightness\s+min\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness min');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.min);
    }

    if (RegExp(r'^\s*brightness\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+brightness\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: brightness status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.brightness, action: DeviceSettingsAction.getStatus);
    }

    // Flashlight commands
    if (RegExp(r'^\s*turn\s+on\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*flashlight\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+flashlight\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: flashlight on');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.flashlight, action: DeviceSettingsAction.set, value: true);
    }

    if (RegExp(r'^\s*turn\s+off\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*flashlight\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+flashlight\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: flashlight off');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.flashlight, action: DeviceSettingsAction.set, value: false);
    }

    if (RegExp(r'^\s*toggle\s+flashlight\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: flashlight toggle');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.flashlight, action: DeviceSettingsAction.toggle);
    }

    if (RegExp(r'^\s*flashlight\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+flashlight\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: flashlight status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.flashlight, action: DeviceSettingsAction.getStatus);
    }

    // Ringer mode commands
    if (RegExp(r'^\s*turn\s+on\s+silent\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+silent\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*silent\s+mode\s+on\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: silent mode on');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.ringerMode, action: DeviceSettingsAction.set, value: "SILENT");
    }

    if (RegExp(r'^\s*turn\s+on\s+vibrate\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+vibrate\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*vibrate\s+mode\s+on\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: vibrate mode on');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.ringerMode, action: DeviceSettingsAction.set, value: "VIBRATE");
    }

    if (RegExp(r'^\s*turn\s+on\s+normal\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+normal\s+mode\s*$').hasMatch(lower) ||
        RegExp(r'^\s*normal\s+mode\s+on\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: normal mode on');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.ringerMode, action: DeviceSettingsAction.set, value: "NORMAL");
    }

    if (RegExp(r'^\s*ringer\s+mode\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+ringer\s+mode\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: ringer mode status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.ringerMode, action: DeviceSettingsAction.getStatus);
    }

    // Do Not Disturb commands
    if (RegExp(r'^\s*turn\s+on\s+do\s+not\s+disturb\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+do\s+not\s+disturb\s*$').hasMatch(lower) ||
        RegExp(r'^\s*do\s+not\s+disturb\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*turn\s+on\s+dnd\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+dnd\s*$').hasMatch(lower) ||
        RegExp(r'^\s*dnd\s+on\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: DND on');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.dnd, action: DeviceSettingsAction.set, value: true);
    }

    if (RegExp(r'^\s*turn\s+off\s+do\s+not\s+disturb\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+do\s+not\s+disturb\s*$').hasMatch(lower) ||
        RegExp(r'^\s*do\s+not\s+disturb\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*turn\s+off\s+dnd\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+dnd\s*$').hasMatch(lower) ||
        RegExp(r'^\s*dnd\s+off\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: DND off');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.dnd, action: DeviceSettingsAction.set, value: false);
    }

    if (RegExp(r'^\s*dnd\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+dnd\s+status\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._deviceSettingsTarget() exiting with match: DND status');
      return DeviceSettingsCommand(settingsType: DeviceSettingsType.dnd, action: DeviceSettingsAction.getStatus);
    }

    print('DIAG: CommandParser._deviceSettingsTarget() exiting: no match');
    return null;
  }

  ConnectivityCommand? _connectivityTarget(String input) {
    print('DIAG: CommandParser._connectivityTarget() entered with input: $input');
    final lower = input.toLowerCase();

    // Wi-Fi commands
    if (RegExp(r'^\s*turn\s+on\s+wi[-]?fi\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+wi[-]?fi\s*$').hasMatch(lower) ||
        RegExp(r'^\s*wi[-]?fi\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+wi[-]?fi\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: wifi enable');
      return ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.enable);
    }

    if (RegExp(r'^\s*turn\s+off\s+wi[-]?fi\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+wi[-]?fi\s*$').hasMatch(lower) ||
        RegExp(r'^\s*wi[-]?fi\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+wi[-]?fi\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: wifi disable');
      return ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.disable);
    }

    if (RegExp(r'^\s*open\s+wi[-]?fi\s+settings\s*$').hasMatch(lower) ||
        RegExp(r'^\s*wi[-]?fi\s+settings\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: wifi open settings');
      return ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.openSettings);
    }

    // Mobile data commands
    if (RegExp(r'^\s*turn\s+on\s+mobile\s+data\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+mobile\s+data\s*$').hasMatch(lower) ||
        RegExp(r'^\s*mobile\s+data\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+mobile\s+data\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: mobile data enable');
      return ConnectivityCommand(type: ConnectivityType.mobileData, action: ConnectivityAction.enable);
    }

    if (RegExp(r'^\s*turn\s+off\s+mobile\s+data\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+mobile\s+data\s*$').hasMatch(lower) ||
        RegExp(r'^\s*mobile\s+data\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+mobile\s+data\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: mobile data disable');
      return ConnectivityCommand(type: ConnectivityType.mobileData, action: ConnectivityAction.disable);
    }

    if (RegExp(r'^\s*open\s+mobile\s+data\s+settings\s*$').hasMatch(lower) ||
        RegExp(r'^\s*mobile\s+data\s+settings\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: mobile data open settings');
      return ConnectivityCommand(type: ConnectivityType.mobileData, action: ConnectivityAction.openSettings);
    }

    // Hotspot commands
    if (RegExp(r'^\s*turn\s+on\s+hotspot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+hotspot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*hotspot\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+hotspot\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: hotspot enable');
      return ConnectivityCommand(type: ConnectivityType.hotspot, action: ConnectivityAction.enable);
    }

    if (RegExp(r'^\s*turn\s+off\s+hotspot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+hotspot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*hotspot\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+hotspot\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: hotspot disable');
      return ConnectivityCommand(type: ConnectivityType.hotspot, action: ConnectivityAction.disable);
    }

    if (RegExp(r'^\s*open\s+hotspot\s+settings\s*$').hasMatch(lower) ||
        RegExp(r'^\s*hotspot\s+settings\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: hotspot open settings');
      return ConnectivityCommand(type: ConnectivityType.hotspot, action: ConnectivityAction.openSettings);
    }

    // Status commands for all types
    if (RegExp(r'^\s*wi[-]?fi\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+wi[-]?fi\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*is\s+wi[-]?fi\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*wi[-]?fi\s+state\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: wifi status');
      return ConnectivityCommand(type: ConnectivityType.wifi, action: ConnectivityAction.getStatus);
    }

    if (RegExp(r'^\s*mobile\s+data\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+mobile\s+data\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*is\s+mobile\s+data\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*mobile\s+data\s+state\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: mobile data status');
      return ConnectivityCommand(type: ConnectivityType.mobileData, action: ConnectivityAction.getStatus);
    }

    if (RegExp(r'^\s*hotspot\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+hotspot\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*is\s+hotspot\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*hotspot\s+state\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._connectivityTarget() exiting with match: hotspot status');
      return ConnectivityCommand(type: ConnectivityType.hotspot, action: ConnectivityAction.getStatus);
    }

    print('DIAG: CommandParser._connectivityTarget() exiting: no match');
    return null;
  }

  FlashlightCommand? _flashlightTarget(String input) {
    print('DIAG: CommandParser._flashlightTarget() entered with input: $input');
    final lower = input.toLowerCase();

    // Turn on flashlight
    if (RegExp(r'^\s*turn\s+on\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*flashlight\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+flashlight\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._flashlightTarget() exiting with match: flashlight on');
      return FlashlightCommand(action: FlashlightAction.on);
    }

    // Turn off flashlight
    if (RegExp(r'^\s*turn\s+off\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+flashlight\s*$').hasMatch(lower) ||
        RegExp(r'^\s*flashlight\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+flashlight\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._flashlightTarget() exiting with match: flashlight off');
      return FlashlightCommand(action: FlashlightAction.off);
    }

    print('DIAG: CommandParser._flashlightTarget() exiting: no match');
    return null;
  }

  ScreenshotCommand? _screenshotTarget(String input) {
    print('DIAG: CommandParser._screenshotTarget() entered with input: $input');
    final lower = input.toLowerCase();

    // Screenshot commands
    if (RegExp(r'^\s*take\s+a\s+screenshot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*screenshot\s*$').hasMatch(lower) ||
        RegExp(r'^\s*capture\s+my\s+screen\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._screenshotTarget() exiting with match: screenshot');
      return ScreenshotCommand();
    }

    print('DIAG: CommandParser._screenshotTarget() exiting: no match');
    return null;
  }

  String? _callTarget(String input) {
    print('DIAG: CommandParser._callTarget() entered with input: $input');
    for (final pattern in _callPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final trimmed = _trimTerminalPunctuation(match.group(1)!);
        print('DIAG: CommandParser._callTarget() exiting with match: $trimmed');
        return trimmed;
      }
    }
    if (_callWithoutTarget.hasMatch(input)) {
      print('DIAG: CommandParser._callTarget() exiting: call without target');
      return '';
    }
    print('DIAG: CommandParser._callTarget() exiting: no match');
    return null;
  }

  BluetoothAction? _bluetoothTarget(String input) {
    print('DIAG: CommandParser._bluetoothTarget() entered with input: $input');
    final lower = input.toLowerCase();
    // Patterns for enabling Bluetooth
    if (RegExp(r'^\s*turn\s+on\s+bluetooth\s*$').hasMatch(lower) ||
        RegExp(r'^\s*enable\s+bluetooth\s*$').hasMatch(lower) ||
        RegExp(r'^\s*bluetooth\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+on\s+bluetooth\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._bluetoothTarget() exiting with match: enable');
      return BluetoothAction.enable;
    }
    // Patterns for disabling Bluetooth
    if (RegExp(r'^\s*turn\s+off\s+bluetooth\s*$').hasMatch(lower) ||
        RegExp(r'^\s*disable\s+bluetooth\s*$').hasMatch(lower) ||
        RegExp(r'^\s*bluetooth\s+off\s*$').hasMatch(lower) ||
        RegExp(r'^\s*switch\s+off\s+bluetooth\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._bluetoothTarget() exiting with match: disable');
      return BluetoothAction.disable;
    }
    // Patterns for getting status
    if (RegExp(r'^\s*bluetooth\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*get\s+bluetooth\s+status\s*$').hasMatch(lower) ||
        RegExp(r'^\s*is\s+bluetooth\s+on\s*$').hasMatch(lower) ||
        RegExp(r'^\s*bluetooth\s+state\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._bluetoothTarget() exiting with match: status');
      return BluetoothAction.getStatus;
    }
    // Patterns for listing devices
    if (RegExp(r'^\s*list\s+bluetooth\s+devices\s*$').hasMatch(lower) ||
        RegExp(r'^\s*bluetooth\s+devices\s*$').hasMatch(lower) ||
        RegExp(r'^\s*show\s+bluetooth\s+devices\s*$').hasMatch(lower)) {
      print('DIAG: CommandParser._bluetoothTarget() exiting with match: listDevices');
      return BluetoothAction.listDevices;
    }
    print('DIAG: CommandParser._bluetoothTarget() exiting: no match');
    return null;
  }

  String _trimTerminalPunctuation(String value) =>
      value.trim().replaceFirst(RegExp(r'[.!?]+$'), '').trim();

  Object? _whatsappVideoCallTargetWithValidation(String input) {
    // Pattern 1: "whatsapp video call <contact>"
    final RegExp pattern1 = RegExp(r'^\s*whatsapp\s+video\s+call\s+(.+?)\s*$', caseSensitive: false);
    // Pattern 2: "video call <contact> on whatsapp"
    final RegExp pattern2 = RegExp(r'^\s*video\s+call\s+(.*?)\s*on\s+whatsapp\s*$', caseSensitive: false);

    final match1 = pattern1.firstMatch(input);
    if (match1 != null) {
      final contactQuery = _trimTerminalPunctuation(match1.group(1)!);
      if (contactQuery.isEmpty) {
        return _invalidWhatsAppMarker;
      }
      return WhatsAppVideoCallCommand(contactQuery: contactQuery);
    }

    final match2 = pattern2.firstMatch(input);
    if (match2 != null) {
      final contactQuery = _trimTerminalPunctuation(match2.group(1)!);
      if (contactQuery.isEmpty) {
        return _invalidWhatsAppMarker;
      }
      return WhatsAppVideoCallCommand(contactQuery: contactQuery);
    }

    return null;
  }

  Object? _whatsappAudioCallTargetWithValidation(String input) {
    // Pattern 1: "whatsapp call <contact>"
    final RegExp pattern1 = RegExp(r'^\s*whatsapp\s+call\s+(.+?)\s*$', caseSensitive: false);
    // Pattern 2: "call <contact> on whatsapp"
    final RegExp pattern2 = RegExp(r'^\s*call\s+(.*?)\s*on\s+whatsapp\s*$', caseSensitive: false);

    final match1 = pattern1.firstMatch(input);
    if (match1 != null) {
      final contactQuery = _trimTerminalPunctuation(match1.group(1)!);
      if (contactQuery.isEmpty) {
        return _invalidWhatsAppMarker;
      }
      return WhatsAppAudioCallCommand(contactQuery: contactQuery);
    }

    final match2 = pattern2.firstMatch(input);
    if (match2 != null) {
      final contactQuery = _trimTerminalPunctuation(match2.group(1)!);
      if (contactQuery.isEmpty) {
        return _invalidWhatsAppMarker;
      }
      return WhatsAppAudioCallCommand(contactQuery: contactQuery);
    }

    return null;
  }

  Object? _whatsappMessageTargetWithValidation(String input) {
    // Pattern 1: "whatsapp <contact> saying <message>"
    final RegExp pattern1 = RegExp(r'^\s*whatsapp\s+(.+?)\s*saying\s+(.+?)\s*$', caseSensitive: false);
    // Pattern 2: "send <contact> a whatsapp saying <message>"
    final RegExp pattern2 = RegExp(r'^\s*send\s+(.+?)\s*a\s+whatsapp\s*saying\s+(.+?)\s*$', caseSensitive: false);

    final match1 = pattern1.firstMatch(input);
    if (match1 != null) {
        final contactQuery = _trimTerminalPunctuation(match1.group(1)!);
        final messageQuery = _trimTerminalPunctuation(match1.group(2)!);
        if (contactQuery.isEmpty || messageQuery.isEmpty) {
          return _invalidWhatsAppMarker;
        }
        return WhatsAppMessageCommand(contactQuery: contactQuery, message: messageQuery);
    }

    final match2 = pattern2.firstMatch(input);
    if (match2 != null) {
        final contactQuery = _trimTerminalPunctuation(match2.group(1)!);
        final messageQuery = _trimTerminalPunctuation(match2.group(2)!);
        if (contactQuery.isEmpty || messageQuery.isEmpty) {
          return _invalidWhatsAppMarker;
        }
        return WhatsAppMessageCommand(contactQuery: contactQuery, message: messageQuery);
    }

    return null;
  }
}