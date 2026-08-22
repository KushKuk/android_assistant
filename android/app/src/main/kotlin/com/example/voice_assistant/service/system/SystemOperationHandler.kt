package com.example.voice_assistant.service.system

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.app.NotificationManager
import android.util.Log

/**
 * Handler for executing system operations.
 * Contains the actual implementation logic for each operation.
 * Delegates to specific handlers for different operation types.
 */
class SystemOperationHandler private constructor(private val context: Context) {

    companion object {
        private const val TAG = "JARVIS_SYSTEM_OPERATION"

        @Volatile
        private var instance: SystemOperationHandler? = null

        fun getInstance(context: Context): SystemOperationHandler {
            return instance ?: synchronized(this) {
                instance ?: SystemOperationHandler(context).also { instance = it }
            }
        }
    }

    /**
     * Execute a system operation.
     *
     * @param operationId The ID of the operation to execute
     * @param action The action to perform (e.g., "get", "set", "enable", "disable")
     * @param args Optional arguments for the operation
     * @return Result of the operation execution
     */
    fun executeOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>? = null
    ): SystemOperationResult {
        Log.d(TAG, "Executing operation: $operationId, action: $action, args: $args")

        // Validate operation exists
        val registry = SystemOperationRegistry(context)
        val operationDef = registry.getOperation(operationId)
        if (operationDef == null) {
            Log.w(TAG, "Unknown operation: $operationId")
            return SystemOperationResult.failed(
                operation = operationId,
                message = "Unknown operation: $operationId"
            )
        }

        // Check SDK version support
        if (!registry.isSupportedBySdk(operationId)) {
            Log.w(TAG, "Operation $operationId not supported on SDK ${Build.VERSION.SDK_INT}")
            return SystemOperationResult.unsupported(
                operation = operationId,
                message = "Operation not supported on this Android version"
            )
        }

        // Check permissions
        if (!registry.arePermissionsGranted(operationId)) {
            val missingPermissions = registry.getMissingPermissions(operationId)
            Log.w(TAG, "Missing permissions for operation $operationId: $missingPermissions")
            return SystemOperationResult.permissionRequired(
                operation = operationId,
                message = "Missing required permissions: ${missingPermissions.joinToString()}"
            )
        }

        // Handle operations based on their ID prefix
        return when {
            operationId.startsWith("wifi.") ||
            operationId.startsWith("mobiledata.") ||
            operationId.startsWith("hotspot.") -> {
                // Delegate connectivity operations to ConnectivityOperationHandler
                val handler = ConnectivityOperationHandler.getInstance(context)
                handler.executeOperation(operationId, action, args)
            }
            operationId.startsWith("settings.") -> {
                // Handle device settings operations
                when (operationId) {
                    "settings.volume.media" -> handleVolumeOperation(
                        operationId, action, args, AudioManager.STREAM_MUSIC
                    )
                    "settings.volume.ring" -> handleVolumeOperation(
                        operationId, action, args, AudioManager.STREAM_RING
                    )
                    "settings.volume.alarm" -> handleVolumeOperation(
                        operationId, action, args, AudioManager.STREAM_ALARM
                    )
                    "settings.brightness" -> handleBrightnessOperation(operationId, action, args)
                    "settings.flashlight" -> handleFlashlightOperation(operationId, action, args)
                    "settings.ringer" -> handleRingerModeOperation(operationId, action, args)
                    "settings.dnd" -> handleDndOperation(operationId, action, args)
                    else -> {
                        Log.w(TAG, "Unknown settings operation: $operationId")
                        SystemOperationResult.failed(
                            operation = operationId,
                            message = "Unknown settings operation: $operationId"
                        )
                    }
                }
            }
            operationId == "system.test" -> {
                // Handle the test operation
                when (action) {
                    "get" -> {
                        // Return diagnostic information about the system
                        val sdkVersion = Build.VERSION.SDK_INT
                        val model = Build.MODEL
                        val manufacturer = Build.MANUFACTURER
                        val message = "System test successful. SDK: $sdkVersion, Model: $model, Manufacturer: $manufacturer"
                        Log.d(TAG, message)
                        SystemOperationResult.success(
                            operation = operationId,
                            message = message
                        )
                    }
                    else -> {
                        Log.w(TAG, "Unsupported action '$action' for operation $operationId")
                        SystemOperationResult.failed(
                            operation = operationId,
                            message = "Unsupported action: $action"
                        )
                    }
                }
            }
            else -> {
                Log.w(TAG, "No implementation for operation: $operationId")
                return SystemOperationResult.failed(
                    operation = operationId,
                    message = "Operation not implemented: $operationId"
                )
            }
        }
    }

    /**
     * Handle volume operations (media, ring, alarm)
     */
    private fun handleVolumeOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>?,
        streamType: Int
    ): SystemOperationResult {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        return when (action) {
            "get" -> {
                val currentVolume = audioManager.getStreamVolume(streamType)
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                val percentage = if (maxVolume > 0) (currentVolume * 100 / maxVolume) else 0
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume retrieved successfully",
                    silent = true
                ).also { it.currentValue = percentage }
            }
            "set" -> {
                val percentage = args?.get("percentage") as? Int ?: args?.get("value") as? Int ?: return SystemOperationResult.failed(
                    operation = operationId,
                    message = "Missing or invalid percentage/value argument"
                )
                if (percentage !in 0..100) {
                    return SystemOperationResult.failed(
                        operation = operationId,
                        message = "Percentage must be between 0 and 100"
                    )
                }
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                val targetVolume = (percentage * maxVolume / 100).coerceIn(0, maxVolume)
                audioManager.setStreamVolume(streamType, targetVolume, 0)
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume set to $percentage%"
                )
            }
            "increase" -> {
                val currentVolume = audioManager.getStreamVolume(streamType)
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                val step = maxVolume / 10 // Increase by 10%
                val newVolume = (currentVolume + step).coerceAtMost(maxVolume)
                audioManager.setStreamVolume(streamType, newVolume, 0)
                val percentage = if (maxVolume > 0) (newVolume * 100 / maxVolume) else 0
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume increased"
                ).also { it.currentValue = percentage }
            }
            "decrease" -> {
                val currentVolume = audioManager.getStreamVolume(streamType)
                val step = audioManager.getStreamMaxVolume(streamType) / 10 // Decrease by 10%
                val newVolume = (currentVolume - step).coerceAtLeast(0)
                audioManager.setStreamVolume(streamType, newVolume, 0)
                val percentage = if (audioManager.getStreamMaxVolume(streamType) > 0) (newVolume * 100 / audioManager.getStreamMaxVolume(streamType)) else 0
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume decreased"
                ).also { it.currentValue = percentage }
            }
            "mute" -> {
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                audioManager.setStreamVolume(streamType, 0, 0)
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume muted"
                ).also { it.currentValue = 0 }
            }
            "unmute" -> {
                // Restore to 50% volume as a reasonable default
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                val targetVolume = maxVolume / 2
                audioManager.setStreamVolume(streamType, targetVolume, 0)
                val percentage = if (maxVolume > 0) (targetVolume * 100 / maxVolume) else 0
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume unmuted"
                ).also { it.currentValue = percentage }
            }
            "max" -> {
                val maxVolume = audioManager.getStreamMaxVolume(streamType)
                audioManager.setStreamVolume(streamType, maxVolume, 0)
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Volume set to maximum"
                ).also { it.currentValue = 100 }
            }
            else -> {
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Unsupported action: $action"
                )
            }
        }
    }

    /**
     * Handle brightness operations
     */
    private fun handleBrightnessOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>?
    ): SystemOperationResult {
        return when (action) {
            "get" -> {
                try {
                    val brightness = Settings.System.getInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS
                    )
                    // Convert from 0-255 to 0-100 percentage
                    val percentage = (brightness * 100 / 255).coerceIn(0, 100)
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness retrieved successfully"
                    ).also { it.currentValue = percentage }
                } catch (e: Settings.SettingNotFoundException) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Failed to get brightness setting"
                    )
                }
            }
            "set" -> {
                val percentage = args?.get("percentage") as? Int ?: args?.get("value") as? Int ?: return SystemOperationResult.failed(
                    operation = operationId,
                    message = "Missing or invalid percentage/value argument"
                )
                if (percentage !in 0..100) {
                    return SystemOperationResult.failed(
                        operation = operationId,
                        message = "Percentage must be between 0 and 100"
                    )
                }
                // Convert from 0-100 percentage to 0-255
                val brightness = (percentage * 255 / 100).coerceIn(0, 255)
                try {
                    Settings.System.putInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS,
                        brightness
                    )
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness set to $percentage%"
                    )
                } catch (e: SecurityException) {
                    SystemOperationResult.permissionRequired(
                        operation = operationId,
                        message = "WRITE_SETTINGS permission required"
                    )
                }
            }
            "increase" -> {
                try {
                    val currentBrightness = Settings.System.getInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS
                    )
                    val step = 25 // Increase by ~10%
                    val newBrightness = (currentBrightness + step).coerceAtMost(255)
                    Settings.System.putInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS,
                        newBrightness
                    )
                    val percentage = (newBrightness * 100 / 255).coerceIn(0, 100)
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness increased"
                    ).also { it.currentValue = percentage }
                } catch (e: Settings.SettingNotFoundException) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Failed to get brightness setting"
                    )
                } catch (e: SecurityException) {
                    SystemOperationResult.permissionRequired(
                        operation = operationId,
                        message = "WRITE_SETTINGS permission required"
                    )
                }
            }
            "decrease" -> {
                try {
                    val currentBrightness = Settings.System.getInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS
                    )
                    val step = 25 // Decrease by ~10%
                    val newBrightness = (currentBrightness - step).coerceAtLeast(0)
                    Settings.System.putInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS,
                        newBrightness
                    )
                    val percentage = (newBrightness * 100 / 255).coerceIn(0, 100)
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness decreased"
                    ).also { it.currentValue = percentage }
                } catch (e: Settings.SettingNotFoundException) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Failed to get brightness setting"
                    )
                } catch (e: SecurityException) {
                    SystemOperationResult.permissionRequired(
                        operation = operationId,
                        message = "WRITE_SETTINGS permission required"
                    )
                }
            }
            "max" -> {
                try {
                    Settings.System.putInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS,
                        255
                    )
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness set to maximum"
                    ).also { it.currentValue = 100 }
                } catch (e: SecurityException) {
                    SystemOperationResult.permissionRequired(
                        operation = operationId,
                        message = "WRITE_SETTINGS permission required"
                    )
                }
            }
            "min" -> {
                try {
                    Settings.System.putInt(
                        context.contentResolver,
                        Settings.System.SCREEN_BRIGHTNESS,
                        0
                    )
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "Brightness set to minimum"
                    ).also { it.currentValue = 0 }
                } catch (e: SecurityException) {
                    SystemOperationResult.permissionRequired(
                        operation = operationId,
                        message = "WRITE_SETTINGS permission required"
                    )
                }
            }
            else -> {
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Unsupported action: $action"
                )
            }
        }
    }

    /**
     * Handle flashlight operations
     */
    private fun handleFlashlightOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>?
    ): SystemOperationResult {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

        return when (action) {
            "get" -> {
                try {
                    val cameraId = cameraManager.cameraIdList.firstOrDefault {
                        cameraManager.getCameraCharacteristics(it)
                            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                    }
                    if (cameraId == null) {
                        SystemOperationResult.unsupported(
                            operation = operationId,
                            message = "Device lacks flashlight hardware"
                        )
                    } else {
                        val torchOn = try {
                            cameraManager.getCameraCharacteristics(cameraId)
                                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                        } catch (e: CameraAccessException) {
                            false
                        }
                        SystemOperationResult.success(
                            operation = operationId,
                            message = "Flashlight status retrieved"
                        ).also { it.currentValue = if (torchOn) "ON" else "OFF" }
                    }
                } catch (e: Exception) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Error checking flashlight availability: ${e.message}"
                    )
                }
            }
            "set" -> {
                val enabled = args?.get("enabled") as? Boolean ?: args?.get("value") as? Boolean ?:
                            return SystemOperationResult.failed(
                                operation = operationId,
                                message = "Missing or invalid enabled/value argument"
                            )
                try {
                    val cameraId = cameraManager.cameraIdList.firstOrDefault {
                        cameraManager.getCameraCharacteristics(it)
                            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                    }
                    if (cameraId == null) {
                        SystemOperationResult.unsupported(
                            operation = operationId,
                            message = "Device lacks flashlight hardware"
                        )
                    } else {
                        cameraManager.setTorchMode(cameraId, enabled)
                        SystemOperationResult.success(
                            operation = operationId,
                            message = "Flashlight ${if (enabled) "turned on" else "turned off"}"
                        ).also { it.currentValue = if (enabled) "ON" else "OFF" }
                    }
                } catch (e: CameraAccessException) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Camera access error: ${e.message}"
                    )
                } catch (e: Exception) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Error setting flashlight: ${e.message}"
                    )
                }
            }
            "toggle" -> {
                try {
                    val cameraId = cameraManager.cameraIdList.firstOrDefault {
                        cameraManager.getCameraCharacteristics(it)
                            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                    }
                    if (cameraId == null) {
                        SystemOperationResult.unsupported(
                            operation = operationId,
                            message = "Device lacks flashlight hardware"
                        )
                    } else {
                        val currentState = try {
                            cameraManager.getTorchState(cameraId)
                        } catch (e: CameraAccessException) {
                            false
                        }
                        cameraManager.setTorchMode(cameraId, !currentState)
                        SystemOperationResult.success(
                            operation = operationId,
                            message = "Flashlight toggled to ${if (!currentState) "ON" else "OFF"}"
                        ).also { it.currentValue = if (!currentState) "ON" else "OFF" }
                    }
                } catch (e: CameraAccessException) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Camera access error: ${e.message}"
                    )
                } catch (e: Exception) {
                    SystemOperationResult.failed(
                        operation = operationId,
                        message = "Error toggling flashlight: ${e.message}"
                    )
                }
            }
            else -> {
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Unsupported action: $action"
                )
            }
        }
    }

    /**
     * Handle ringer mode operations
     */
    private fun handleRingerModeOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>?
    ): SystemOperationResult {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        return when (action) {
            "get" -> {
                val ringerMode = audioManager.ringerMode
                val modeString = when (ringerMode) {
                    AudioManager.RINGER_MODE_NORMAL -> "NORMAL"
                    AudioManager.RINGER_MODE_VIBRATE -> "VIBRATE"
                    AudioManager.RINGER_MODE_SILENT -> "SILENT"
                    else -> "UNKNOWN"
                }
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Ringer mode retrieved successfully"
                ).also { it.currentValue = modeString }
            }
            "set" -> {
                val mode = args?.get("mode") as? String ?: args?.get("value") as? String ?:
                         return SystemOperationResult.failed(
                             operation = operationId,
                             message = "Missing or invalid mode/value argument"
                         )
                val targetMode = when (mode.uppercase()) {
                    "NORMAL" -> AudioManager.RINGER_MODE_NORMAL
                    "VIBRATE" -> AudioManager.RINGER_MODE_VIBRATE
                    "SILENT" -> AudioManager.RINGER_MODE_SILENT
                    else -> return SystemOperationResult.failed(
                        operation = operationId,
                        message = "Invalid mode. Must be NORMAL, VIBRATE, or SILENT"
                    )
                }
                audioManager.ringerMode = targetMode
                val modeString = when (targetMode) {
                    AudioManager.RINGER_MODE_NORMAL -> "NORMAL"
                    AudioManager.RINGER_MODE_VIBRATE -> "VIBRATE"
                    AudioManager.RINGER_MODE_SILENT -> "SILENT"
                    else -> "UNKNOWN"
                }
                SystemOperationResult.success(
                    operation = operationId,
                    message = "Ringer mode set to $modeString"
                ).also { it.currentValue = modeString }
            }
            else -> {
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Unsupported action: $action"
                )
            }
        }
    }

    /**
     * Handle Do Not Disturb operations
     */
    private fun handleDndOperation(
        operationId: String,
        action: String,
        args: Map<String, Any>?
    ): SystemOperationResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return SystemOperationResult.unsupported(
                operation = operationId,
                message = "Do Not Disturb not supported on this Android version"
            )
        }

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        return when (action) {
            "get" -> {
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    val dndEnabled = notificationManager.isInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    val modeString = if (dndEnabled) "ENABLED" else "DISABLED"
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "DND status retrieved successfully"
                    ).also { it.currentValue = modeString }
                } else {
                    SystemOperationResult.userActionRequired(
                        operation = operationId,
                        message = "Notification Policy Access permission required"
                    )
                }
            }
            "set" -> {
                val enabled = args?.get("enabled") as? Boolean ?: args?.get("value") as? Boolean ?:
                            return SystemOperationResult.failed(
                                operation = operationId,
                                message = "Missing or invalid enabled/value argument"
                            )
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    if (enabled) {
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    } else {
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    SystemOperationResult.success(
                        operation = operationId,
                        message = "DND ${if (enabled) "enabled" else "disabled"}"
                    ).also { it.currentValue = if (enabled) "ENABLED" else "DISABLED" }
                } else {
                    SystemOperationResult.userActionRequired(
                        operation = operationId,
                        message = "Notification Policy Access permission required"
                    )
                }
            }
            else -> {
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Unsupported action: $action"
                )
            }
        }
    }
}