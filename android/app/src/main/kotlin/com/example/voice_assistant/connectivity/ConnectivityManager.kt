package com.example.voice_assistant.connectivity

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.provider.Settings

/**
 * Manages system connectivity operations for the voice assistant.
 * Handles Wi-Fi, mobile data, and hotspot operations.
 * Uses official Android APIs and falls back to settings when direct control is restricted.
 */
class ConnectivityManager(private val context: Context, private val activity: Activity?) {

    private val wifiManager: WifiManager? = context.getSystemService(Context.WIFI_SERVICE) as WifiManager?
    private val connectivityManager: ConnectivityManager? =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager?

    /**
     * Checks if Wi-Fi is available on this device.
     */
    fun isWifiAvailable(): Boolean {
        return wifiManager != null
    }

    /**
     * Gets the current Wi-Fi status.
     */
    @SuppressLint("MissingPermission")
    fun getWifiStatus(): WifiStatusResult {
        if (!isWifiAvailable()) {
            return WifiStatusResult("unavailable", "Wi-Fi not supported on this device")
        }

        // Note: For Android 12+, we need ACCESS_FINE_LOCATION permission to get accurate state
        // but we'll try anyway and handle permission exceptions
        return if (wifiManager?.isWifiEnabled == true) {
            WifiStatusResult("enabled")
        } else {
            WifiStatusResult("disabled")
        }
    }

    /**
     * Requests to enable Wi-Fi.
     * Attempts to enable programmatically first, falls back to user action if needed.
     */
    @SuppressLint("MissingPermission")
    fun setWifiEnabled(enabled: Boolean): WifiActionResult {
        if (!isWifiAvailable()) {
            return WifiActionResult(
                "unsupported", "Wi-Fi not supported on this device"
            )
        }

        // If already in desired state, return success immediately
        if (wifiManager?.isWifiEnabled == enabled) {
            return WifiActionResult("success", "Wi-Fi is already ${if (enabled) "enabled" else "disabled"}")
        }

        // Try to change Wi-Fi state programmatically (requires CHANGE_WIFI_STATE permission)
        try {
            val result = wifiManager?.setWifiEnabled(enabled)
            if (result == true) {
                // Command issued successfully, now check if it's actually in the desired state
                // Give it a moment to change state, then check status
                val startTime = System.currentTimeMillis()
                while (System.currentTimeMillis() - startTime < 3000) { // 3 second timeout
                    Thread.sleep(100) // Check every 100ms
                    if (wifiManager?.isWifiEnabled == enabled) {
                        return WifiActionResult("success", "Wi-Fi ${if (enabled) "enabled" else "disabled"} successfully")
                    }
                }
                // If we get here, command was issued but didn't change state within 3 seconds
                // Fall back to user action
                return WifiActionResult(
                    "userActionRequired",
                    "Wi-Fi ${if (enabled) "enable" else "disable"} command issued but device is still changing state. Please wait or change manually."
                )
            } else if (result == false) {
                // Command failed immediately
                return WifiActionResult(
                    "failure", "Failed to issue Wi-Fi ${if (enabled) "enable" else "disable"} command"
                )
            } else {
                // result is null (shouldn't happen but let's be safe)
                return WifiActionResult(
                    "failure", "Wi-Fi ${if (enabled) "enable" else "disable"} attempt returned null result"
                )
            }
        } catch (e: SecurityException) {
            // Don't have CHANGE_WIFI_STATE permission, fall back to user action
            return WifiActionResult(
                "userActionRequired",
                "Please change Wi-Fi state in system settings (requires CHANGE_WIFI_STATE permission)"
            )
        } catch (e: Exception) {
            // Other exception, fall back to user action
            return WifiActionResult(
                "userActionRequired",
                "Failed to ${if (enabled) "enable" else "disable"} Wi-Fi: ${e.message}. Please change manually."
            )
        }
    }

    /**
     * Checks if mobile data is available on this device.
     * Note: Direct control of mobile data is restricted in modern Android versions.
     */
    fun isMobileDataAvailable(): Boolean {
        return connectivityManager != null
    }

    /**
     * Gets the current mobile data status.
     * Note: This may require specific permissions and may not be accurate on all devices/Android versions.
     */
    @SuppressLint("MissingPermission")
    fun getMobileDataStatus(): MobileDataStatusResult {
        if (!isMobileDataAvailable()) {
            return MobileDataStatusResult("unavailable", "Connectivity manager not available")
        }

        try {
            // Try to get active network info
            val activeNetwork = connectivityManager?.activeNetwork
            if (activeNetwork != null) {
                val networkCapabilities = connectivityManager?.getNetworkCapabilities(activeNetwork)
                if (networkCapabilities != null) {
                    // Check if we have a cellular network with internet capability
                    if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) &&
                        networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                        return MobileDataStatusResult("enabled")
                    }
                }
            }

            // If we couldn't determine it's enabled, assume disabled
            return MobileDataStatusResult("disabled")
        } catch (e: SecurityException) {
            // Don't have sufficient permissions
            return MobileDataStatusResult("permissionRequired", "Insufficient permissions to check mobile data state")
        } catch (e: Exception) {
            // Other error
            return MobileDataStatusResult("unavailable", "Failed to check mobile data status: ${e.message}")
        }
    }

    /**
     * Requests to enable mobile data.
     * Note: Third-party apps cannot directly control mobile data in modern Android versions.
     * We'll return userActionRequired and suggest opening settings.
     */
    fun setMobileDataEnabled(enabled: Boolean): MobileDataActionResult {
        if (!isMobileDataAvailable()) {
            return MobileDataActionResult(
                "unsupported", "Connectivity manager not available"
            )
        }

        // Since direct control of mobile data is restricted for third-party apps
        // on most Android versions, we'll always return userActionRequired
        // and suggest the user change it in settings
        return MobileDataActionResult(
            "userActionRequired",
            "Please change mobile data state in system settings (direct control restricted for third-party apps)"
        )
    }

    /**
     * Checks if hotspot is available on this device.
     */
    fun isHotspotAvailable(): Boolean {
        return wifiManager != null
    }

    /**
     * Gets the current hotspot status.
     */
    @SuppressLint("MissingPermission")
    fun getHotspotStatus(): HotspotStatusResult {
        if (!isHotspotAvailable()) {
            return HotspotStatusResult("unavailable", "Wi-Fi/hotspot not supported on this device")
        }

        try {
            // Note: For Android 12+, we need specific permissions to check hotspot state accurately
            // We'll try using reflection or fallback methods, but for simplicity
            // we'll check if the wifi manager supports hotspot configuration
            if (wifiManager?.isWifiEnabled == true) {
                // Hotspot requires Wi-Fi to be enabled, but we can't easily check if hotspot is active
                // without additional permissions or reflection
                // For now, we'll return disabled as we can't reliably detect hotspot state
                // In a production app, you'd use TelephonyManager or other APIs with proper permissions
                return HotspotStatusResult("disabled")
            } else {
                return HotspotStatusResult("disabled")
            }
        } catch (e: SecurityException) {
            // Don't have sufficient permissions
            return HotspotStatusResult("permissionRequired", "Insufficient permissions to check hotspot state")
        } catch (e: Exception) {
            // Other error
            return HotspotStatusResult("unavailable", "Failed to check hotspot status: ${e.message}")
        }
    }

    /**
     * Requests to enable hotspot.
     * Note: Controlling hotspot programmatically requires specific permissions
     * and may not be available to third-party apps.
     */
    @SuppressLint("MissingPermission")
    fun setHotspotEnabled(enabled: Boolean): HotspotActionResult {
        if (!isHotspotAvailable()) {
            return HotspotActionResult(
                "unsupported", "Wi-Fi/hotspot not supported on this device"
            )
        }

        if (enabled) {
            // Enabling hotspot
            try {
                // First check if Wi-Fi is enabled (required for hotspot)
                if (wifiManager?.isWifiEnabled != true) {
                    // Try to enable Wi-Fi first
                    val wifiResult = setWifiEnabled(true)
                    if (wifiResult.status != "success" && wifiResult.status != "userActionRequired") {
                        return HotspotActionResult(
                            "failure", "Failed to enable Wi-Fi required for hotspot: ${wifiResult.message}"
                        )
                    }
                }

                // For enabling hotspot, we'll need to check if we can do it programmatically
                // On most modern Android versions, direct hotspot control by third-party apps is restricted
                // We'll return userActionRequired and suggest using settings
                return HotspotActionResult(
                    "userActionRequired",
                    "Please enable hotspot in system settings (direct control may be restricted for third-party apps)"
                )
            } catch (e: Exception) {
                return HotspotActionResult(
                    "failure", "Failed to enable hotspot: ${e.message}"
                )
            }
        } else {
            // Disabling hotspot
            // Similar to enabling, direct control is often restricted
            return HotspotActionResult(
                "userActionRequired",
                "Please disable hotspot in system settings (direct control may be restricted for third-party apps)"
            )
        }
    }

    /**
     * Opens Wi-Fi settings.
     */
    fun openWifiSettings(): SettingsActionResult {
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
        return startSettingsActivity(intent, "Wi-Fi settings")
    }

    /**
     * Opens mobile data settings.
     */
    fun openMobileDataSettings(): SettingsActionResult {
        val intent = Intent(Settings.ACTION_DATA_ROAMING_SETTINGS)
        // If DATA_ROAMING_SETTINGS is not available, try more general settings
        return startSettingsActivity(intent, "Mobile data settings")
    }

    /**
     * Opens hotspot settings.
     */
    fun openHotspotSettings(): SettingsActionResult {
        val intent = Intent(Settings.ACTION_TETHERING_SETTINGS)
        return startSettingsActivity(intent, "Hotspot settings")
    }

    /**
     * Helper method to start a settings activity and return result.
     */
    private fun startSettingsActivity(intent: Intent, settingsName: String): SettingsActionResult {
        // Check if we can resolve the activity
        val resolveInfo = context.packageManager.queryIntentActivities(intent, 0)
        if (resolveInfo.isEmpty()) {
            return SettingsActionResult(
                "failure", "No activity found to handle $settingsName"
            )
        }

        // Add flags to make it work properly
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            context.startActivity(intent)
            return SettingsActionResult(
                "success", "Opened $settingsName"
            )
        } catch (e: Exception) {
            return SettingsActionResult(
                "failure", "Failed to open $settingsName: ${e.message}"
            )
        }
    }
}