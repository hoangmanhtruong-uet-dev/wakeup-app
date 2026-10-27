package com.wakeup.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmTriggerReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WakeUp"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, -1)
        if (alarmId == -1) return

        val autoStopMs = intent.getLongExtra(
            AlarmScheduler.EXTRA_AUTO_STOP_MS, AlarmService.DEFAULT_AUTO_STOP_MS
        )
        val soundId = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND_ID)
        val volume = intent.getDoubleExtra(AlarmScheduler.EXTRA_VOLUME, 1.0).toFloat()

        // 1. Đổ chuông bằng Foreground Service.
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("ALARM_ID", alarmId)
            putExtra(AlarmService.EXTRA_AUTO_STOP_MS, autoStopMs)
            putExtra(AlarmService.EXTRA_SOUND_ID, soundId)
            putExtra(AlarmService.EXTRA_VOLUME, volume)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 2. Tự lập lịch cho lần kêu kế tiếp.
        //    Đây là bước BẮT BUỘC: nếu thiếu, báo thức lặp sẽ chỉ kêu đúng một lần rồi im.
        //    Việc này phải nằm ở native vì Dart có thể không chạy lúc này.
        rescheduleNextOccurrence(context, intent)
    }

    private fun rescheduleNextOccurrence(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, -1)
        val hour = intent.getIntExtra(AlarmScheduler.EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(AlarmScheduler.EXTRA_MINUTE, -1)
        val repeatDays = intent.getIntExtra(AlarmScheduler.EXTRA_REPEAT_DAYS, -1)
        val firedAt =
            intent.getLongExtra(AlarmScheduler.EXTRA_FIRE_TIME, System.currentTimeMillis())

        // Đọc lại từ Intent thay vì dùng biến cục bộ của onReceive: hàm này có thể
        // được gọi độc lập, và giá trị phải lấy từ đúng nguồn sự thật.
        val autoStopMs = intent.getLongExtra(
            AlarmScheduler.EXTRA_AUTO_STOP_MS, AlarmService.DEFAULT_AUTO_STOP_MS
        )
        val soundId = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND_ID)
        val volume = intent.getFloatExtra(AlarmScheduler.EXTRA_VOLUME, 1.0f)

        // Báo thức được tạo bởi phiên bản Dart cũ (không gửi đủ đặc tả) -> không lập lại được.
        // Lớp bảo vệ Dart sẽ lấy lại lịch khi app quay lại foreground.
        if (hour !in 0..23 || minute !in 0..59 || repeatDays < 0) {
            Log.w(TAG, "Alarm $alarmId thiếu đặc tả lặp lại — bỏ qua tự lập lại")
            return
        }

        val next = NextOccurrenceCalculator.nextOccurrence(firedAt, hour, minute, repeatDays)
        if (next == NextOccurrenceCalculator.NO_NEXT_OCCURRENCE) {
            Log.d(TAG, "Alarm $alarmId không có lần kêu tiếp theo (báo thức một lần)")
            return
        }

        try {
            AlarmScheduler.scheduleAlarm(
                context, alarmId, next, hour, minute, repeatDays, autoStopMs, soundId, volume
            )
            Log.d(TAG, "Đã tự lập lại lịch cho alarm $alarmId tại $next")
        } catch (e: Exception) {
            // Không được để lỗi ở đây làm sập quá trình nhận broadcast.
            Log.e(TAG, "Lỗi tự lập lại lịch cho alarm $alarmId: ${e.message}")
        }
    }
}