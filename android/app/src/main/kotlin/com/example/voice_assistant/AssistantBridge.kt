package com.example.voice_assistant

import android.Manifest
import android.app.Activity
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.example.voice_assistant.bluetooth.BluetoothManager
import com.example.voice_assistant.calls.CallRequest
import com.example.voice_assistant.calls.SafeCallPipeline
import com.example.voice_assistant.connectivity.ConnectivityManager
import com.example.voice_assistant.contacts.ContactResolver
import com.example.voice_assistant.speech.AssistantSpeechRecognizer
import com.example.voice_assistant.speech.AssistantTextToSpeech
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The sole Flutter entry point for Android-specific assistant functionality. */
class AssistantBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val settingsStore = NativeAssistantSettingsStore(activity.applicationContext)
    private val contactResolver = ContactResolver(activity.contentResolver)
    private val safeCallPipeline = SafeCallPipeline(activity, contactResolver)
    private val tts = AssistantTextToSpeech(activity.applicationContext) { eventSink }
    private val stt = AssistantSpeechRecognizer(activity.applicationContext) { eventSink }
    private val bluetoothManager = BluetoothManager(activity, activity)
    private val connectivityManager = ConnectivityManager(activity, activity)
    private var eventSink: EventChannel.EventSink? = null
    private var pendingContactsPermissionResult: MethodChannel.Result? = null
    private var pendingCallPermissionResult: MethodChannel.Result? = null
    private var pendingMicrophonePermissionResult: MethodChannel.Result? = null

    fun register() {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getIntegrationStatus" -> result.success(
                mapOf(
                    "isAvailable" to true,
                    "platform" to "Android",
                    "androidApiLevel" to Build.VERSION.SDK_INT,
                    "voiceInteractionServiceRegistered" to false,
                ),
            )
            "syncSettings" -> syncSettings(call, result)
            "hasContactsPermission" -> result.success(hasContactsPermission())
            "requestContactsPermission" -> requestContactsPermission(result)
            "resolveContacts" -> resolveContacts(call, result)
            "hasCallPermission" -> result.success(hasCallPermission())
            "requestCallPermission" -> requestCallPermission(result)
            "prepareCall" -> prepareCall(call, result)
            "confirmCall" -> confirmCall(call, result)
            "speak" -> speak(call, result)
            "stopSpeaking" -> { tts.stop(); result.success(null) }
            "getTtsStatus" -> result.success(tts.getStatus())
            "hasMicrophonePermission" -> result.success(hasMicrophonePermission())
            "requestMicrophonePermission" -> requestMicrophonePermission(result)
            "startListening" -> {
                if (!hasMicrophonePermission()) {
                    result.error("permission_required", "Microphone permission is required.", null)
                } else {
                    result.success(stt.startListening())
                }
            }
            "stopListening" -> result.success(stt.stopListening())
            "cancelListening" -> result.success(stt.cancelListening())
            "getSpeechRecognitionStatus" -> result.success(stt.getStatus())

            // Bluetooth methods
            "getBluetoothStatus" -> result.success(getBluetoothStatus().toMap())
            "requestBluetoothEnable" -> result.success(requestBluetoothEnable().toMap())
            "requestBluetoothDisable" -> result.success(requestBluetoothDisable().toMap())
            "getBluetoothDevices" -> {
                val arguments = call.arguments as? Map<*, *>
                val onlyBonded = arguments?.get("onlyBonded") as? Boolean ?: false
                result.success(getBluetoothDevices(onlyBonded).toMap())
            }
            "connectBluetoothDevice" -> {
                val arguments = call.arguments as? Map<*, *> ?: run {
                    result.error("invalid_arguments", "Device address is required.", null)
                    return
                }
                val deviceAddress = arguments["deviceAddress"] as? String
                if (deviceAddress.isNullOrBlank()) {
                    result.error("invalid_arguments", "Device address must not be empty.", null)
                    return
                }
                result.success(connectBluetoothDevice(deviceAddress).toMap())
            }
            "disconnectBluetoothDevice" -> {
                val arguments = call.arguments as? Map<*, *> ?: run {
                    result.error("invalid_arguments", "Device address is required.", null)
                    return
                }
                val deviceAddress = arguments["deviceAddress"] as? String
                if (deviceAddress.isNullOrBlank()) {
                    result.error("invalid_arguments", "Device address must not be empty.", null)
                    return
                }
                result.success(disconnectBluetoothDevice(deviceAddress).toMap())
            }

            // Connectivity methods
            "getWifiStatus" -> result.success(getWifiStatus().toMap())
            "setWifiEnabled" -> {
                val arguments = call.arguments as? Map<*, *>
                val enabled = arguments?.get("enabled") as? Boolean ?: false
                result.success(setWifiEnabled(enabled).toMap())
            }
            "getMobileDataStatus" -> result.success(getMobileDataStatus().toMap())
            "setMobileDataEnabled" -> {
                val arguments = call.arguments as? Map<*, *>
                val enabled = arguments?.get("enabled") as? Boolean ?: false
                result.success(setMobileDataEnabled(enabled).toMap())
            }
            "getHotspotStatus" -> result.success(getHotspotStatus().toMap())
            "setHotspotEnabled" -> {
                val arguments = call.arguments as? Map<*, *>
                val enabled = arguments?.get("enabled") as? Boolean ?: false
                result.success(setHotspotEnabled(enabled).toMap())
            }
            "openWifiSettings" -> result.success(openWifiSettings().toMap())
            "openMobileDataSettings" -> result.success(openMobileDataSettings().toMap())
            "openHotspotSettings" -> result.success(openHotspotSettings().toMap())
            else -> result.notImplemented()
        }
    }

    private fun syncSettings(call: MethodCall, result: MethodChannel.Result) {
        val values = call.arguments as? Map<*, *> ?: run {
            result.error("invalid_arguments", "Settings must be a map.", null)
            return
        }
        val assistantName = values["assistantName"] as? String
        val wakeWord = values["wakeWord"] as? String
        if (assistantName.isNullOrBlank() || wakeWord.isNullOrBlank()) {
            result.error("invalid_settings", "Assistant name and wake word are required.", null)
            return
        }
        settingsStore.save(values)
        result.success(null)
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        return when (requestCode) {
            CONTACTS_PERMISSION_REQUEST_CODE -> {
                pendingContactsPermissionResult?.success(mapOf("granted" to granted))
                pendingContactsPermissionResult = null
                true
            }
            CALL_PERMISSION_REQUEST_CODE -> {
                pendingCallPermissionResult?.success(mapOf("granted" to granted))
                pendingCallPermissionResult = null
                true
            }
            MICROPHONE_PERMISSION_REQUEST_CODE -> {
                pendingMicrophonePermissionResult?.success(mapOf("granted" to granted))
                pendingMicrophonePermissionResult = null
                true
            }
            else -> false
        }
    }

    private fun hasContactsPermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED

    private fun requestContactsPermission(result: MethodChannel.Result) {
        if (hasContactsPermission()) {
            result.success(mapOf("granted" to true))
            return
        }
        if (pendingContactsPermissionResult != null) {
            result.error("permission_request_in_progress", "A contacts permission request is already active.", null)
            return
        }
        pendingContactsPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.READ_CONTACTS),
            CONTACTS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun hasCallPermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED

    private fun requestCallPermission(result: MethodChannel.Result) {
        if (hasCallPermission()) {
            result.success(mapOf("granted" to true))
            return
        }
        if (pendingCallPermissionResult != null) {
            result.error("permission_request_in_progress", "A phone permission request is already active.", null)
            return
        }
        pendingCallPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.CALL_PHONE),
            CALL_PERMISSION_REQUEST_CODE,
        )
    }

    private fun hasMicrophonePermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    private fun requestMicrophonePermission(result: MethodChannel.Result) {
        if (hasMicrophonePermission()) {
            result.success(mapOf("granted" to true))
            return
        }
        if (pendingMicrophonePermissionResult != null) {
            result.error("permission_request_in_progress", "A microphone permission request is already active.", null)
            return
        }
        pendingMicrophonePermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            MICROPHONE_PERMISSION_REQUEST_CODE,
        )
    }

    private fun resolveContacts(call: MethodCall, result: MethodChannel.Result) {
        if (!hasContactsPermission()) {
            result.error("contacts_permission_required", "Contacts permission has not been granted.", null)
            return
        }
        val arguments = call.arguments as? Map<*, *> ?: run {
            result.error("invalid_arguments", "A contact query is required.", null)
            return
        }
        val query = arguments["query"] as? String
        if (query.isNullOrBlank()) {
            result.error("invalid_contact_query", "A non-empty contact query is required.", null)
            return
        }
        try {
            result.success(
                mapOf(
                    "query" to query.trim(),
                    "candidates" to contactResolver.search(query).map { it.toMap() },
                ),
            )
        } catch (exception: SecurityException) {
            result.error("contacts_permission_required", exception.message, null)
        }
    }

    private fun prepareCall(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *> ?: run {
            result.error("invalid_arguments", "Call details are required.", null)
            return
        }
        result.success(
            safeCallPipeline.prepare(
                CallRequest(
                    contactId = arguments["contactId"] as? String,
                    phoneNumber = arguments["phoneNumber"] as? String,
                    displayName = arguments["displayName"] as? String,
                ),
            ).toMap(),
        )
    }

    private fun confirmCall(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *> ?: run {
            result.error("invalid_arguments", "Call confirmation details are required.", null)
            return
        }
        val token = arguments["confirmationToken"] as? String
        val confirmed = arguments["confirmed"] as? Boolean
        if (token.isNullOrBlank() || confirmed == null) {
            result.error("invalid_arguments", "A confirmation token and decision are required.", null)
            return
        }
        result.success(safeCallPipeline.confirm(token, confirmed, hasCallPermission()).toMap())
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        eventSink?.success(mapOf("type" to "bridge_ready", "state" to "idle"))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *> ?: run {
            result.error("invalid_arguments", "Text is required.", null)
            return
        }
        val text = arguments["text"] as? String ?: run {
            result.success(mapOf("success" to false, "message" to "Text must not be empty."))
            return
        }
        result.success(tts.speak(text))
    }

    fun dispose() {
        tts.shutdown()
        stt.shutdown()
    }

    // Bluetooth methods
    @SuppressLint("MissingPermission")
    private fun getBluetoothStatus(): Map<String, Any> {
        Log.d("AssistantBridge", "getBluetoothStatus() entered")
        val result = bluetoothManager.getBluetoothStatus().toMap()
        Log.d("AssistantBridge", "getBluetoothStatus() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun requestBluetoothEnable(): Map<String, Any> {
        Log.d("AssistantBridge", "requestBluetoothEnable() entered")
        val result = bluetoothManager.requestBluetoothEnable().toMap()
        Log.d("AssistantBridge", "requestBluetoothEnable() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun requestBluetoothDisable(): Map<String, Any> {
        Log.d("AssistantBridge", "requestBluetoothDisable() entered")
        val result = bluetoothManager.requestBluetoothDisable().toMap()
        Log.d("AssistantBridge", "requestBluetoothDisable() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun getBluetoothDevices(onlyBonded: Boolean): Map<String, Any> {
        Log.d("AssistantBridge", "getBluetoothDevices() entered with onlyBonded: $onlyBonded")
        // Note: The BluetoothManager currently only supports getting bonded devices
        // For now, we ignore the onlyBonded parameter and always return bonded devices
        // In a more complete implementation, we would add scanning capabilities
        val result = bluetoothManager.getBondedDevices().toMap()
        Log.d("AssistantBridge", "getBluetoothDevices() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun connectBluetoothDevice(deviceAddress: String): Map<String, Any> {
        Log.d("AssistantBridge", "connectBluetoothDevice() entered with deviceAddress: $deviceAddress")
        val result = bluetoothManager.connectDevice(deviceAddress).toMap()
        Log.d("AssistantBridge", "connectBluetoothDevice() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun disconnectBluetoothDevice(deviceAddress: String): Map<String, Any> {
        Log.d("AssistantBridge", "disconnectBluetoothDevice() entered with deviceAddress: $deviceAddress")
        val result = bluetoothManager.disconnectDevice(deviceAddress).toMap()
        Log.d("AssistantBridge", "disconnectBluetoothDevice() returning: $result")
        return result
    }

    // Connectivity methods
    @SuppressLint("MissingPermission")
    private fun getWifiStatus(): Map<String, Any> {
        Log.d("AssistantBridge", "getWifiStatus() entered")
        val result = connectivityManager.getWifiStatus().toMap()
        Log.d("AssistantBridge", "getWifiStatus() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun setWifiEnabled(enabled: Boolean): Map<String, Any> {
        Log.d("AssistantBridge", "setWifiEnabled() entered with enabled: $enabled")
        val result = connectivityManager.setWifiEnabled(enabled).toMap()
        Log.d("AssistantBridge", "setWifiEnabled() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun getMobileDataStatus(): Map<String, Any> {
        Log.d("AssistantBridge", "getMobileDataStatus() entered")
        val result = connectivityManager.getMobileDataStatus().toMap()
        Log.d("AssistantBridge", "getMobileDataStatus() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun setMobileDataEnabled(enabled: Boolean): Map<String, Any> {
        Log.d("AssistantBridge", "setMobileDataEnabled() entered with enabled: $enabled")
        val result = connectivityManager.setMobileDataEnabled(enabled).toMap()
        Log.d("AssistantBridge", "setMobileDataEnabled() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun getHotspotStatus(): Map<String, Any> {
        Log.d("AssistantBridge", "getHotspotStatus() entered")
        val result = connectivityManager.getHotspotStatus().toMap()
        Log.d("AssistantBridge", "getHotspotStatus() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun setHotspotEnabled(enabled: Boolean): Map<String, Any> {
        Log.d("AssistantBridge", "setHotspotEnabled() entered with enabled: $enabled")
        val result = connectivityManager.setHotspotEnabled(enabled).toMap()
        Log.d("AssistantBridge", "setHotspotEnabled() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun openWifiSettings(): Map<String, Any> {
        Log.d("AssistantBridge", "openWifiSettings() entered")
        val result = connectivityManager.openWifiSettings().toMap()
        Log.d("AssistantBridge", "openWifiSettings() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun openMobileDataSettings(): Map<String, Any> {
        Log.d("AssistantBridge", "openMobileDataSettings() entered")
        val result = connectivityManager.openMobileDataSettings().toMap()
        Log.d("AssistantBridge", "openMobileDataSettings() returning: $result")
        return result
    }

    @SuppressLint("MissingPermission")
    private fun openHotspotSettings(): Map<String, Any> {
        Log.d("AssistantBridge", "openHotspotSettings() entered")
        val result = connectivityManager.openHotspotSettings().toMap()
        Log.d("AssistantBridge", "openHotspotSettings() returning: $result")
        return result
    }

    private companion object {
        const val METHOD_CHANNEL = "com.example.voice_assistant/assistant"
        const val EVENT_CHANNEL = "com.example.voice_assistant/assistant_events"
        const val CONTACTS_PERMISSION_REQUEST_CODE = 4001
        const val CALL_PERMISSION_REQUEST_CODE = 4002
        const val MICROPHONE_PERMISSION_REQUEST_CODE = 4003
    }
}

class NativeAssistantSettingsStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun save(values: Map<*, *>) {
        preferences.edit().apply {
            putString("assistant_name", values["assistantName"] as String)
            putString("wake_word", values["wakeWord"] as String)
            putString("voice", values["voice"] as? String)
            putFloat("speech_rate", (values["speechRate"] as? Number)?.toFloat() ?: 1f)
            putFloat("speech_pitch", (values["speechPitch"] as? Number)?.toFloat() ?: 1f)
            putString("language", values["language"] as? String)
            putBoolean("wake_word_enabled", values["wakeWordEnabled"] as? Boolean ?: true)
            putBoolean("voice_feedback_enabled", values["voiceFeedbackEnabled"] as? Boolean ?: true)
            apply()
        }
    }

    private companion object {
        const val PREFERENCES_NAME = "assistant_settings"
    }
}
