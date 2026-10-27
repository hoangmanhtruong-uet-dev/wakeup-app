package com.wakeup.app

import android.content.Context
import android.util.Log
import org.json.JSONObject

/**
 * Sổ đăng ký báo thức ở tầng native (SharedPreferences).
 *
 * ## Vì sao KHÔNG đọc thẳng file SQLite?
 * Database đang được mã hóa bằng SQLCipher, khóa nằm trong Keystore và chỉ được
 * truy cập từ phía Dart (`flutter_secure_storage`). Tầng native không mở được file đó.
 * Trước đây `AlarmReceiver` cố mở bằng `openDatabase(path, null, READONLY)` — thao tác này
 * luôn thất bại với DB đã mã hóa, nên **sau khi khởi động lại máy, không còn báo thức nào
 * được lập lại**.
 *
 * Giải pháp: khi lập lịch, native ghi luôn đặc tả lịch vào SharedPreferences
 * (chỉ chứa số liệu giờ/ngày lặp — không phải dữ liệu nhạy cảm của người dùng).
 * Khi boot / đổi múi giờ, `AlarmReceiver` đọc lại từ đây để tính lần kêu tiếp theo.
 */
object AlarmRegistry {

    private const val PREFS = "wakeup_alarm_registry"
    private const val KEY = "alarms"

    /** Một báo thức đang được lập lịch. */
    data class Entry(
        val id: Int,
        val hour: Int,
        val minute: Int,
        val repeatDays: Int,
        val triggerAt: Long,
        val autoStopMs: Long,
        val soundId: String?,
        val volume: Float
    )

    fun put(
        context: Context,
        alarmId: Int,
        hour: Int,
        minute: Int,
        repeatDays: Int,
        triggerAt: Long,
        autoStopMs: Long,
        soundId: String?,
        volume: Float
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val root = readRoot(prefs.getString(KEY, null))
        val item = JSONObject().apply {
            put("hour", hour)
            put("minute", minute)
            put("repeatDays", repeatDays)
            put("triggerAt", triggerAt)
            put("autoStopMs", autoStopMs)
            put("soundId", soundId)
            put("volume", volume.toDouble())
        }
        root.put(alarmId.toString(), item)
        prefs.edit().putString(KEY, root.toString()).apply()
    }

    fun remove(context: Context, alarmId: Int) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val root = readRoot(prefs.getString(KEY, null))
        root.remove(alarmId.toString())
        prefs.edit().putString(KEY, root.toString()).apply()
    }

    fun removeAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY).apply()
    }

    fun all(context: Context): List<Entry> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val root = readRoot(prefs.getString(KEY, null))
        val out = mutableListOf<Entry>()

        val keys = root.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val id = key.toIntOrNull()
            if (id == null) continue

            val item = root.optJSONObject(key) ?: continue
            out.add(
                Entry(
                    id = id,
                    hour = item.optInt("hour", -1),
                    minute = item.optInt("minute", -1),
                    repeatDays = item.optInt("repeatDays", -1),
                    triggerAt = item.optLong("triggerAt", 0L),
                    autoStopMs = item.optLong(
                        "autoStopMs",
                        AlarmService.DEFAULT_AUTO_STOP_MS
                    ),
                    soundId = if (item.has("soundId")) item.optString("soundId") else null,
                    volume = item.optDouble("volume", 1.0).toFloat()
                )
            )
        }
        return out
    }

    private fun readRoot(raw: String?): JSONObject {
        if (raw.isNullOrBlank()) return JSONObject()
        return try {
            JSONObject(raw)
        } catch (e: Exception) {
            Log.w("WakeUp", "Alarm registry hỏng, khởi tạo lại: ${e.message}")
            JSONObject()
        }
    }
}