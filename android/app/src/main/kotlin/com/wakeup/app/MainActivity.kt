package com.wakeup.app

import android.content.Context
import android.content.Intent
import android.os.Build
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

                    // Đặc tả lặp lại: bắt buộc để native tự lập lại lịch sau khi chuông vang.
                    // Thiếu 3 trường này thì báo thức lặp chỉ kêu đúng một lần rồi im.
                    val hour = call.argument<Int>("hour") ?: -1
                    val minute = call.argument<Int>("minute") ?: -1
                    val repeatDays = call.argument<Int>("repeatDays") ?: -1

                    // Thời gian tự dừng chuông (F-07). Dart gửi theo phút.
                    val autoStopMinutes = call.argument<Int>("autoStopMinutes") ?: 10
                    val autoStopMs = autoStopMinutes.coerceAtLeast(1).toLong() * 60L * 1000L

                    // Nhạc chuông: tên file trong res/raw (ví dụ "alarm_radar").
                    val soundId = call.argument<String>("soundId")
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()

                    AlarmScheduler.scheduleAlarm(
                        this, id, timeInMillis, hour, minute, repeatDays,
                        autoStopMs, soundId, volume
                    )
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
                "startRinging" -> {
                    val soundId = call.argument<String>("soundId") ?: "alarm_default"
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    val autoStopMinutes = call.argument<Int>("autoStopMinutes") ?: 10
                    val autoStopMs = autoStopMinutes.coerceAtLeast(1).toLong() * 60L * 1000L

                    AlarmService.startService(this, -999, soundId, volume, autoStopMs)
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    // Android dùng cơ chế POST_NOTIFICATIONS của permission_handler,
                    // không cần xin quyền qua MethodChannel.
                    result.success(true)
                }
                "getMissedAlarms" -> {
                    // Trả về danh sách báo thức bị bỏ lỡ và xoá khỏi store phía native.
                    // Dart gọi hàm này mỗi khi app mở lên để đồng bộ lịch sử.
                    result.success(MissedAlarmStore.consumeAll(this))
                }
                "getInitialAlarmPayload" -> {
                    val isAlarm = intent?.getBooleanExtra("IS_ALARM_SCREEN", false) ?: false
                    val alarmId = intent?.getIntExtra("ALARM_ID", -1) ?: -1
                    if (isAlarm) {
                        result.success(alarmId)
                    } else {
                        result.success(null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

/**
 * Extension method to start AlarmService with foreground priority, looping ringtone,
 * vibration, wakelock, and high-priority notification.
 */
fun AlarmService.Companion.startService(
    context: Context,
    alarmId: Int = -999,
    soundId: String? = "alarm_default",
    volume: Float = 1.0f,
    autoStopMs: Long = 600000L
) {
    val serviceIntent = Intent(context, AlarmService::class.java).apply {
        putExtra(AlarmService.EXTRA_ALARM_ID, alarmId)
        putExtra(AlarmService.EXTRA_SOUND_ID, soundId)
        putExtra(AlarmService.EXTRA_VOLUME, volume)
        putExtra(AlarmService.EXTRA_AUTO_STOP_MS, autoStopMs)
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(serviceIntent)
    } else {
        context.startService(serviceIntent)
    }
}
