import 'package:voice_assistant/models/bluetooth_device_info.dart';

enum BluetoothStatus {
  enabled,
  disabled,
  unavailable,
  permissionRequired,
}

class BluetoothStatusResult {
  const BluetoothStatusResult({
    required this.status,
    this.message,
  });

  final BluetoothStatus status;
  final String? message;

  factory BluetoothStatusResult.fromMap(Map<String, dynamic> map) {
    return BluetoothStatusResult(
      status: BluetoothStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'message': message,
    };
  }
}

enum BluetoothActionStatus {
  success,
  failure,
  permissionRequired,
  userActionRequired,
  unsupported,
}

class BluetoothActionResult {
  const BluetoothActionResult({
    required this.status,
    this.message,
  });

  final BluetoothActionStatus status;
  final String? message;

  bool get isSuccess => status == BluetoothActionStatus.success;
  bool get isFailure => status == BluetoothActionStatus.failure;
  bool get isPermissionRequired => status == BluetoothActionStatus.permissionRequired;
  bool get isUserActionRequired => status == BluetoothActionStatus.userActionRequired;
  bool get isUnsupported => status == BluetoothActionStatus.unsupported;

  factory BluetoothActionResult.fromMap(Map<String, dynamic> map) {
    return BluetoothActionResult(
      status: BluetoothActionStatus.values.byName(map['status'] as String),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'message': message,
    };
  }
}

class BluetoothDeviceListResult {
  const BluetoothDeviceListResult({
    required this.devices,
    required this.message,
  });

  final List<BluetoothDeviceInfo> devices;
  final String message;

  factory BluetoothDeviceListResult.fromMap(Map<String, dynamic> map) {
    final List<dynamic> devicesList = map['devices'] ?? [];
    final List<BluetoothDeviceInfo> devices = devicesList
        .map((e) => BluetoothDeviceInfo.fromMap(e as Map<String, dynamic>))
        .toList();

    return BluetoothDeviceListResult(
      devices: devices,
      message: map['message'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'devices': devices.map((e) => e.toMap()).toList(),
      'message': message,
    };
  }
}