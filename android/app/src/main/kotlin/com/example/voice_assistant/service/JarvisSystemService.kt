package com.example.voice_assistant.service

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.util.Log
import com.example.voice_assistant.IJarvisSystemService
import com.example.voice_assistant.service.system.SystemOperationHandler
import com.example.voice_assistant.service.system.SystemOperationResult

/**
 * A Binder service for JARVIS Phase 4 System Control Framework.
 * Provides a generic interface for system operations through Binder IPC.
 */
class JarvisSystemService : Service() {

    private val TAG = "JARVIS_SYSTEM_SERVICE"
    private val binder = LocalBinder()

    // Service version for testing
    private val SERVICE_VERSION = "1.0.0-prototype"

    inner class LocalBinder : Binder(), IJarvisSystemService.Stub {
        override fun getServiceVersion(): String {
            val uid = Binder.getCallingUid()
            val pid = Binder.getCallingPid()
            Log.d(TAG, "getServiceVersion() called from uid=$uid, pid=$pid")
            return SERVICE_VERSION
        }

        override fun ping(): Boolean {
            val uid = Binder.getCallingUid()
            val pid = Binder.getCallingPid()
            Log.d(TAG, "ping() called from uid=$uid, pid=$pid")
            return true
        }

        override fun getSystemStatus(): String {
            val uid = Binder.getCallingUid()
            val pid = Binder.getCallingPid()
            Log.d(TAG, "getSystemStatus() called from uid=$uid, pid=$pid")
            return "OK"
        }

        // New method for system operations - Phase 4
        override fun executeSystemOperation(operation: String, action: String, args: String): String {
            val uid = Binder.getCallingUid()
            val pid = Binder.getCallingPid()
            Log.d(TAG, "executeSystemOperation() called from uid=$uid, pid=$pid with operation=$operation, action=$action, args=$args")

            // Parse args from JSON string (simple implementation for now)
            val argsMap = when (args) {
                null -> emptyMap<String, Any>()
                "" -> emptyMap<String, Any>()
                else -> {
                    try {
                        // Simple JSON parsing for basic key-value pairs
                        val map = mutableMapOf<String, Any>()
                        // Remove braces and split by commas
                        val cleaned = args.trim()
                            .removeSurrounding('{', '}')
                            .split(',')
                            .filter { it.isNotBlank() }
                        for (pair in cleaned) {
                            val keyValue = pair.split(':', limit = 2)
                            if (keyValue.size == 2) {
                                val key = keyValue[0].trim().removeSurrounding('"', '"')
                                val value = keyValue[1].trim()
                                // Try to parse as boolean or number, otherwise keep as string
                                val parsedValue = when (value) {
                                    "true" -> true
                                    "false" -> false
                                    else -> {
                                        if (value.matches(Regex("^-?\\d+(\\.\\d+)?$"))) {
                                            if (value.contains('.')) value.toDouble() else value.toInt()
                                        } else {
                                            value.removeSurrounding('"', '"')
                                        }
                                    }
                                }
                                map[key] = parsedValue
                            }
                        }
                        map.toMap()
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to parse args JSON: $args", e)
                        emptyMap<String, Any>()
                    }
                }
            }

            // Execute the operation through our handler
            val handler = SystemOperationHandler.getInstance(applicationContext)
            val result: SystemOperationResult = handler.executeOperation(operation, action, argsMap)

            // Convert result to JSON string for AIDL compatibility
            return """
                |{
                |  "status": "${result.status.name}",
                |  "operation": "${result.operation}",
                |  "message": "${result.message.replace('\"', '\\\\\"')}",
                |  "silent": ${result.silent},
                |  "requiresUserAction": ${result.requiresUserAction}
                |}
                """.trimMargin()
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "JarvisSystemService created")
    }

    override fun onBind(intent: Intent?): IBinder {
        Log.d(TAG, "Service bound: ${intent?.action}")
        return binder
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Service unbound: ${intent?.action}")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "JarvisSystemService destroyed")
    }
}