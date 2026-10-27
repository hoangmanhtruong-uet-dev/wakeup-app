package com.wakeup.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object AlarmScheduler {

    // ----- Khoá để truyền đặc tả báo thức xuyên suốt Intent -----
    // Đặc tả này là thứ cho phép tầng native TỰ lập lịch lại sau khi chuông vang,
    // vì lúc đó Flutter engine có thể không còn chạy.
    const val EXTRA_ALARM_ID = "ALARM_ID"
    const val EXTRA_HOUR = "ALARM_HOUR"
    const val EXTRA_MINUTE = "ALARM_MINUTE"
    const val EXTRA_REPEAT_DAYS = "ALARM_REPEAT_DAYS"
    const val EXTRA_FIRE_TIME = "ALARM_FIRE_TIME"

    /// Thời gian tự dừng chuông (millis) nếu không có tương tác (F-07).
    const val EXTRA_AUTO_STOP_MS = "ALARM_AUTO_STOP_MS"

    /// Id nhạc chuông (tên file trong `res/raw`, không có extension).
    const val EXTRA_SOUND_ID = "ALARM_SOUND_ID"

    /// Âm lượng 0.0 ... 1.0 (có thể lưu với 2 chữ số thập phân trong Bundle).
    const val EXTRA_VOLUME = "ALARM_VOLUME"

    fun scheduleAlarm(
        context: Context,
        alarmId: Int,
        timeInMillis: Long,
        hour: Int,
        minute: Int,
        repeatDays: Int,
        autoStopMs: Long = AlarmService.DEFAULT_AUTO_STOP_MS,
        soundId: String? = null,
        // Dùng Float (không phải Double) vì đây là kiểu của Ringtone.volume và
        // Intent.putExtra(String, Float). Giữ thống nhất với AlarmRegistry.Entry.volume.
        volume: Float = 1.0f
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_HOUR, hour)
            putExtra(EXTRA_MINUTE, minute)
            putExtra(EXTRA_REPEAT_DAYS, repeatDays)
            putExtra(EXTRA_AUTO_STOP_MS, autoStopMs)
            putExtra(EXTRA_SOUND_ID, soundId)
            putExtra(EXTRA_VOLUME, volume)
            // Lưu lại thời điểm dự kiến để tính chính xác lần kêu kế tiếp.
            putExtra(EXTRA_FIRE_TIME, timeInMillis)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // setAlarmClock là cấp độ chính xác cao nhất trên Android: vượt qua Doze Mode
        // và hiển thị biểu tượng báo thức trên thanh trạng thái.
        val alarmClockInfo = AlarmManager.AlarmClockInfo(
            timeInMillis,
            getShowInfoIntent(context)
        )
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)

        // Ghi lại đặc tả vào registry để khôi phục được sau khi máy khởi động lại
        // hoặc đổi múi giờ (không phụ thuộc SQLite đã mã hóa).
        AlarmRegistry.put(
            context, alarmId, hour, minute, repeatDays, timeInMillis, autoStopMs, soundId, volume
        )
    }

    fun cancelAlarm(context: Context, alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmTriggerReceiver::class.java)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        AlarmRegistry.remove(context, alarmId)
    }

    private fun getShowInfoIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}