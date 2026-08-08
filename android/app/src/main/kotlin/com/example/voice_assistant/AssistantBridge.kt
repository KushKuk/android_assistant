package com.example.voice_assistant

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.example.voice_assistant.calls.CallRequest
import com.example.voice_assistant.calls.SafeCallPipeline
import com.example.voice_assistant.contacts.ContactResolver
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
    private var eventSink: EventChannel.EventSink? = null
    private var pendingContactsPermissionResult: MethodChannel.Result? = null
    private var pendingCallPermissionResult: MethodChannel.Result? = null

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
    }

    private companion object {
        const val METHOD_CHANNEL = "com.example.voice_assistant/assistant"
        const val EVENT_CHANNEL = "com.example.voice_assistant/assistant_events"
        const val CONTACTS_PERMISSION_REQUEST_CODE = 4001
        const val CALL_PERMISSION_REQUEST_CODE = 4002
    }
}

class NativeAssistantSettingsStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun save(values: Map<*, *>) {
        preferences.edit().apply {
            putString("assistant_name", values["assistantName"] as String)
            putString("wake_word", values["wakeWord"] as String)
            putString("calling_mode", values["callingMode"] as? String)
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
