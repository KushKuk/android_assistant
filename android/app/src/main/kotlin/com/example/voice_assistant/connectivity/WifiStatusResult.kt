package com.example.voice_assistant.connectivity

/**
 * Result class for Wi-Fi status operations.
 */
data class WifiStatusResult(
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