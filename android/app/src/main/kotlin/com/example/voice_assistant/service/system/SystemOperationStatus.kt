package com.example.voice_assistant.service.system

/** Enum representing the status of a system operation. */
enum class SystemOperationStatus {
    SUCCESS,
    PERMISSION_REQUIRED,
    USER_ACTION_REQUIRED,
    UNSUPPORTED,
    DENIED,
    FAILED
}