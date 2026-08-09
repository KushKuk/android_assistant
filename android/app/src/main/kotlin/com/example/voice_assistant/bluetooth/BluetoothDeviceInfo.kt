package com.example.voice_assistant.bluetooth

import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice

/**
 * Data class representing Bluetooth device information safe for transfer over MethodChannel.
 */
data class BluetoothDeviceInfo(
    val name: String,
    val address: String,
    val bondState: Int,    // Android BluetoothDevice.BOND_* constants
    val connectionState: Int, // Custom connection state (we'll map this)
    val deviceClass: Int? = null // Android Bluetooth Class, optional
) {
    fun toMap(): Map<String, Any> {
        val map = hashMapOf<String, Any>()
        map["name"] = name
        map["address"] = address
        map["bondState"] = bondState
        map["connectionState"] = connectionState
        map["deviceClass"] = deviceClass ?: -1
        return map
    }
    companion object {
        /**
         * Creates a BluetoothDeviceInfo from an Android BluetoothDevice.
         * @param device The Android BluetoothDevice
         * @return BluetoothDeviceInfo safe for MethodChannel transfer
         */
        fun fromAndroidDevice(device: BluetoothDevice): BluetoothDeviceInfo {
            return BluetoothDeviceInfo(
                name = device.name ?: "Unknown Device",
                address = device.address,
                bondState = device.bondState,
                connectionState = getConnectionState(device),
                deviceClass = device.bluetoothClass?.getDeviceClass()
            )
        }

        private fun getConnectionState(device: BluetoothDevice): Int {
            // Note: Android doesn't provide a direct connection state API for all devices
            // We'll return a custom state based on what we can determine
            // For now, we'll rely on the bond state and assume disconnected if not bonded
            // In a more sophisticated implementation, we might check connection profiles
            return when (device.bondState) {
                android.bluetooth.BluetoothDevice.BOND_NONE -> 0 // Disconnected
                android.bluetooth.BluetoothDevice.BOND_BONDING -> 1 // Connecting
                android.bluetooth.BluetoothDevice.BOND_BONDED -> 2 // Connected (assuming bonded means connected for simplicity)
                else -> 0
            }
        }
    }
}