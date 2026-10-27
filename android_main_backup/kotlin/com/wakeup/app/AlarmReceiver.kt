package com.wakeup.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

import android.database.sqlite.SQLiteDatabase
import android.app.AlarmManager
import android.app.PendingIntent
import java.io.File
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("WakeUp", "Received broadcast: $action")
        
        if (action == Intent.ACTION_BOOT_COMPLETED || 
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED) {
            
            rescheduleAllAlarms(context)
        }
    }

    private fun rescheduleAllAlarms(context: Context) {
        // Thư mục dữ liệu mặc định của path_provider (Flutter) trên Android
        val dbFile = File(context.applicationInfo.dataDir, "app_flutter/wakeup_db.sqlite")
        if (!dbFile.exists()) {
            Log.e("WakeUp", "Không tìm thấy SQLite DB tại: ${dbFile.absolutePath}")
            return
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT id, hour, minute, repeatDays, enabled FROM alarms WHERE enabled = 1", null)
            
            while (cursor.moveToNext()) {
                val id = cursor.getInt(0)
                val hour = cursor.getInt(1)
                val minute = cursor.getInt(2)
                val repeatDays = cursor.getInt(3)
                
                // TODO: Triển khai logic tính toán chi tiết bitmask (repeatDays) và skipNextDate như TimeUtils.dart
                val triggerAtMillis = calculateNextRingTime(hour, minute, repeatDays)
                
                scheduleAlarm(context, id, triggerAtMillis)
            }
            cursor.close()
            Log.d("WakeUp", "Đã lập lịch lại thành công tất cả báo thức đang bật.")
        } catch (e: Exception) {
            Log.e("WakeUp", "Lỗi đọc DB: ${e.message}")
        } finally {
            db?.close()
        }
    }

    private fun calculateNextRingTime(hour: Int, minute: Int, repeatDays: Int): Long {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        // Tạm thời: Nếu giờ đã qua trong ngày, chuyển sang ngày mai
        if (calendar.timeInMillis <= System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }
        
        return calendar.timeInMillis
    }

    private fun scheduleAlarm(context: Context, id: Int, timeInMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context, id, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Dùng setAlarmClock để đảm bảo báo thức kêu đúng giờ tuyệt đối
        // (Bỏ qua Doze Mode và hiển thị icon báo thức trên Status bar)
        val infoIntent = PendingIntent.getActivity(
            context, 0, 
            context.packageManager.getLaunchIntentForPackage(context.packageName), 
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmClockInfo = AlarmManager.AlarmClockInfo(timeInMillis, infoIntent)
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        Log.d("WakeUp", "Lập lịch báo thức ID $id vào lúc $timeInMillis")
    }
}
