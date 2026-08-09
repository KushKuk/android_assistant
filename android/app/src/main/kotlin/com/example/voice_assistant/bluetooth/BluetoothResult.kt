package com.example.voice_assistant.bluetooth

/**
 * Result class for Bluetooth status operations.
 */
data class BluetoothStatusResult(
    val status: String, // "enabled", "disabled", "unavailable", "permissionRequired"
    val message: String? = null
) {
    fun toMap(): Map<String, Any> {
        val map = hashMapOf<String, Any>()
        map["status"] = status
        map["message"] = message ?: ""
        return map
    }
}

/**
 * Result class for Bluetooth action operations (enable/disable/connect/disconnect).
 */
data class BluetoothActionResult(
    val status: String, // "success", "failure", "permissionRequired", "userActionRequired", "unsupported"
    val message: String? = null
) {
    fun toMap(): Map<String, Any> {
        val map = hashMapOf<String, Any>()
        map["status"] = status
        map["message"] = message ?: ""
        return map
    }
}

/**
 * Result class for Bluetooth device list operations.
 */
data class BluetoothDeviceListResult(
    val devices: List<BluetoothDeviceInfo>,
    val message: String
) {
    fun toMap(): Map<String, Any> {
        val map = hashMapOf<String, Any>()
        map["devices"] = devices.map { it.toMap() }
        map["message"] = message
        return map
    }
}