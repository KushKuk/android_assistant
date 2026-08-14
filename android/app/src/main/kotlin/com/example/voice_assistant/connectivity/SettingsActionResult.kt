package com.example.voice_assistant.connectivity

/**
 * Result class for settings action operations (open settings).
 */
data class SettingsActionResult(
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