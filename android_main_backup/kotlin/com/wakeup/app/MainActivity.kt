package com.wakeup.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wakeup.app/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "id is required", null)
                    val timeInMillis = call.argument<Long>("timeInMillis") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "timeInMillis is required", null)
                    
                    AlarmScheduler.scheduleAlarm(this, id, timeInMillis)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "id is required", null)
                    
                    AlarmScheduler.cancelAlarm(this, id)
                    result.success(true)
                }
                "stopRinging" -> {
                    AlarmService.stopService(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
