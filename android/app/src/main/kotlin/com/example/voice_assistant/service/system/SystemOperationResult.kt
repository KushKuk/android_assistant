package com.example.voice_assistant.service.system

/**
 * Result of a system operation execution.
 * Follows the pattern of existing result classes in the project.
 */
data class SystemOperationResult(
    val status: SystemOperationStatus,
    val operation: String,
    val message: String,
    val silent: Boolean = true,
    val requiresUserAction: Boolean = false
) {
    companion object {
        fun success(
            operation: String,
            message: String = "Operation completed successfully",
            silent: Boolean = true
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.SUCCESS,
                operation = operation,
                message = message,
                silent = silent,
                requiresUserAction = false
            )
        }

        fun permissionRequired(
            operation: String,
            message: String = "Permission required"
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.PERMISSION_REQUIRED,
                operation = operation,
                message = message,
                silent = false,
                requiresUserAction = true
            )
        }

        fun userActionRequired(
            operation: String,
            message: String = "User action required"
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.USER_ACTION_REQUIRED,
                operation = operation,
                message = message,
                silent = false,
                requiresUserAction = true
            )
        }

        fun unsupported(
            operation: String,
            message: String = "Operation not supported"
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.UNSUPPORTED,
                operation = operation,
                message = message,
                silent = true,
                requiresUserAction = false
            )
        }

        fun denied(
            operation: String,
            message: String = "Operation denied"
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.DENIED,
                operation = operation,
                message = message,
                silent = true,
                requiresUserAction = false
            )
        }

        fun failed(
            operation: String,
            message: String = "Operation failed"
        ): SystemOperationResult {
            return SystemOperationResult(
                status = SystemOperationStatus.FAILED,
                operation = operation,
                message = message,
                silent = true,
                requiresUserAction = false
            )
        }
    }
}