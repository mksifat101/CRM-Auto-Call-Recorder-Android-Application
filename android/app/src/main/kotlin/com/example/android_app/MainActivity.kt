package com.example.android_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "call_recorder/call_detection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // সার্ভিসকে চ্যানেল অবজেক্ট দিয়ে দিন
        RecordingForegroundService.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecordingService" -> {
                    val phone = call.argument<String>("phone_number") ?: "Unknown"
                    RecordingForegroundService.startService(this, phone)
                    result.success(true)
                }
                "stopRecordingService" -> {
                    RecordingForegroundService.stopService(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}