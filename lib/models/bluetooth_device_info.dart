class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.bondState,
    required this.connectionState,
    this.deviceClass,
  });

  final String name;
  final String address; // MAC address
  final BluetoothBondState bondState;
  final BluetoothConnectionState connectionState;
  final int? deviceClass; // Android Bluetooth Class, optional

  factory BluetoothDeviceInfo.fromMap(Map<String, dynamic> map) {
    return BluetoothDeviceInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      bondState: BluetoothBondState.fromName(map['bondState'] ?? 'none'),
      connectionState: BluetoothConnectionState.fromName(
          map['connectionState'] ?? 'disconnected'),
      deviceClass: map['deviceClass'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'bondState': bondState.name,
      'connectionState': connectionState.name,
      'deviceClass': deviceClass,
    };
  }
}

enum BluetoothBondState {
  none('none'),
  bonding('bonding'),
  bonded('bonded');

  final String name;

  const BluetoothBondState(this.name);

  static BluetoothBondState fromName(String name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => none,
    );
  }
}

enum BluetoothConnectionState {
  disconnected('disconnected'),
  connecting('connecting'),
  connected('connected'),
  disconnecting('disconnecting');

  final String name;

  const BluetoothConnectionState(this.name);

  static BluetoothConnectionState fromName(String name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => disconnected,
    );
  }
}

enum BluetoothAction {
  getStatus,
  enable,
  disable,
  listDevices,
  connect,
  disconnect,
}

class BluetoothCommand {
  const BluetoothCommand({
    required this.action,
    this.deviceQuery,
    this.deviceAddress,
  });

  final BluetoothAction action;
  final String? deviceQuery; // For resolving devices by name
  final String? deviceAddress; // For direct address specification

  bool get isGetStatus => action == BluetoothAction.getStatus;
  bool get isEnable => action == BluetoothAction.enable;
  bool get isDisable => action == BluetoothAction.disable;
  bool get isListDevices => action == BluetoothAction.listDevices;
  bool get isConnect => action == BluetoothAction.connect;
  bool get isDisconnect => action == BluetoothAction.disconnect;
}