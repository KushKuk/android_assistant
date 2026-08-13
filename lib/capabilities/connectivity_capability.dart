import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:flutter/services.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';

/// Capability for handling ConnectivityCommand execution.
///
/// This capability encapsulates connectivity control logic and delegates
/// to the AssistantPlatform for actual implementation.
class ConnectivityCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  ConnectivityCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    print('DIAG: ConnectivityCapability.canHandle() called with command: $command');
    final result = command is ConnectivityCommand;
    print('DIAG: ConnectivityCapability.canHandle() returning: $result');
    return result;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    print('DIAG: ConnectivityCapability.execute() called with command: $command');
    if (!canHandle(command)) {
      print('DIAG: ConnectivityCapability cannot handle command: $command');
      return ExecutionResult.invalidArguments(
          'ConnectivityCapability can only handle ConnectivityCommand');
    }

    final connectivityCommand = command as ConnectivityCommand;
    print('DIAG: ConnectivityCapability about to execute _executeConnectivityCommand');
    final result = await _executeConnectivityCommand(connectivityCommand);
    print('DIAG: ConnectivityCapability._executeConnectivityCommand returned: $result');
    return result;
  }

  Future<ExecutionResult> _executeConnectivityCommand(
      ConnectivityCommand command) async {
    print('DIAG: ConnectivityCapability._executeConnectivityCommand() entered with command: $command');
    try {
      if (command.isGetStatus) {
        print('DIAG: ConnectivityCapability handling getStatus for ${command.type}');
        return await _handleGetStatus(command.type);
      } else if (command.isEnable) {
        print('DIAG: ConnectivityCapability handling enable for ${command.type}');
        return await _handleEnable(command.type);
      } else if (command.isDisable) {
        print('DIAG: ConnectivityCapability handling disable for ${command.type}');
        return await _handleDisable(command.type);
      } else if (command.isOpenSettings) {
        print('DIAG: ConnectivityCapability handling openSettings for ${command.type}');
        return await _handleOpenSettings(command.type);
      } else {
        print('DIAG: ConnectivityCapability unsupported action: ${command.action}');
        return ExecutionResult.unsupported(
            'Unsupported Connectivity action: ${command.action}');
      }
    } catch (e) {
      print('DIAG: ConnectivityCapability._executeConnectivityCommand caught exception: $e');
      return ExecutionResult.failure('Connectivity execution failed: $e');
    }
  }

  Future<ExecutionResult> _handleGetStatus(ConnectivityType type) async {
    print('DIAG: ConnectivityCapability._handleGetStatus() entered for type: $type');
    switch (type) {
      case ConnectivityType.wifi:
        final result = await _platform.getWifiStatus();
        final converted = _convertWifiStatusResult(result);
        print('DIAG: ConnectivityCapability._handleGetStatus returning: $converted');
        return converted;
      case ConnectivityType.mobileData:
        final result = await _platform.getMobileDataStatus();
        final converted = _convertMobileDataStatusResult(result);
        print('DIAG: ConnectivityCapability._handleGetStatus returning: $converted');
        return converted;
      case ConnectivityType.hotspot:
        final result = await _platform.getHotspotStatus();
        final converted = _convertHotspotStatusResult(result);
        print('DIAG: ConnectivityCapability._handleGetStatus returning: $converted');
        return converted;
    }
  }

  Future<ExecutionResult> _handleEnable(ConnectivityType type) async {
    print('DIAG: ConnectivityCapability._handleEnable() entered for type: $type');
    switch (type) {
      case ConnectivityType.wifi:
        final result = await _platform.setWifiEnabled(true);
        final converted = _convertWifiActionResult(result);
        print('DIAG: ConnectivityCapability._handleEnable returning: $converted');
        return converted;
      case ConnectivityType.mobileData:
        final result = await _platform.setMobileDataEnabled(true);
        final converted = _convertMobileDataActionResult(result);
        print('DIAG: ConnectivityCapability._handleEnable returning: $converted');
        return converted;
      case ConnectivityType.hotspot:
        final result = await _platform.setHotspotEnabled(true);
        final converted = _convertHotspotActionResult(result);
        print('DIAG: ConnectivityCapability._handleEnable returning: $converted');
        return converted;
    }
  }

  Future<ExecutionResult> _handleDisable(ConnectivityType type) async {
    print('DIAG: ConnectivityCapability._handleDisable() entered for type: $type');
    switch (type) {
      case ConnectivityType.wifi:
        final result = await _platform.setWifiEnabled(false);
        final converted = _convertWifiActionResult(result);
        print('DIAG: ConnectivityCapability._handleDisable returning: $converted');
        return converted;
      case ConnectivityType.mobileData:
        final result = await _platform.setMobileDataEnabled(false);
        final converted = _convertMobileDataActionResult(result);
        print('DIAG: ConnectivityCapability._handleDisable returning: $converted');
        return converted;
      case ConnectivityType.hotspot:
        final result = await _platform.setHotspotEnabled(false);
        final converted = _convertHotspotActionResult(result);
        print('DIAG: ConnectivityCapability._handleDisable returning: $converted');
        return converted;
    }
  }

  Future<ExecutionResult> _handleOpenSettings(ConnectivityType type) async {
    print('DIAG: ConnectivityCapability._handleOpenSettings() entered for type: $type');
    switch (type) {
      case ConnectivityType.wifi:
        final result = await _platform.openWifiSettings();
        final converted = _convertSettingsResult(result);
        print('DIAG: ConnectivityCapability._handleOpenSettings returning: $converted');
        return converted;
      case ConnectivityType.mobileData:
        final result = await _platform.openMobileDataSettings();
        final converted = _convertSettingsResult(result);
        print('DIAG: ConnectivityCapability._handleOpenSettings returning: $converted');
        return converted;
      case ConnectivityType.hotspot:
        final result = await _platform.openHotspotSettings();
        final converted = _convertSettingsResult(result);
        print('DIAG: ConnectivityCapability._handleOpenSettings returning: $converted');
        return converted;
    }
  }

  ExecutionResult _convertWifiStatusResult(WifiStatusResult result) {
    print('DIAG: ConnectivityCapability._convertWifiStatusResult() entered with result: $result');
    switch (result.status) {
      case WifiStatus.enabled:
        print('DIAG: ConnectivityCapability._convertWifiStatusResult returning success for enabled');
        return ExecutionResult.success(data: result);
      case WifiStatus.disabled:
        print('DIAG: ConnectivityCapability._convertWifiStatusResult returning success for disabled');
        return ExecutionResult.success(data: result);
      case WifiStatus.unavailable:
        print('DIAG: ConnectivityCapability._convertWifiStatusResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Wi-Fi unavailable');
      case WifiStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertWifiStatusResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Wi-Fi permission required');
    }
  }

  ExecutionResult _convertMobileDataStatusResult(MobileDataStatusResult result) {
    print('DIAG: ConnectivityCapability._convertMobileDataStatusResult() entered with result: $result');
    switch (result.status) {
      case MobileDataStatus.enabled:
        print('DIAG: ConnectivityCapability._convertMobileDataStatusResult returning success for enabled');
        return ExecutionResult.success(data: result);
      case MobileDataStatus.disabled:
        print('DIAG: ConnectivityCapability._convertMobileDataStatusResult returning success for disabled');
        return ExecutionResult.success(data: result);
      case MobileDataStatus.unavailable:
        print('DIAG: ConnectivityCapability._convertMobileDataStatusResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Mobile data unavailable');
      case MobileDataStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertMobileDataStatusResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Mobile data permission required');
      case MobileDataStatus.restricted:
        print('DIAG: ConnectivityCapability._convertMobileDataStatusResult returning userActionRequired for restricted');
        return ExecutionResult.userActionRequired(
            result.message ?? 'Mobile data restricted - user action required',
            data: result);
    }
  }

  ExecutionResult _convertHotspotStatusResult(HotspotStatusResult result) {
    print('DIAG: ConnectivityCapability._convertHotspotStatusResult() entered with result: $result');
    switch (result.status) {
      case HotspotStatus.enabled:
        print('DIAG: ConnectivityCapability._convertHotspotStatusResult returning success for enabled');
        return ExecutionResult.success(data: result);
      case HotspotStatus.disabled:
        print('DIAG: ConnectivityCapability._convertHotspotStatusResult returning success for disabled');
        return ExecutionResult.success(data: result);
      case HotspotStatus.unavailable:
        print('DIAG: ConnectivityCapability._convertHotspotStatusResult returning unavailable');
        return ExecutionResult.unavailable(result.message ?? 'Hotspot unavailable');
      case HotspotStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertHotspotStatusResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Hotspot permission required');
      case HotspotStatus.configureRequired:
        print('DIAG: ConnectivityCapability._convertHotspotStatusResult returning userActionRequired for configuration required');
        return ExecutionResult.userActionRequired(
            result.message ?? 'Hotspot requires configuration - user action required',
            data: result);
    }
  }

  ExecutionResult _convertWifiActionResult(WifiActionResult result) {
    print('DIAG: ConnectivityCapability._convertWifiActionResult() entered with result: $result');
    switch (result.status) {
      case WifiActionStatus.success:
        print('DIAG: ConnectivityCapability._convertWifiActionResult returning success');
        return ExecutionResult.success(data: result);
      case WifiActionStatus.failure:
        print('DIAG: ConnectivityCapability._convertWifiActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Wi-Fi action failed');
      case WifiActionStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertWifiActionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Wi-Fi permission required');
      case WifiActionStatus.userActionRequired:
        print('DIAG: ConnectivityCapability._convertWifiActionResult returning userActionRequired');
        return ExecutionResult.userActionRequired(
            result.message ?? 'User action required for Wi-Fi',
            data: result);
      case WifiActionStatus.unsupported:
        print('DIAG: ConnectivityCapability._convertWifiActionResult returning unsupported');
        return ExecutionResult.unsupported(
            result.message ?? 'Wi-Fi not supported on this platform');
    }
  }

  ExecutionResult _convertMobileDataActionResult(MobileDataActionResult result) {
    print('DIAG: ConnectivityCapability._convertMobileDataActionResult() entered with result: $result');
    switch (result.status) {
      case MobileDataActionStatus.success:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResult returning success');
        return ExecutionResult.success(data: result);
      case MobileDataActionStatus.failure:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Mobile data action failed');
      case MobileDataActionStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Mobile data permission required');
      case MobileDataActionStatus.userActionRequired:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResult returning userActionRequired');
        return ExecutionResult.userActionRequired(
            result.message ?? 'User action required for mobile data',
            data: result);
      case MobileDataActionStatus.unsupported:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResult returning unsupported');
        return ExecutionResult.unsupported(
            result.message ?? 'Mobile data control not supported on this platform');
    }
  }

  ExecutionResult _convertHotspotActionResult(HotspotActionResult result) {
    print('DIAG: ConnectivityCapability._convertHotspotActionResult() entered with result: $result');
    switch (result.status) {
      case HotspotActionStatus.success:
        print('DIAG: ConnectivityCapability._convertHotspotActionResult returning success');
        return ExecutionResult.success(data: result);
      case HotspotActionStatus.failure:
        print('DIAG: ConnectivityCapability._convertHotspotActionResult returning failure');
        return ExecutionResult.failure(result.message ?? 'Hotspot action failed');
      case HotspotActionStatus.permissionRequired:
        print('DIAG: ConnectivityCapability._convertHotspotActionResult returning permissionRequired');
        return ExecutionResult.permissionRequired(
            result.message ?? 'Hotspot permission required');
      case HotspotActionStatus.userActionRequired:
        print('DIAG: ConnectivityCapability._convertHotspotActionResult returning userActionRequired');
        return ExecutionResult.userActionRequired(
            result.message ?? 'User action required for hotspot',
            data: result);
      case HotspotActionStatus.unsupported:
        print('DIAG: ConnectivityCapability._convertHotspotActionResult returning unsupported');
        return ExecutionResult.unsupported(
            result.message ?? 'Hotspot control not supported on this platform');
    }
  }

  ExecutionResult _convertSettingsResult(SettingsActionResult result) {
    print('DIAG: ConnectivityCapability._convertSettingsResult() entered with result: $result');
    if (result.status == SettingsActionStatus.success) {
      print('DIAG: ConnectivityCapability._convertSettingsResult returning success');
      return ExecutionResult.success(data: result);
    } else {
      print('DIAG: ConnectivityCapability._convertSettingsResult returning failure');
      return ExecutionResult.failure(
          result.message ?? 'Failed to open settings');
    }
  }
}