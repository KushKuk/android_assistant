package com.example.voice_assistant.connectivity

/**
 * Result class for mobile data status operations.
 */
data class MobileDataStatusResult(
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