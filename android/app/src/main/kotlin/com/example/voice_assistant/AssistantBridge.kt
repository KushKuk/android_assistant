package com.example.voice_assistant

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The sole Flutter entry point for Android-specific assistant functionality. */
class AssistantBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val settingsStore = NativeAssistantSettingsStore(context)
    private var eventSink: EventChannel.EventSink? = null

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

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        eventSink?.success(mapOf("type" to "bridge_ready", "state" to "idle"))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private companion object {
        const val METHOD_CHANNEL = "com.example.voice_assistant/assistant"
        const val EVENT_CHANNEL = "com.example.voice_assistant/assistant_events"
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
