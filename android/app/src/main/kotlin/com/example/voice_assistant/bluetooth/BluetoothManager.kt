package com.example.voice_assistant.bluetooth

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat

private const val BLUETOOTH_PERMISSION_REQUEST_CODE = 4004

/**
 * Manages Bluetooth operations for the voice assistant.
 * Handles permission checking and basic Bluetooth operations.
 */
class BluetoothManager(private val context: Context, private val activity: Activity?) {

    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    /**
     * Checks if Bluetooth is available on this device.
     */
    fun isBluetoothAvailable(): Boolean {
        return bluetoothAdapter != null
    }

    /**
     * Gets the current Bluetooth status.
     */
    @SuppressLint("MissingPermission")
    fun getBluetoothStatus(): BluetoothStatusResult {
        print("DIAG: BluetoothManager.getBluetoothStatus() entered")
        if (!isBluetoothAvailable()) {
            print("DIAG: BluetoothManager.getBluetoothStatus() Bluetooth not available")
            return BluetoothStatusResult("unavailable", "Bluetooth not supported on this device")
        }

        // For Android 12+, we need BLUETOOTH_CONNECT permission to get accurate state
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
            print("DIAG: BluetoothManager.getBluetoothStatus() BLUETOOTH_CONNECT permission check: $hasConnectPermission")

            if (!hasConnectPermission) {
                print("DIAG: BluetoothManager.getBluetoothStatus() Missing BLUETOOTH_CONNECT permission")
                return BluetoothStatusResult("permissionRequired", "BLUETOOTH_CONNECT permission required")
            }
        }

        val isEnabled = bluetoothAdapter?.isEnabled == true
        print("DIAG: BluetoothManager.getBluetoothStatus() Bluetooth is enabled: $isEnabled")
        return if (isEnabled) {
            BluetoothStatusResult("enabled")
        } else {
            BluetoothStatusResult("disabled")
        }
    }

    /**
     * Requests to enable Bluetooth.
     * On Android 12+, we need to request BLUETOOTH_CONNECT permission first.
     * Actual enabling requires user action through system settings.
     */
    @SuppressLint("MissingPermission")
    fun requestBluetoothEnable(): BluetoothActionResult {
        print("DIAG: BluetoothManager.requestBluetoothEnable() entered")
        if (!isBluetoothAvailable()) {
            print("DIAG: BluetoothManager.requestBluetoothEnable() Bluetooth not available")
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        // Check if we have the necessary permissions for Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
            print("DIAG: BluetoothManager.requestBluetoothEnable() BLUETOOTH_CONNECT permission check: $hasConnectPermission")

            if (!hasConnectPermission) {
                print("DIAG: BluetoothManager.requestBluetoothEnable() Missing BLUETOOTH_CONNECT permission")
                return BluetoothActionResult(
                    "permissionRequired",
                    "BLUETOOTH_CONNECT permission required"
                )
            }
        }

        // If already enabled, return success immediately
        if (bluetoothAdapter?.isEnabled == true) {
            print("DIAG: BluetoothManager.requestBluetoothEnable() Bluetooth already enabled")
            return BluetoothActionResult("success", "Bluetooth is already enabled")
        }

        // For enabling Bluetooth, we need to use system intent as third-party apps
        // cannot programmatically enable Bluetooth on most Android versions
        // This requires user action through system settings
        print("DIAG: BluetoothManager.requestBluetoothEnable() User action required to enable Bluetooth")
        return BluetoothActionResult(
            "userActionRequired",
            "Please enable Bluetooth in system settings"
        )
    }

    /**
     * Requests to disable Bluetooth.
     */
    @SuppressLint("MissingPermission")
    fun requestBluetoothDisable(): BluetoothActionResult {
        print("DIAG: BluetoothManager.requestBluetoothDisable() entered")
        if (!isBluetoothAvailable()) {
            print("DIAG: BluetoothManager.requestBluetoothDisable() Bluetooth not available")
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        // Check if we have the necessary permissions for Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
            print("DIAG: BluetoothManager.requestBluetoothDisable() BLUETOOTH_CONNECT permission check: $hasConnectPermission")

            if (!hasConnectPermission) {
                print("DIAG: BluetoothManager.requestBluetoothDisable() Missing BLUETOOTH_CONNECT permission")
                return BluetoothActionResult(
                    "permissionRequired",
                    "BLUETOOTH_CONNECT permission required"
                )
            }
        }

        if (bluetoothAdapter?.isEnabled == false) {
            print("DIAG: BluetoothManager.requestBluetoothDisable() Bluetooth already disabled")
            return BluetoothActionResult("success", "Bluetooth is already disabled")
        }

        // Disabling Bluetooth also requires user action through system settings
        print("DIAG: BluetoothManager.requestBluetoothDisable() User action required to disable Bluetooth")
        return BluetoothActionResult(
            "userActionRequired",
            "Please disable Bluetooth in system settings"
        )
    }

    /**
     * Gets a list of paired/bonded Bluetooth devices.
     */
    @SuppressLint("MissingPermission")
    fun getBondedDevices(): BluetoothDeviceListResult {
        if (!isBluetoothAvailable()) {
            return BluetoothDeviceListResult(
                emptyList(), "Bluetooth not supported on this device"
            )
        }

        // Check permissions for Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            val hasScanPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasConnectPermission && !hasScanPermission) {
                return BluetoothDeviceListResult(
                    emptyList(), "BLUETOOTH_CONNECT or BLUETOOTH_SCAN permission required"
                )
            }
        }

        val bondedDevices = bluetoothAdapter?.bondedDevices ?: emptySet()
        val deviceInfos = bondedDevices.map { BluetoothDeviceInfo.fromAndroidDevice(it) }

        return BluetoothDeviceListResult(
            devices = deviceInfos,
            message = "Found ${deviceInfos.size} paired device(s)"
        )
    }

    /**
     * Attempts to connect to a Bluetooth device.
     * Note: Actual connection depends on the Bluetooth profile and user permissions.
     * This is a simplified implementation that indicates user action may be required.
     */
    @SuppressLint("MissingPermission")
    fun connectDevice(deviceAddress: String): BluetoothActionResult {
        if (!isBluetoothAvailable()) {
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        // Check permissions for Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasConnectPermission) {
                return BluetoothActionResult(
                    "permissionRequired",
                    "BLUETOOTH_CONNECT permission required"
                )
            }
        }

        val device: BluetoothDevice? = bluetoothAdapter?.getRemoteDevice(deviceAddress)
        if (device == null) {
            return BluetoothActionResult("failure", "Device not found: $deviceAddress")
        }

        // Check if device is bonded
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            return BluetoothActionResult(
                "userActionRequired",
                "Device is not paired. Please pair with the device first."
            )
        }

        // Note: Actual connection depends on Bluetooth profile (A2DP, HFP, etc.)
        // and requires appropriate permissions and user interaction for many profiles
        // We'll indicate that user action may be required
        return BluetoothActionResult(
            "userActionRequired",
            "Please connect to the device using system Bluetooth settings"
        )
    }

    /**
     * Attempts to disconnect from a Bluetooth device.
     */
    @SuppressLint("MissingPermission")
    fun disconnectDevice(deviceAddress: String): BluetoothActionResult {
        if (!isBluetoothAvailable()) {
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        // Check permissions for Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasConnectPermission) {
                return BluetoothActionResult(
                    "permissionRequired",
                    "BLUETOOTH_CONNECT permission required"
                )
            }
        }

        val device: BluetoothDevice? = bluetoothAdapter?.getRemoteDevice(deviceAddress)
        if (device == null) {
            return BluetoothActionResult("failure", "Device not found: $deviceAddress")
        }

        // Note: Disconnecting programmatically is limited and depends on the profile
        // For most cases, we'll suggest user action through system settings
        return BluetoothActionResult(
            "userActionRequired",
            "Please disconnect from the device using system Bluetooth settings"
        )
    }

    /**
     * Checks if the necessary Bluetooth permissions are granted.
     */
    fun hasBluetoothPermissions(): Boolean {
        if (!isBluetoothAvailable()) {
            return false
        }

        // For Android 12+, we need BLUETOOTH_CONNECT for most operations
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnectPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED

            // For scanning, we also need BLUETOOTH_SCAN
            val hasScanPermission = ContextCompat.checkSelfPermission(
                context, Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED

            return hasConnectPermission // At minimum we need CONNECT for basic operations
        }

        // For older Android versions, check legacy BLUETOOTH permission
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.BLUETOOTH
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Requests the necessary Bluetooth permissions for Android 12+.
     * For older Android versions, requests the legacy BLUETOOTH permission.
     */
    fun requestBluetoothPermission(activity: Activity, result: (Boolean) -> Unit) {
        if (!isBluetoothAvailable()) {
            result(false)
            return
        }

        val permissions = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> arrayOf(Manifest.permission.BLUETOOTH_CONNECT)
            else -> arrayOf(Manifest.permission.BLUETOOTH)
        }

        print("DIAG: BluetoothManager.requestBluetoothPermission() requesting permissions: ${permissions.contentToString()}")
        activity.requestPermissions(permissions, BLUETOOTH_PERMISSION_REQUEST_CODE)
    }
}