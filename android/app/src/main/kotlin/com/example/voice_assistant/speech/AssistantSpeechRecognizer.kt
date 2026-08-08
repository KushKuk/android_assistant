package com.example.voice_assistant.speech

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.EventChannel

enum class SttState {
    idle,
    listening,
    processing,
    error,
    unavailable,
    permissionRequired
}

/**
 * Wraps Android's native [SpeechRecognizer].
 *
 * Exposes thread-safe start, stop, cancel, and cleanup methods.
 * Emits events to the provided EventChannel sink.
 */
class AssistantSpeechRecognizer(
    private val context: Context,
    private val eventSinkProvider: () -> EventChannel.EventSink?,
) : RecognitionListener {

    private var speechRecognizer: SpeechRecognizer? = null
    @Volatile private var state: SttState = SttState.unavailable
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        mainHandler.post {
            initializeRecognizer()
        }
    }

    private fun initializeRecognizer() {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            state = SttState.unavailable
            return
        }
        try {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
                setRecognitionListener(this@AssistantSpeechRecognizer)
            }
            state = SttState.idle
        } catch (_: Exception) {
            state = SttState.error
        }
    }

    fun startListening(): Map<String, Any?> {
        if (state == SttState.unavailable) {
            return errorResult("Speech recognition is not available on this device.")
        }
        mainHandler.post {
            if (speechRecognizer == null) {
                initializeRecognizer()
            }
            if (speechRecognizer == null) {
                return@post
            }
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            }
            try {
                speechRecognizer?.startListening(intent)
                state = SttState.listening
                sendEvent("listening_started")
            } catch (e: Exception) {
                state = SttState.error
                sendEvent("speech_error", mapOf("message" to (e.message ?: "Failed to start listening.")))
            }
        }
        return mapOf("success" to true)
    }

    fun stopListening(): Map<String, Any?> {
        mainHandler.post {
            if (state == SttState.listening) {
                try {
                    speechRecognizer?.stopListening()
                    state = SttState.processing
                } catch (_: Exception) {
                    state = SttState.error
                }
            }
        }
        return mapOf("success" to true)
    }

    fun cancelListening(): Map<String, Any?> {
        mainHandler.post {
            try {
                speechRecognizer?.cancel()
                if (state == SttState.listening || state == SttState.processing) {
                    state = SttState.idle
                    sendEvent("listening_stopped")
                }
            } catch (_: Exception) {
                state = SttState.error
            }
        }
        return mapOf("success" to true)
    }

    fun getStatus(): String = state.name

    fun shutdown() {
        mainHandler.post {
            try {
                speechRecognizer?.cancel()
                speechRecognizer?.destroy()
            } catch (_: Exception) {
                // Ignore cleanup errors
            }
            speechRecognizer = null
            state = SttState.unavailable
        }
    }

    // --- RecognitionListener overrides ---

    override fun onReadyForSpeech(params: Bundle?) {
        state = SttState.listening
    }

    override fun onBeginningOfSpeech() {
        // Optional: emit an event for UI feedback
    }

    override fun onRmsChanged(rmsdB: Float) {
        // Optional: emit audio level events
    }

    override fun onBufferReceived(buffer: ByteArray?) {}

    override fun onEndOfSpeech() {
        if (state == SttState.listening) {
            state = SttState.processing
        }
    }

    override fun onError(error: Int) {
        state = SttState.idle
        val message = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No recognition result matched"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "RecognitionService busy"
            SpeechRecognizer.ERROR_SERVER -> "Error from server"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
        }
        sendEvent("speech_error", mapOf("message" to message, "code" to error))
    }

    override fun onResults(results: Bundle?) {
        state = SttState.idle
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        val transcript = matches?.firstOrNull()
        
        if (transcript != null) {
            sendEvent("final_transcript", mapOf("text" to transcript))
        } else {
            sendEvent("speech_error", mapOf("message" to "No transcript generated."))
        }
        sendEvent("listening_stopped")
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        val transcript = matches?.firstOrNull()
        
        if (transcript != null) {
            sendEvent("partial_transcript", mapOf("text" to transcript))
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {}

    private fun sendEvent(type: String, data: Map<String, Any?> = emptyMap()) {
        val event = mutableMapOf<String, Any?>("type" to type)
        event.putAll(data)
        // Listener callbacks are guaranteed to be on the main thread for SpeechRecognizer
        eventSinkProvider()?.success(event)
    }

    private fun errorResult(message: String): Map<String, Any?> =
        mapOf("success" to false, "message" to message)
}
