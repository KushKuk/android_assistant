import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/models/wifi_result.dart';
import 'package:voice_assistant/models/mobile_data_result.dart';
import 'package:voice_assistant/models/hotspot_result.dart';
import 'package:voice_assistant/models/settings_result.dart';
import 'dart:convert';

/// Capability for handling ConnectivityCommand execution.
///
/// This capability encapsulates connectivity control logic and delegates
/// to the AssistantPlatform for actual implementation.
class ConnectivityCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  ConnectivityCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    return command is ConnectivityCommand;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    if (!canHandle(command)) {
      return ExecutionResult.invalidArguments(
          'ConnectivityCapability can only handle ConnectivityCommand');
    }

    final connectivityCommand = command as ConnectivityCommand;
    return await _executeConnectivityCommand(connectivityCommand);
  }

  Future<ExecutionResult> _executeConnectivityCommand(
      ConnectivityCommand command) async {
    print('DIAG: ConnectivityCapability._executeConnectivityCommand() entered with command: $command');
    try {
      String operation = '';
      String action = '';

      // Map connectivity command to system operation
      if (command.type == ConnectivityType.wifi) {
        if (command.isGetStatus) {
          operation = "wifi.status";
          action = "get";
        } else if (command.isEnable) {
          operation = "wifi.enable";
          action = "set";
        } else if (command.isDisable) {
          operation = "wifi.disable";
          action = "set";
        } else if (command.isOpenSettings) {
          // For opening settings, we'll keep using the existing platform method
          // as it's simpler and doesn't require Binder complexity for this use case
          print('DIAG: ConnectivityCapability handling openSettings for ${command.type}');
          return await _handleOpenSettings(command.type);
        }
      } else if (command.type == ConnectivityType.mobileData) {
        if (command.isGetStatus) {
          operation = "mobiledata.status";
          action = "get";
        } else if (command.isEnable) {
          operation = "mobiledata.enable";
          action = "set";
        } else if (command.isDisable) {
          operation = "mobiledata.disable";
          action = "set";
        } else if (command.isOpenSettings) {
          // For opening settings, we'll keep using the existing platform method
          print('DIAG: ConnectivityCapability handling openSettings for ${command.type}');
          return await _handleOpenSettings(command.type);
        }
      } else if (command.type == ConnectivityType.hotspot) {
        if (command.isGetStatus) {
          operation = "hotspot.status";
          action = "get";
        } else if (command.isEnable) {
          operation = "hotspot.enable";
          action = "set";
        } else if (command.isDisable) {
          operation = "hotspot.disable";
          action = "set";
        } else if (command.isOpenSettings) {
          // For opening settings, we'll keep using the existing platform method
          print('DIAG: ConnectivityCapability handling openSettings for ${command.type}');
          return await _handleOpenSettings(command.type);
        }
      } else {
        print('DIAG: ConnectivityCapability unsupported connectivity type: ${command.type}');
        return ExecutionResult.unsupported(
            'Unsupported Connectivity type: ${command.type}');
      }

      // Execute the operation through Binder IPC
      print('DIAG: ConnectivityCapability executing system operation: $operation, action: $action');
      final resultJson = await _platform.executeSystemOperation(
        operation,
        action,
        args: {}, // No additional args needed for these operations
      );

      if (resultJson == null) {
        return ExecutionResult.failure('System operation returned null result');
      }

      // Parse the JSON result and convert to appropriate ExecutionResult
      try {
        final resultMap = jsonDecode(resultJson) as Map<String, dynamic>;
        final status = resultMap['status'] as String?;
        final message = resultMap['message'] as String?;
        final requiresUserAction = resultMap['requiresUserAction'] as bool? ?? false;
        final silent = resultMap['silent'] as bool? ?? true;

        // Convert based on operation type and status
        switch (operation) {
          case "wifi.status":
            return _convertWifiStatusResultFromSystem(resultMap);
          case "wifi.enable":
          case "wifi.disable":
            return _convertWifiActionResultFromSystem(resultMap);
          case "mobiledata.status":
            return _convertMobileDataStatusResultFromSystem(resultMap);
          case "mobiledata.enable":
          case "mobiledata.disable":
            return _convertMobileDataActionResultFromSystem(resultMap);
          case "hotspot.status":
            return _convertHotspotStatusResultFromSystem(resultMap);
          case "hotspot.enable":
          case "hotspot.disable":
            return _convertHotspotActionResultFromSystem(resultMap);
          default:
            return ExecutionResult.failure('Unknown operation: $operation');
        }
      } catch (e) {
        print('DIAG: ConnectivityCapability failed to parse system operation result: $e');
        return ExecutionResult.failure('Failed to parse system operation result: $e');
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

  // Conversion methods for system operation results
  ExecutionResult _convertWifiStatusResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertWifiStatusResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    WifiStatus wifiStatus;
    switch (status.toLowerCase()) {
      case 'enabled':
        wifiStatus = WifiStatus.enabled;
        break;
      case 'disabled':
        wifiStatus = WifiStatus.disabled;
        break;
      case 'unavailable':
        wifiStatus = WifiStatus.unavailable;
        break;
      case 'permissionrequired':
        wifiStatus = WifiStatus.permissionRequired;
        break;
      default:
        wifiStatus = WifiStatus.unavailable;
    }

    final result = WifiStatusResult(
      status: wifiStatus,
      message: message,
    );

    // Determine if this requires user action or is an error
    if (status.toLowerCase() == 'permissionrequired') {
      print('DIAG: ConnectivityCapability._convertWifiStatusResultFromSystem returning permissionRequired');
      return ExecutionResult.permissionRequired(message ?? 'Wi-Fi permission required');
    } else if (status.toLowerCase() == 'unavailable' || status.toLowerCase() == 'failed') {
      print('DIAG: ConnectivityCapability._convertWifiStatusResultFromSystem returning unavailable/failed');
      return ExecutionResult.unavailable(message ?? 'Wi-Fi unavailable');
    } else {
      print('DIAG: ConnectivityCapability._convertWifiStatusResultFromSystem returning success');
      return ExecutionResult.success(data: result);
    }
  }

  ExecutionResult _convertWifiActionResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    switch (status.toLowerCase()) {
      case 'success':
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning success');
        final result = WifiActionResult(
          status: WifiActionStatus.success,
          message: message,
        );
        return ExecutionResult.success(data: result);
      case 'failure':
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning failure');
        return ExecutionResult.failure(message ?? 'Wi-Fi action failed');
      case 'permissionrequired':
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning permissionRequired');
        return ExecutionResult.permissionRequired(message ?? 'Wi-Fi permission required');
      case 'useractionrequired':
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning userActionRequired');
        final result = WifiActionResult(
          status: WifiActionStatus.userActionRequired,
          message: message,
        );
        return ExecutionResult.userActionRequired(
          message ?? 'User action required for Wi-Fi',
          data: result,
        );
      case 'unsupported':
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning unsupported');
        return ExecutionResult.unsupported(message ?? 'Wi-Fi not supported on this platform');
      default:
        print('DIAG: ConnectivityCapability._convertWifiActionResultFromSystem returning failure for unknown status: $status');
        return ExecutionResult.failure('Unknown Wi-Fi action status: $status');
    }
  }

  ExecutionResult _convertMobileDataStatusResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertMobileDataStatusResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    MobileDataStatus mobileDataStatus;
    switch (status.toLowerCase()) {
      case 'enabled':
        mobileDataStatus = MobileDataStatus.enabled;
        break;
      case 'disabled':
        mobileDataStatus = MobileDataStatus.disabled;
        break;
      case 'unavailable':
        mobileDataStatus = MobileDataStatus.unavailable;
        break;
      case 'permissionrequired':
        mobileDataStatus = MobileDataStatus.permissionRequired;
        break;
      default:
        mobileDataStatus = MobileDataStatus.unavailable;
    }

    final result = MobileDataStatusResult(
      status: mobileDataStatus,
      message: message,
    );

    // Determine if this requires user action or is an error
    if (status.toLowerCase() == 'permissionrequired') {
      print('DIAG: ConnectivityCapability._convertMobileDataStatusResultFromSystem returning permissionRequired');
      return ExecutionResult.permissionRequired(message ?? 'Mobile data permission required');
    } else if (status.toLowerCase() == 'unavailable' || status.toLowerCase() == 'failed') {
      print('DIAG: ConnectivityCapability._convertMobileDataStatusResultFromSystem returning unavailable/failed');
      return ExecutionResult.unavailable(message ?? 'Mobile data unavailable');
    } else {
      print('DIAG: ConnectivityCapability._convertMobileDataStatusResultFromSystem returning success');
      return ExecutionResult.success(data: result);
    }
  }

  ExecutionResult _convertMobileDataActionResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    switch (status.toLowerCase()) {
      case 'success':
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning success');
        final result = MobileDataActionResult(
          status: MobileDataActionStatus.success,
          message: message,
        );
        return ExecutionResult.success(data: result);
      case 'failure':
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning failure');
        return ExecutionResult.failure(message ?? 'Mobile data action failed');
      case 'permissionrequired':
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning permissionRequired');
        return ExecutionResult.permissionRequired(message ?? 'Mobile data permission required');
      case 'useractionrequired':
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning userActionRequired');
        final result = MobileDataActionResult(
          status: MobileDataActionStatus.userActionRequired,
          message: message,
        );
        return ExecutionResult.userActionRequired(
          message ?? 'User action required for mobile data',
          data: result,
        );
      case 'unsupported':
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning unsupported');
        return ExecutionResult.unsupported(message ?? 'Mobile data control not supported on this platform');
      default:
        print('DIAG: ConnectivityCapability._convertMobileDataActionResultFromSystem returning failure for unknown status: $status');
        return ExecutionResult.failure('Unknown mobile data action status: $status');
    }
  }

  ExecutionResult _convertHotspotStatusResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertHotspotStatusResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    HotspotStatus hotspotStatus;
    switch (status.toLowerCase()) {
      case 'enabled':
        hotspotStatus = HotspotStatus.enabled;
        break;
      case 'disabled':
        hotspotStatus = HotspotStatus.disabled;
        break;
      case 'unavailable':
        hotspotStatus = HotspotStatus.unavailable;
        break;
      case 'permissionrequired':
        hotspotStatus = HotspotStatus.permissionRequired;
        break;
      case 'configurerequired':
        hotspotStatus = HotspotStatus.configureRequired;
        break;
      default:
        hotspotStatus = HotspotStatus.unavailable;
    }

    final result = HotspotStatusResult(
      status: hotspotStatus,
      message: message,
    );

    // Determine if this requires user action or is an error
    if (status.toLowerCase() == 'permissionrequired') {
      print('DIAG: ConnectivityCapability._convertHotspotStatusResultFromSystem returning permissionRequired');
      return ExecutionResult.permissionRequired(message ?? 'Hotspot permission required');
    } else if (status.toLowerCase() == 'unavailable' || status.toLowerCase() == 'failed') {
      print('DIAG: ConnectivityCapability._convertHotspotStatusResultFromSystem returning unavailable/failed');
      return ExecutionResult.unavailable(message ?? 'Hotspot unavailable');
    } else if (status.toLowerCase() == 'configurerequired') {
      print('DIAG: ConnectivityCapability._convertHotspotStatusResultFromSystem returning userActionRequired for configureRequired');
      final result = HotspotStatusResult(
        status: HotspotStatus.configureRequired,
        message: message,
      );
      return ExecutionResult.userActionRequired(
        message ?? 'Hotspot requires configuration - user action required',
        data: result,
      );
    } else {
      print('DIAG: ConnectivityCapability._convertHotspotStatusResultFromSystem returning success');
      return ExecutionResult.success(data: result);
    }
  }

  ExecutionResult _convertHotspotActionResultFromSystem(Map<String, dynamic> resultMap) {
    print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem() entered with result: $resultMap');
    final status = resultMap['status'] as String;
    final message = resultMap['message'] as String?;

    switch (status.toLowerCase()) {
      case 'success':
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning success');
        final result = HotspotActionResult(
          status: HotspotActionStatus.success,
          message: message,
        );
        return ExecutionResult.success(data: result);
      case 'failure':
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning failure');
        return ExecutionResult.failure(message ?? 'Hotspot action failed');
      case 'permissionrequired':
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning permissionRequired');
        return ExecutionResult.permissionRequired(message ?? 'Hotspot permission required');
      case 'useractionrequired':
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning userActionRequired');
        final result = HotspotActionResult(
          status: HotspotActionStatus.userActionRequired,
          message: message,
        );
        return ExecutionResult.userActionRequired(
          message ?? 'User action required for hotspot',
          data: result,
        );
      case 'unsupported':
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning unsupported');
        return ExecutionResult.unsupported(message ?? 'Hotspot control not supported on this platform');
      default:
        print('DIAG: ConnectivityCapability._convertHotspotActionResultFromSystem returning failure for unknown status: $status');
        return ExecutionResult.failure('Unknown hotspot action status: $status');
    }
  }
}