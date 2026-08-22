package com.example.voice_assistant

import android.Manifest
import android.app.Activity
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.KeyEvent
import com.example.voice_assistant.bluetooth.BluetoothManager
import com.example.voice_assistant.calls.CallRequest
import com.example.voice_assistant.calls.SafeCallPipeline
import com.example.voice_assistant.connectivity.ConnectivityManager
import com.example.voice_assistant.contacts.ContactResolver
import com.example.voice_assistant.system.binder.JarvisSystemServiceClient
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
    private var pendingBluetoothPermissionResult: MethodChannel.Result? = null
    private val systemServiceClient by lazy { JarvisSystemServiceClient.getInstance(activity.applicationContext) }

    fun register() {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun bindToSystemService() {
        systemServiceClient.bind()
    }

    fun unbindFromSystemService() {
        systemServiceClient.unbind()
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
            "hasBluetoothPermission" -> result.success(hasBluetoothPermission())
            "requestBluetoothPermission" -> requestBluetoothPermission(result)
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

            // Spotify methods
            "isSpotifyInstalled" -> result.success(isSpotifyInstalled())
            "openSpotify" -> { openSpotify(); result.success(null) }
            "playSpotify" -> { playSpotify(); result.success(null) }
            "pauseSpotify" -> { pauseSpotify(); result.success(null) }
            "resumeSpotify" -> { resumeSpotify(); result.success(null) }
            "nextSpotify" -> { nextSpotify(); result.success(null) }
            "previousSpotify" -> { previousSpotify(); result.success(null) }
            "searchAndPlayTrack" -> {
                val arguments = call.arguments as? Map<*, *>
                val query = arguments?.get("query") as? String
                if (query.isNullOrBlank()) {
                    result.error("invalid_arguments", "Query is required.", null)
                    return
                }
                searchAndPlayTrack(query)
                result.success(null)
            }
            "searchAndPlayArtist" -> {
                val arguments = call.arguments as? Map<*, *>
                val query = arguments?.get("query") as? String
                if (query.isNullOrBlank()) {
                    result.error("invalid_arguments", "Query is required.", null)
                    return
                }
                searchAndPlayArtist(query)
                result.success(null)
            }
            "searchAndPlayPlaylist" -> {
                val arguments = call.arguments as? Map<*, *>
                val query = arguments?.get("query") as? String
                if (query.isNullOrBlank()) {
                    result.error("invalid_arguments", "Query is required.", null)
                    return
                }
                searchAndPlayPlaylist(query)
                result.success(null)
            }

            // System Service methods (Binder IPC)
            "jarvis_system_ping" -> result.success(systemServiceClient.ping())
            "jarvis_system_version" -> result.success(systemServiceClient.getServiceVersion())
            "jarvis_system_status" -> result.success(systemServiceClient.getSystemStatus())
            "jarvis_system_execute_operation" -> {
                val arguments = call.arguments as? Map<*, *> ?: run {
                    result.error("invalid_arguments", "Operation arguments are required.", null)
                    return
                }
                val operation = arguments["operation"] as? String
                val action = arguments["action"] as? String
                val argsMap = arguments["args"] as? Map<*, *>
                // Convert argsMap to JSON string for the Binder call
                val argsJson = argsMap?.toString() ?: "{}"
                if (operation.isNullOrBlank() || action.isNullOrBlank()) {
                    result.error("invalid_arguments", "Operation and action are required.", null)
                    return
                }
                result.success(systemServiceClient.executeSystemOperation(operation, action, argsJson))
            }

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
            BLUETOOTH_PERMISSION_REQUEST_CODE -> {
                pendingBluetoothPermissionResult?.success(mapOf("granted" to granted))
                pendingBluetoothPermissionResult = null
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

    private fun hasBluetoothPermission(): Boolean {
        return bluetoothManager.hasBluetoothPermissions()
    }

    private fun requestBluetoothPermission(result: MethodChannel.Result) {
        if (hasBluetoothPermission()) {
            result.success(mapOf("granted" to true))
            return
        }
        if (pendingBluetoothPermissionResult != null) {
            result.error("permission_request_in_progress", "A Bluetooth permission request is already active.", null)
            return
        }
        pendingBluetoothPermissionResult = result
        // Use BluetoothManager to request permission
        bluetoothManager.requestBluetoothPermission(activity) { granted ->
            pendingBluetoothPermissionResult?.success(mapOf("granted" to granted))
            pendingBluetoothPermissionResult = null
        }
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

    // Spotify methods
    @SuppressLint("QueryPermissionsNeeded")
    private fun isSpotifyInstalled(): Boolean {
        Log.d("AssistantBridge", "isSpotifyInstalled() entered")
        // Check if Spotify package is installed
        val packageManager = activity.packageManager
        return try {
            packageManager.getPackageInfo("com.spotify.music", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    @SuppressLint("QueryPermissionsNeeded")
    private fun openSpotify() {
        Log.d("AssistantBridge", "openSpotify() entered")
        val packageManager = activity.packageManager
        val intent = packageManager.getLaunchIntentForPackage("com.spotify.music")
        if (intent != null) {
            activity.startActivity(intent)
        } else {
            // If Spotify is not installed, open Play Store
            val playStoreIntent = Intent(Intent.ACTION_VIEW)
            playStoreIntent.data = Uri.parse("market://details?id=com.spotify.music")
            activity.startActivity(playStoreIntent)
        }
    }

    private fun playSpotify() {
        Log.d("AssistantBridge", "playSpotify() entered")
        // Send play command to Spotify using media button intent
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY))
        }
        activity.sendOrderedBroadcast(intent, null)

        // Also send the key up event
        val intentUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY))
        }
        activity.sendOrderedBroadcast(intentUp, null)
    }

    private fun pauseSpotify() {
        Log.d("AssistantBridge", "pauseSpotify() entered")
        // Send pause command to Spotify using media button intent
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE))
        }
        activity.sendOrderedBroadcast(intent, null)

        // Also send the key up event
        val intentUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE))
        }
        activity.sendOrderedBroadcast(intentUp, null)
    }

    private fun resumeSpotify() {
        Log.d("AssistantBridge", "resumeSpotify() entered")
        // Resume is the same as play for Spotify
        playSpotify()
    }

    private fun nextSpotify() {
        Log.d("AssistantBridge", "nextSpotify() entered")
        // Send next track command to Spotify using media button intent
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_NEXT))
        }
        activity.sendOrderedBroadcast(intent, null)

        // Also send the key up event
        val intentUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_NEXT))
        }
        activity.sendOrderedBroadcast(intentUp, null)
    }

    private fun previousSpotify() {
        Log.d("AssistantBridge", "previousSpotify() entered")
        // Send previous track command to Spotify using media button intent
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
        }
        activity.sendOrderedBroadcast(intent, null)

        // Also send the key up event
        val intentUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
        }
        activity.sendOrderedBroadcast(intentUp, null)
    }

    @SuppressLint("QueryPermissionsNeeded")
    private fun searchAndPlayTrack(query: String) {
        Log.d("AssistantBridge", "searchAndPlayTrack() entered with query: $query")
        // Search and play track using Spotify search URI
        val searchUri = Uri.parse("spotify:search:$query")
        val intent = Intent(Intent.ACTION_VIEW, searchUri).apply {
            setPackage("com.spotify.music")
        }

        // Verify if there's an activity to handle the intent
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivity(intent)
        } else {
            // Fallback to web search if Spotify URI handling fails
            val webSearchUri = Uri.parse("https://open.spotify.com/search/$query")
            val webIntent = Intent(Intent.ACTION_VIEW, webSearchUri)
            activity.startActivity(webIntent)
        }
    }

    @SuppressLint("QueryPermissionsNeeded")
    private fun searchAndPlayArtist(query: String) {
        Log.d("AssistantBridge", "searchAndPlayArtist() entered with query: $query")
        // Search and play artist using Spotify search URI
        val searchUri = Uri.parse("spotify:search:$query")
        val intent = Intent(Intent.ACTION_VIEW, searchUri).apply {
            setPackage("com.spotify.music")
        }

        // Verify if there's an activity to handle the intent
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivity(intent)
        } else {
            // Fallback to web search if Spotify URI handling fails
            val webSearchUri = Uri.parse("https://open.spotify.com/search/$query")
            val webIntent = Intent(Intent.ACTION_VIEW, webSearchUri)
            activity.startActivity(webIntent)
        }
    }

    @SuppressLint("QueryPermissionsNeeded")
    private fun searchAndPlayPlaylist(query: String) {
        Log.d("AssistantBridge", "searchAndPlayPlaylist() entered with query: $query")
        // Search and play playlist using Spotify search URI
        val searchUri = Uri.parse("spotify:search:$query")
        val intent = Intent(Intent.ACTION_VIEW, searchUri).apply {
            setPackage("com.spotify.music")
        }

        // Verify if there's an activity to handle the intent
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivity(intent)
        } else {
            // Fallback to web search if Spotify URI handling fails
            val webSearchUri = Uri.parse("https://open.spotify.com/search/$query")
            val webIntent = Intent(Intent.ACTION_VIEW, webSearchUri)
            activity.startActivity(webIntent)
        }
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
        Log.d("AssistantBridge", "setWifeEnabled() returning: $result")
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

    companion object {
        const val METHOD_CHANNEL = "com.example.voice_assistant/assistant"
        const val EVENT_CHANNEL = "com.example.voice_assistant/assistant_events"
        const val CONTACTS_PERMISSION_REQUEST_CODE = 4001
        const val CALL_PERMISSION_REQUEST_CODE = 4002
        const val MICROPHONE_PERMISSION_REQUEST_CODE = 4003
        const val BLUETOOTH_PERMISSION_REQUEST_CODE = 4004
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