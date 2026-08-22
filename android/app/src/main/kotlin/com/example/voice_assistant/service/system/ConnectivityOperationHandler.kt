package com.example.voice_assistant.service.system

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import com.example.voice_assistant.connectivity.ConnectivityManager
import com.example.voice_assistant.service.system.SystemOperationResult

/**
 * Handler for executing connectivity system operations (Wi-Fi, Mobile Data, Hotspot).
 * Delegates to ConnectivityManager for actual implementation.
 */
class ConnectivityOperationHandler private constructor(private val context: Context) {

    companion object {
        private const val TAG = "JARVIS_CONNECTIVITY_OPERATION"

        @Volatile
        private var instance: ConnectivityOperationHandler? = null

        fun getInstance(context: Context): ConnectivityOperationHandler {
            return instance ?: synchronized(this) {
                instance ?: ConnectivityOperationHandler(context).also { instance = it }
            }
        }
    }

    /**
     * Execute a connectivity system operation.
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
        Log.d(TAG, "Executing connectivity operation: $operationId, action: $action, args: $args")

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

        // Handle connectivity operations
        return when (operationId) {
            "wifi.status" -> handleWifiStatus(action)
            "wifi.enable" -> handleWifiEnable(action)
            "wifi.disable" -> handleWifiDisable(action)
            "mobiledata.status" -> handleMobileDataStatus(action)
            "mobiledata.enable" -> handleMobileDataEnable(action)
            "mobiledata.disable" -> handleMobileDataDisable(action)
            "hotspot.status" -> handleHotspotStatus(action)
            "hotspot.enable" -> handleHotspotEnable(action)
            "hotspot.disable" -> handleHotspotDisable(action)
            else -> {
                Log.w(TAG, "No implementation for connectivity operation: $operationId")
                SystemOperationResult.failed(
                    operation = operationId,
                    message = "Operation not implemented: $operationId"
                )
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleWifiStatus(action: String): SystemOperationResult {
        if (action != "get") {
            return SystemOperationResult.failed(
                operation = "wifi.status",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null /* activity not needed for status */)
        val result = connectivityManager.getWifiStatus()

        return when (result.status) {
            "enabled" -> SystemOperationResult.success(
                operation = "wifi.status",
                message = result.message ?: "Wi-Fi is enabled"
            )
            "disabled" -> SystemOperationResult.success(
                operation = "wifi.status",
                message = result.message ?: "Wi-Fi is disabled"
            )
            "unavailable" -> SystemOperationResult.unsupported(
                operation = "wifi.status",
                message = result.message ?: "Wi-Fi not available on this device"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "wifi.status",
                message = result.message ?: "Permission required to check Wi-Fi status"
            )
            else -> SystemOperationResult.failed(
                operation = "wifi.status",
                message = result.message ?: "Unknown Wi-Fi status: ${result.status}"
            )
        }
    }

    private fun handleWifiEnable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "wifi.enable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setWifiEnabled(true)

        return when (result.status) {
            "success" -> SystemOperationResult.success(
                operation = "wifi.enable",
                message = result.message ?: "Wi-Fi enabled successfully"
            )
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "wifi.enable",
                message = result.message ?: "User action required to enable Wi-Fi"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "wifi.enable",
                message = result.message ?: "Permission required to enable Wi-Fi"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "wifi.enable",
                message = result.message ?: "Wi-Fi not supported on this device"
            )
            else -> SystemOperationResult.failed(
                operation = "wifi.enable",
                message = result.message ?: "Failed to enable Wi-Fi"
            )
        }
    }

    private fun handleWifiDisable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "wifi.disable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setWifiEnabled(false)

        return when (result.status) {
            "success" -> SystemOperationResult.success(
                operation = "wifi.disable",
                message = result.message ?: "Wi-Fi disabled successfully"
            )
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "wifi.disable",
                message = result.message ?: "User action required to disable Wi-Fi"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "wifi.disable",
                message = result.message ?: "Permission required to disable Wi-Fi"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "wifi.disable",
                message = result.message ?: "Wi-Fi not supported on this device"
            )
            else -> SystemOperationResult.failed(
                operation = "wifi.disable",
                message = result.message ?: "Failed to disable Wi-Fi"
            )
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleMobileDataStatus(action: String): SystemOperationResult {
        if (action != "get") {
            return SystemOperationResult.failed(
                operation = "mobiledata.status",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.getMobileDataStatus()

        return when (result.status) {
            "enabled" -> SystemOperationResult.success(
                operation = "mobiledata.status",
                message = result.message ?: "Mobile data is enabled"
            )
            "disabled" -> SystemOperationResult.success(
                operation = "mobiledata.status",
                message = result.message ?: "Mobile data is disabled"
            )
            "unavailable" -> SystemOperationResult.unsupported(
                operation = "mobiledata.status",
                message = result.message ?: "Mobile data not available on this device"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "mobiledata.status",
                message = result.message ?: "Permission required to check mobile data status"
            )
            else -> SystemOperationResult.failed(
                operation = "mobiledata.status",
                message = result.message ?: "Unknown mobile data status: ${result.status}"
            )
        }
    }

    private fun handleMobileDataEnable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "mobiledata.enable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setMobileDataEnabled(true)

        return when (result.status) {
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "mobiledata.enable",
                message = result.message ?: "User action required to enable mobile data (direct control restricted)"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "mobiledata.enable",
                message = result.message ?: "Mobile data control not supported on this platform"
            )
            else -> SystemOperationResult.failed(
                operation = "mobiledata.enable",
                message = result.message ?: "Failed to enable mobile data"
            )
        }
    }

    private fun handleMobileDataDisable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "mobiledata.disable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setMobileDataEnabled(false)

        return when (result.status) {
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "mobiledata.disable",
                message = result.message ?: "User action required to disable mobile data (direct control restricted)"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "mobiledata.disable",
                message = result.message ?: "Mobile data control not supported on this platform"
            )
            else -> SystemOperationResult.failed(
                operation = "mobiledata.disable",
                message = result.message ?: "Failed to disable mobile data"
            )
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleHotspotStatus(action: String): SystemOperationResult {
        if (action != "get") {
            return SystemOperationResult.failed(
                operation = "hotspot.status",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.getHotspotStatus()

        return when (result.status) {
            "enabled" -> SystemOperationResult.success(
                operation = "hotspot.status",
                message = result.message ?: "Hotspot is enabled"
            )
            "disabled" -> SystemOperationResult.success(
                operation = "hotspot.status",
                message = result.message ?: "Hotspot is disabled"
            )
            "unavailable" -> SystemOperationResult.unsupported(
                operation = "hotspot.status",
                message = result.message ?: "Hotspot not available on this device"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "hotspot.status",
                message = result.message ?: "Permission required to check hotspot status"
            )
            else -> SystemOperationResult.failed(
                operation = "hotspot.status",
                message = result.message ?: "Unknown hotspot status: ${result.status}"
            )
        }
    }

    private fun handleHotspotEnable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "hotspot.enable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setHotspotEnabled(true)

        return when (result.status) {
            "success" -> SystemOperationResult.success(
                operation = "hotspot.enable",
                message = result.message ?: "Hotspot enabled successfully"
            )
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "hotspot.enable",
                message = result.message ?: "User action required to enable hotspot"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "hotspot.enable",
                message = result.message ?: "Permission required to enable hotspot"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "hotspot.enable",
                message = result.message ?: "Hotspot not supported on this device"
            )
            else -> SystemOperationResult.failed(
                operation = "hotspot.enable",
                message = result.message ?: "Failed to enable hotspot"
            )
        }
    }

    private fun handleHotspotDisable(action: String): SystemOperationResult {
        if (action != "set") {
            return SystemOperationResult.failed(
                operation = "hotspot.disable",
                message = "Unsupported action: $action"
            )
        }

        val connectivityManager = ConnectivityManager(context, null)
        val result = connectivityManager.setHotspotEnabled(false)

        return when (result.status) {
            "success" -> SystemOperationResult.success(
                operation = "hotspot.disable",
                message = result.message ?: "Hotspot disabled successfully"
            )
            "userActionRequired" -> SystemOperationResult.userActionRequired(
                operation = "hotspot.disable",
                message = result.message ?: "User action required to disable hotspot"
            )
            "permissionRequired" -> SystemOperationResult.permissionRequired(
                operation = "hotspot.disable",
                message = result.message ?: "Permission required to disable hotspot"
            )
            "unsupported" -> SystemOperationResult.unsupported(
                operation = "hotspot.disable",
                message = result.message ?: "Hotspot not supported on this device"
            )
            else -> SystemOperationResult.failed(
                operation = "hotspot.disable",
                message = result.message ?: "Failed to disable hotspot"
            )
        }
    }
}