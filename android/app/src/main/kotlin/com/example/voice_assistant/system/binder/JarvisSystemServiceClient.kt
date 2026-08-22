package com.example.voice_assistant.system.binder

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import com.example.voice_assistant.IJarvisSystemService

/**
 * Binder client for JarvisSystemService.
 * Provides methods to bind to the service and call Binder interface methods.
 */
class JarvisSystemServiceClient private constructor(
    private val context: Context
) {

    companion object {
        private const val TAG = "JarvisSystemServiceClient"
        @Volatile private var INSTANCE: JarvisSystemServiceClient? = null

        fun getInstance(context: Context): JarvisSystemServiceClient {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: JarvisSystemServiceClient(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private var service: IJarvisSystemService? = null
    private var isBound = false
    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            Log.d(TAG, "Service connected")
            this@JarvisSystemServiceClient.service = IJarvisSystemService.Stub.asInterface(service)
            isBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            Log.d(TAG, "Service disconnected")
            this@JarvisSystemServiceClient.service = null
            isBound = false
        }
    }

    /** Bind to the JarvisSystemService */
    fun bind(): Boolean {
        val intent = android.content.Intent(context, JarvisSystemService::class.java)
        val bound = context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
        Log.d(TAG, "Bind attempt result: $bound")
        return bound
    }

    /** Unbind from the service */
    fun unbind() {
        if (isBound) {
            context.unbindService(connection)
            isBound = false
            service = null
            Log.d(TAG, "Service unbound")
        }
    }

    /** Check if client is bound to service */
    fun isBound(): Boolean = isBound

    /** Call ping() on the service */
    fun ping(): Boolean {
        return service?.ping() ?: false
    }

    /** Call getServiceVersion() on the service */
    fun getServiceVersion(): String {
        return service?.getServiceVersion() ?: "UNBOUND"
    }

    /** Call getSystemStatus() on the service */
    fun getSystemStatus(): String {
        return service?.getSystemStatus() ?: "UNBOUND"
    }

    /** Call executeSystemOperation() on the service */
    fun executeSystemOperation(operation: String, action: String, args: String): String {
        return service?.executeSystemOperation(operation, action, args) ?: "UNBOUND"
    }
}