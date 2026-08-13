package com.example.voice_assistant.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.provider.Settings

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
        if (!isBluetoothAvailable()) {
            return BluetoothStatusResult("unavailable", "Bluetooth not supported on this device")
        }

        // Note: For Android 12+, we need BLUETOOTH_CONNECT or BLUETOOTH_SCAN permissions
        // to get accurate state, but we'll try anyway and handle permission exceptions
        return if (bluetoothAdapter?.isEnabled == true) {
            BluetoothStatusResult("enabled")
        } else {
            BluetoothStatusResult("disabled")
        }
    }

    /**
     * Requests to enable Bluetooth.
     * Attempts to enable programmatically first, falls back to user action if needed.
     */
    @SuppressLint("MissingPermission")
    fun requestBluetoothEnable(): BluetoothActionResult {
        if (!isBluetoothAvailable()) {
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        // If already enabled, return success immediately
        if (bluetoothAdapter?.isEnabled == true) {
            return BluetoothActionResult("success", "Bluetooth is already enabled")
        }

        // Try to enable Bluetooth programmatically (requires BLUETOOTH_ADMIN permission)
        try {
            val result = bluetoothAdapter?.enable()
            if (result == true) {
                // Enable command issued successfully, now check if it's actually enabled
                // Give it a moment to turn on, then check status
                val startTime = System.currentTimeMillis()
                while (System.currentTimeMillis() - startTime < 2000) { // 2 second timeout
                    Thread.sleep(100) // Check every 100ms
                    if (bluetoothAdapter?.isEnabled == true) {
                        return BluetoothActionResult("success", "Bluetooth enabled successfully")
                    }
                }
                // If we get here, enable was issued but didn't turn on within 2 seconds
                // Fall back to user action
                return BluetoothActionResult(
                    "userActionRequired",
                    "Bluetooth enable command issued but device is still enabling. Please wait or enable manually."
                )
            } else if (result == false) {
                // Enable command failed immediately
                return BluetoothActionResult(
                    "failure", "Failed to issue Bluetooth enable command"
                )
            } else {
                // result is null (shouldn't happen but let's be safe)
                return BluetoothActionResult(
                    "failure", "Bluetooth enable attempt returned null result"
                )
            }
        } catch (e: SecurityException) {
            // Don't have BLUETOOTH_ADMIN permission, fall back to user action
            return BluetoothActionResult(
                "userActionRequired",
                "Please enable Bluetooth in system settings (requires BLUETOOTH_ADMIN permission)"
            )
        } catch (e: Exception) {
            // Other exception, fall back to user action
            return BluetoothActionResult(
                "userActionRequired",
                "Failed to enable Bluetooth: ${e.message}. Please enable manually."
            )
        }
    }

    /**
     * Requests to disable Bluetooth.
     * Note: This usually requires BLUETOOTH_ADMIN permission or user interaction.
     */
    @SuppressLint("MissingPermission")
    fun requestBluetoothDisable(): BluetoothActionResult {
        if (!isBluetoothAvailable()) {
            return BluetoothActionResult(
                "unsupported", "Bluetooth not supported on this device"
            )
        }

        if (bluetoothAdapter?.isEnabled == false) {
            return BluetoothActionResult("success", "Bluetooth is already disabled")
        }

        // Disabling Bluetooth programmatically requires BLUETOOTH_ADMIN permission
        // which is not available to third-party apps on most Android versions
        // We'll suggest the user do it through system settings
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

        // Note: For Android 12+, we need BLUETOOTH_CONNECT or BLUETOOTH_SCAN permissions
        val bondedDevices = bluetoothAdapter?.bondedDevices ?: emptySet()
        val deviceInfos = bondedDevices.map { BluetoothDeviceInfo.fromAndroidDevice(it) }

        return BluetoothDeviceListResult(
            devices = deviceInfos.toList(),
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
     * Note: This is simplified - actual permission checking depends on Android version.
     */
    fun hasBluetoothPermissions(): Boolean {
        // For simplicity, we're assuming permissions are handled at runtime
        // In a production app, you'd check for:
        // - BLUETOOTH (for legacy apps)
        // - BLUETOOTH_CONNECT, BLUETOOTH_ADMIN (Android 12+)
        // - BLUETOOTH_SCAN (Android 12+ for scanning)
        return true // Placeholder - actual implementation would check permissions
    }
}