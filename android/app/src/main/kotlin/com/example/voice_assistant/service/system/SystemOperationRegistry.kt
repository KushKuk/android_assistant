package com.example.voice_assistant.service.system

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Registry for system operations that defines available operations and their properties.
 * This allows for extensible system operations without modifying the core service.
 */
class SystemOperationRegistry(private val context: Context) {

    /**
     * Definition of a system operation.
     */
    data class OperationDefinition(
        val id: String,
        val name: String,
        val description: String,
        val minSdkVersion: Int = Build.VERSION_CODES.BASE,
        val requiredPermissions: List<String> = emptyList(),
        val requiresUserActionNormally: Boolean = false,
        val hasStatusOperation: Boolean = false,
        val isReadOnly: Boolean = true
    )

    // Registry of known operations
    private val operations = mutableMapOf<String, OperationDefinition>()

    init {
        // Register the test operation
        registerOperation(
            OperationDefinition(
                id = "system.test",
                name = "System Test",
                description = "A harmless test operation to verify the system control framework",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = emptyList(),
                requiresUserActionNormally = false,
                hasStatusOperation = false,
                isReadOnly = true
            )
        )

        // Register Wi-Fi operations
        registerOperation(
            OperationDefinition(
                id = "wifi.status",
                name = "Wi-Fi Status",
                description = "Get the current Wi-Fi status",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.ACCESS_WIFI_STATE,
                    Manifest.permission.CHANGE_WIFI_STATE
                ),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = true
            )
        )
        registerOperation(
            OperationDefinition(
                id = "wifi.enable",
                name = "Enable Wi-Fi",
                description = "Enable Wi-Fi",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_WIFI_STATE
                ),
                requiresUserActionNormally = false,
                hasStatusOperation = false,
                isReadOnly = false
            )
        )
        registerOperation(
            OperationDefinition(
                id = "wifi.disable",
                name = "Disable Wi-Fi",
                description = "Disable Wi-Fi",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_WIFI_STATE
                ),
                requiresUserActionNormally = false,
                hasStatusOperation = false,
                isReadOnly = false
            )
        )

        // Register mobile data operations
        registerOperation(
            OperationDefinition(
                id = "mobiledata.status",
                name = "Mobile Data Status",
                description = "Get the current mobile data status",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.ACCESS_NETWORK_STATE,
                    Manifest.permission.READ_PHONE_STATE
                ),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = true
            )
        )
        registerOperation(
            OperationDefinition(
                id = "mobiledata.enable",
                name = "Enable Mobile Data",
                description = "Enable mobile data",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.MODIFY_PHONE_STATE
                ),
                requiresUserActionNormally = true, // Usually requires user action due to restrictions
                hasStatusOperation = false,
                isReadOnly = false
            )
        )
        registerOperation(
            OperationDefinition(
                id = "mobiledata.disable",
                name = "Disable Mobile Data",
                description = "Disable mobile data",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(
                    Manifest.permission.MODIFY_PHONE_STATE
                ),
                requiresUserActionNormally = true, // Usually requires user action due to restrictions
                hasStatusOperation = false,
                isReadOnly = false
            )
        )

        // Register hotspot operations
        registerOperation(
            OperationDefinition(
                id = "hotspot.status",
                name = "Hotspot Status",
                description = "Get the current hotspot status",
                minSdkVersion = Build.VERSION_CODES.Q, // Android 10+
                requiredPermissions = listOf(
                    Manifest.permission.ACCESS_WIFI_STATE,
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = true
            )
        )
        registerOperation(
            OperationDefinition(
                id = "hotspot.enable",
                name = "Enable Hotspot",
                description = "Enable Wi-Fi hotspot",
                minSdkVersion = Build.VERSION_CODES.Q, // Android 10+
                requiredPermissions = listOf(
                    Manifest.permission.ACCESS_WIFI_STATE,
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ),
                requiresUserActionNormally = true, // Often requires user action on modern Android
                hasStatusOperation = false,
                isReadOnly = false
            )
        )
        registerOperation(
            OperationDefinition(
                id = "hotspot.disable",
                name = "Disable Hotspot",
                description = "Disable Wi-Fi hotspot",
                minSdkVersion = Build.VERSION_CODES.Q, // Android 10+
                requiredPermissions = listOf(
                    Manifest.permission.ACCESS_WIFI_STATE,
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ),
                requiresUserActionNormally = true, // Often requires user action on modern Android
                hasStatusOperation = false,
                isReadOnly = false
            )
        )

        // Register device settings operations
        // Volume operations
        registerOperation(
            OperationDefinition(
                id = "settings.volume.media",
                name = "Media Volume",
                description = "Get or set media volume",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = emptyList(),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )
        registerOperation(
            OperationDefinition(
                id = "settings.volume.ring",
                name = "Ring Volume",
                description = "Get or set ring volume",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = emptyList(),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )
        registerOperation(
            OperationDefinition(
                id = "settings.volume.alarm",
                name = "Alarm Volume",
                description = "Get or set alarm volume",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = emptyList(),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )

        // Brightness operation
        registerOperation(
            OperationDefinition(
                id = "settings.brightness",
                name = "Screen Brightness",
                description = "Get or set screen brightness",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = listOf(Manifest.permission.WRITE_SETTINGS),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )

        // Flashlight operation
        registerOperation(
            OperationDefinition(
                id = "settings.flashlight",
                name = "Flashlight",
                description = "Get or set flashlight state",
                minSdkVersion = Build.VERSION_CODES.LOLLIPOP, // API 21
                requiredPermissions = listOf(Manifest.permission.CAMERA),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )

        // Ringer mode operation
        registerOperation(
            OperationDefinition(
                id = "settings.ringer",
                name = "Ringer Mode",
                description = "Get or set ringer mode (normal, vibrate, silent)",
                minSdkVersion = Build.VERSION_CODES.BASE,
                requiredPermissions = emptyList(),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )

        // Do Not Disturb operation
        registerOperation(
            OperationDefinition(
                id = "settings.dnd",
                name = "Do Not Disturb",
                description = "Get or set Do Not Disturb state",
                minSdkVersion = Build.VERSION_CODES.LOLLIPOP, // API 21
                requiredPermissions = listOf(Manifest.permission.ACCESS_NOTIFICATION_POLICY),
                requiresUserActionNormally = false,
                hasStatusOperation = true,
                isReadOnly = false
            )
        )
    }

    /**
     * Register a new system operation.
     */
    fun registerOperation(definition: OperationDefinition) {
        operations[definition.id] = definition
    }

    /**
     * Get the definition for an operation by its ID.
     */
    fun getOperation(id: String): OperationDefinition? {
        return operations[id]
    }

    /**
     * Check if an operation is supported based on Android SDK version.
     */
    fun isSupportedBySdk(operationId: String): Boolean {
        val operation = getOperation(operationId) ?: return false
        return Build.VERSION.SDK_INT >= operation.minSdkVersion
    }

    /**
     * Check if all required permissions for an operation are granted.
     */
    fun arePermissionsGranted(operationId: String): Boolean {
        val operation = getOperation(operationId) ?: return false
        return operation.requiredPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Get list of missing permissions for an operation.
     */
    fun getMissingPermissions(operationId: String): List<String> {
        val operation = getOperation(operationId) ?: return listOf()
        return operation.requiredPermissions.filter { permission ->
            ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Get all registered operation IDs.
     */
    fun getRegisteredOperations(): List<String> {
        return operations.keys.toList()
    }
}