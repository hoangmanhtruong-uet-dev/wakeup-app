package com.wakeup.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Lấy lại toàn bộ lịch báo thức sau khi có sự kiện làm mất PendingIntent:
 * khởi động lại máy, cập nhật app, hoặc đổi múi giờ / đổi giờ hệ thống.
 *
 * Trước Giai đoạn 2, receiver này cố đọc thẳng file SQLite. Điều đó **luôn thất bại**
 * vì database đã được mã hóa SQLCipher, nên sau khi reboot toàn bộ báo thức biến mất
 * mà không có bất kỳ cảnh báo nào cho người dùng. Nay đọc từ [AlarmRegistry].
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WakeUp"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d(TAG, "Nhận broadcast: $action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED -> {
                rescheduleAllAlarms(context.applicationContext)
            }
        }
    }

    private fun rescheduleAllAlarms(context: Context) {
        val entries = AlarmRegistry.all(context)
        if (entries.isEmpty()) {
            Log.d(TAG, "Không có báo thức nào trong registry, không cần lập lại")
            return
        }

        val now = System.currentTimeMillis()
        var restored = 0

        for (entry in entries) {
            // Bản ghi không hợp lệ (app cũ chưa ghi đủ thông tin) -> dọn đi.
            if (entry.hour !in 0..23 || entry.minute !in 0..59 || entry.repeatDays < 0) {
                AlarmRegistry.remove(context, entry.id)
                continue
            }

            val next = if (entry.repeatDays == 0) {
                // Báo thức một lần: giữ thời điểm tuyệt đối đã lập. Đã qua rồi thì bỏ.
                if (entry.triggerAt > now) {
                    entry.triggerAt
                } else {
                    NextOccurrenceCalculator.NO_NEXT_OCCURRENCE
                }
            } else {
                NextOccurrenceCalculator.nextOccurrenceAtOrAfter(
                    now, entry.hour, entry.minute, entry.repeatDays
                )
            }

            if (next == NextOccurrenceCalculator.NO_NEXT_OCCURRENCE) {
                // Báo thức một lần đã qua -> không còn ý nghĩa.
                AlarmRegistry.remove(context, entry.id)
                continue
            }

            try {
                AlarmScheduler.scheduleAlarm(
                    context, entry.id, next,
                    entry.hour, entry.minute, entry.repeatDays,
                    entry.autoStopMs, entry.soundId, entry.volume
                )
                restored++
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi lập lại lịch cho alarm ${entry.id}: ${e.message}")
            }
        }

        Log.d(TAG, "Đã lập lại lịch cho $restored/${entries.size} báo thức")
    }
}