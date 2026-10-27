package com.wakeup.app

import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * Danh sách báo thức bị BỎ LỜ — tự tắt sau `autoStopMinutes` mà không có ai tương tác.
 *
 * ## Vì sao phải lưu ở tầng native?
 * Khi chuông tự tắt, ứng dụng thường đang bị giữ ở chế độ nền và Flutter engine
 * KHÔNG chạy — không thể ghi thẳng vào SQLite. Vì vậy native ghi tạm vào đây,
 * rồi Dart sẽ gọi `getMissedAlarms` để lấy và xoá danh sách mỗi khi app mở lên.
 *
 * Yêu cầu liên quan: F-07 trong docs/REQUIREMENTS.md.
 */
object MissedAlarmStore {

    private const val PREFS = "wakeup_missed"
    private const val KEY = "missed_ids"

    /** Ghi nhận một báo thức bị bỏ lỡ. Bỏ qua id không hợp lệ và tránh trùng lặp. */
    fun markMissed(context: Context, alarmId: Int) {
        if (alarmId == -1) return

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val array = JSONArray(prefs.getString(KEY, "[]") ?: "[]")

        val ids = mutableListOf<Int>()
        for (i in 0 until array.length()) {
            val v = array.optInt(i, -1)
            if (v != -1 && v != alarmId) ids.add(v)
        }
        ids.add(alarmId)

        val out = JSONArray()
        ids.forEach { out.put(it) }
        prefs.edit().putString(KEY, out.toString()).apply()

        Log.w("WakeUp", "Báo thức $alarmId bị bỏ lỡ (tự dừng sau autoStop)")
    }

    /** Trả về danh sách id bỏ lỡ và XÓA khỏi store (đọc một lần). */
    fun consumeAll(context: Context): List<Int> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY, "[]") ?: "[]"
        prefs.edit().remove(KEY).apply()

        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { array.optInt(it, -1) }.filter { it != -1 }
        } catch (e: Exception) {
            Log.w("WakeUp", "Không đọc được danh sách bỏ lỡ: ${e.message}")
            emptyList()
        }
    }
}