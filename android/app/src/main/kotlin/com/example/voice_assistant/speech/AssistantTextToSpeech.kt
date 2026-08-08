package com.example.voice_assistant.speech

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.EventChannel
import java.util.Locale
import java.util.UUID

enum class TtsStatus {
    unavailable,
    idle,
    speaking,
    error,
}

/**
 * Wraps Android's native [TextToSpeech] engine.
 *
 * All public methods are called from the main thread (via MethodChannel handlers).
 * [UtteranceProgressListener] callbacks arrive on an arbitrary thread, so events
 * are posted to the main looper before reaching the [EventChannel.EventSink].
 */
class AssistantTextToSpeech(
    context: Context,
    private val eventSinkProvider: () -> EventChannel.EventSink?,
) : TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    @Volatile private var status: TtsStatus = TtsStatus.unavailable
    @Volatile private var currentUtteranceId: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        try {
            tts = TextToSpeech(context.applicationContext, this)
        } catch (_: Exception) {
            status = TtsStatus.error
        }
    }

    override fun onInit(resultCode: Int) {
        if (resultCode != TextToSpeech.SUCCESS) {
            status = TtsStatus.error
            return
        }
        val engine = tts ?: run {
            status = TtsStatus.error
            return
        }

        if (!selectLocale(engine)) {
            status = TtsStatus.error
            sendEvent("speech_error", mapOf("message" to "No supported language available."))
            return
        }

        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
                if (utteranceId != null && utteranceId == currentUtteranceId) {
                    status = TtsStatus.speaking
                    sendEvent("speaking_started", mapOf("utteranceId" to utteranceId))
                }
            }

            override fun onDone(utteranceId: String?) {
                if (utteranceId != null && utteranceId == currentUtteranceId) {
                    status = TtsStatus.idle
                    currentUtteranceId = null
                    sendEvent("speaking_completed", mapOf("utteranceId" to utteranceId))
                }
            }

            @Suppress("DEPRECATION")
            override fun onError(utteranceId: String?) {
                if (utteranceId != null && utteranceId == currentUtteranceId) {
                    status = TtsStatus.idle
                    currentUtteranceId = null
                    sendEvent("speech_error", mapOf(
                        "utteranceId" to utteranceId,
                        "message" to "Speech synthesis failed.",
                    ))
                }
            }
        })

        status = TtsStatus.idle
    }

    fun speak(text: String): Map<String, Any?> {
        if (text.isBlank()) return errorResult("Text must not be empty.")
        val engine = tts ?: return errorResult("TTS engine is not available.")
        if (status == TtsStatus.unavailable || status == TtsStatus.error) {
            return errorResult("TTS engine is not ready.")
        }

        val utteranceId = UUID.randomUUID().toString()
        currentUtteranceId = utteranceId
        status = TtsStatus.speaking

        val result = engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
        if (result != TextToSpeech.SUCCESS) {
            currentUtteranceId = null
            status = TtsStatus.idle
            return errorResult("Failed to start speech synthesis.")
        }

        return mapOf("success" to true, "utteranceId" to utteranceId)
    }

    fun stop(): Map<String, Any?> {
        val engine = tts
        if (engine != null && status == TtsStatus.speaking) {
            engine.stop()
            val stoppedId = currentUtteranceId
            currentUtteranceId = null
            status = TtsStatus.idle
            sendEvent("speaking_stopped", mapOf("utteranceId" to stoppedId))
        }
        return mapOf("success" to true)
    }

    fun getStatus(): String = status.name

    fun shutdown() {
        currentUtteranceId = null
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {
            // Ignore shutdown errors — the engine may already be released.
        }
        tts = null
        status = TtsStatus.unavailable
    }

    private fun selectLocale(engine: TextToSpeech): Boolean {
        val defaultResult = engine.setLanguage(Locale.getDefault())
        if (defaultResult != TextToSpeech.LANG_MISSING_DATA &&
            defaultResult != TextToSpeech.LANG_NOT_SUPPORTED
        ) return true

        val fallback = engine.setLanguage(Locale.US)
        return fallback != TextToSpeech.LANG_MISSING_DATA &&
            fallback != TextToSpeech.LANG_NOT_SUPPORTED
    }

    private fun sendEvent(type: String, data: Map<String, Any?> = emptyMap()) {
        val event = mutableMapOf<String, Any?>("type" to type)
        event.putAll(data)
        mainHandler.post { eventSinkProvider()?.success(event) }
    }

    private fun errorResult(message: String): Map<String, Any?> =
        mapOf("success" to false, "message" to message)
}
