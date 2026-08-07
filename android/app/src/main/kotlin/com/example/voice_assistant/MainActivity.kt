package com.example.voice_assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var assistantBridge: AssistantBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        assistantBridge = AssistantBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        assistantBridge.register()
    }
}
