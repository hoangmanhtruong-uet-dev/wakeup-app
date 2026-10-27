package com.wakeup.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import android.net.Uri
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service phát chuông báo thức.
 *
 * ## Trách nhiệm
 * 1. Phát chuông + rung liên tục.
 * 2. **Tự dừng sau `autoStopMinutes`** nếu người dùng không tương tác (yêu cầu F-07),
 *    và ghi nhận báo thức đó là BỎ LỜ.
 *
 * ## Vì sao cần tự dừng?
 * Nếu không, chuông sẽ reo vô hạn khi người dùng không ở nhà hoặc không cầm máy:
 * vừa hao pin vừa gây khó chịu nặng nề — người dùng sẽ phải GỠ APP.
 */
class AlarmService : Service() {

    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private val handler = Handler(Looper.getMainLooper())

    /** Chạy khi hết thời gian tự dừng. */
    private val autoStopRunnable = Runnable { handleAutoStop() }

    companion object {
        private const val TAG = "WakeUp"

        const val CHANNEL_ID = "WakeUpAlarmChannel"
        const val NOTIFICATION_ID = 1001

        const val EXTRA_ALARM_ID = "ALARM_ID"
        const val EXTRA_AUTO_STOP_MS = "AUTO_STOP_MS"
        const val EXTRA_SOUND_ID = "ALARM_SOUND_ID"
        const val EXTRA_VOLUME = "ALARM_VOLUME"

        /** Tên resource dự phòng khi báo thức dùng soundId = "default". */
        private const val FALLBACK_SOUND_ID = "alarm_default"

        /** Mặc định 10 phút nếu Dart không truyền (khớp F-07). */
        const val DEFAULT_AUTO_STOP_MS = 10L * 60L * 1000L

        /** Chặn trên: service sẽ tự tắt nếu autoStopMinutes <= 0. */
        private const val MIN_AUTO_STOP_MS = 5_000L

        private const val PREFS = "wakeup_runtime"
        private const val KEY_STOP_DEADLINE = "auto_stop_deadline"
        private const val KEY_PENDING_ALARM_ID = "pending_alarm_id"

        /**
         * Dừng chuông theo yêu cầu của người dùng (đã xử lý báo thức).
         *
         * Xoá hẹn giờ tự dừng để KHÔNG ghi nhận nhầm là bỏ lỡ.
         */
        fun stopService(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .remove(KEY_STOP_DEADLINE)
                .remove(KEY_PENDING_ALARM_ID)
                .apply()

            val intent = Intent(context, AlarmService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Hệ thống khởi động lại service (START_STICKY) với intent == null.
        // TUYỆT ĐỐI không phát lại chuông ở đây, nếu không chuông sẽ reo lặp vô hạn.
        // Chỉ khôi phục hẹn giờ tự dừng nếu còn.
        if (intent == null) {
            Log.w(TAG, "Service được khởi động lại với intent null — không phát lại chuông")
            restoreAutoStopTimer()
            return START_STICKY
        }

        val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
        val autoStopMs = intent.getLongExtra(EXTRA_AUTO_STOP_MS, DEFAULT_AUTO_STOP_MS)
        val soundId = intent.getStringExtra(EXTRA_SOUND_ID)
        val volume = intent.getFloatExtra(EXTRA_VOLUME, 1.0f)

        // startForeground() phải được gọi sớm (trong ~5 giây) sau
        // startForegroundService(), nếu không Android ném
        // ForegroundServiceDidNotStartInTimeException và crash app.
        val notification = createNotification(alarmId)
        startForeground(NOTIFICATION_ID, notification)

        playRingtone(soundId, volume)
        startVibrating()
        acquireWakeLock(autoStopMs)
        scheduleAutoStop(alarmId, autoStopMs)

        return START_STICKY
    }

    // -----------------------------------------------------------------
    // Tự dừng
    // -----------------------------------------------------------------

    private fun scheduleAutoStop(alarmId: Int, autoStopMs: Long) {
        val effective = autoStopMs.coerceAtLeast(MIN_AUTO_STOP_MS)

        // Lưu deadline để sống sót cả khi tiến trình bị hệ thống hạ giết.
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong(KEY_STOP_DEADLINE, System.currentTimeMillis() + effective)
            .putInt(KEY_PENDING_ALARM_ID, alarmId)
            .apply()

        handler.removeCallbacks(autoStopRunnable)
        handler.postDelayed(autoStopRunnable, effective)

        Log.i(TAG, "Chuông alarm $alarmId sẽ tự dừng sau ${effective / 1000}s nếu không tương tác")
    }

    /** Khôi phục hẹn giờ tự dừng sau khi tiến trình bị hệ thống hạ giết rồi khởi động lại. */
    private fun restoreAutoStopTimer() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val deadline = prefs.getLong(KEY_STOP_DEADLINE, 0L)
        val remaining = deadline - System.currentTimeMillis()

        if (deadline <= 0L || remaining <= 0L) {
            Log.i(TAG, "Không còn deadline tự dừng hợp lệ")
            return
        }

        handler.removeCallbacks(autoStopRunnable)
        handler.postDelayed(autoStopRunnable, remaining)
        Log.i(TAG, "Đã khôi phục hẹn tự dừng còn ${remaining / 1000}s")
    }

    /** Đến hạn tự dừng -> ghi nhận bỏ lỡ rồi tắt service. */
    private fun handleAutoStop() {
        val alarmId = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_PENDING_ALARM_ID, -1)

        Log.i(TAG, "Hết thời gian tự dừng — dừng chuông và ghi nhận bỏ lỡ")
        MissedAlarmStore.markMissed(this, alarmId)

        clearAutoStopState()
        stopSelf()
    }

    private fun clearAutoStopState() {
        handler.removeCallbacks(autoStopRunnable)
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(KEY_STOP_DEADLINE)
            .remove(KEY_PENDING_ALARM_ID)
            .apply()
    }

    // -----------------------------------------------------------------
    // WakeLock
    // -----------------------------------------------------------------

    /**
     * Giữ CPU thức trong lúc chuông kêu để âm thanh không bị đứt giữa chừng.
     *
     * Dùng `acquire(timeout)` để Android TỰ động nhả wakelock khi hết thời gian —
     * an toàn hơn là không có timeout, tránh rò rỉ wakelock làm cạn pin.
     */
    private fun acquireWakeLock(timeoutMs: Long) {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "WakeUp:alarm"
            ).apply {
                setReferenceCounted(false)
                acquire(timeoutMs.coerceAtLeast(MIN_AUTO_STOP_MS))
            }
        } catch (e: Exception) {
            Log.w(TAG, "Không lấy được WakeLock: ${e.message}")
        }
    }

    // -----------------------------------------------------------------
    // Phát chuông
    // -----------------------------------------------------------------

    /**
     * Phát nhạc chuông của báo thức.
     *
     * - Nếu `soundId` trỏ tới một file trong `res/raw` -> dùng file đó (WAV do
     *   `tools/generate_alarm_sounds.py` sinh ra).
     *
     * `Ringtone` chạy được với URI dạng `android.resource://`, nên không cần
     * `MediaPlayer` riêng.
     */

    /**
     * Tìm id resource của nhạc chuông.
     *
     * ## Vì sao KHÔNG dùng `resources.getIdentifier()`?
     * `getIdentifier()` tra cứu theo CHUỖI, nên `shrinkResources` của R8 **không nhìn
     * thấy** các file trong `res/raw/` và sẽ XOÁ SẠCH chúng ở bản release — đã kiểm chứng
     * thực tế: APK release có 0/12 file âm thanh.
     *
     * Thay vào đó ta liệt kê tường minh bằng `R.raw.xxx`. Cách này:
     *   - tham chiếu tĩnh nên shrinker giữ lại file,
     *   - được trình biên dịch kiểm tra: gõ sai tên là báo lỗi ngay,
     *   - nhanh hơn tra cứu chuỗi.
     *
     * Thêm nhạc chuông mới: thêm file .wav vào `android/app/src/main/res/raw/`
     * rồi thêm một nhánh ở đây.
     */
    private fun resolveSoundResourceId(soundId: String?): Int {
        return when (soundId?.trim()) {
            "alarm_beep" -> R.raw.alarm_beep
            "alarm_radar" -> R.raw.alarm_radar
            "alarm_siren" -> R.raw.alarm_siren
            "alarm_bell" -> R.raw.alarm_bell
            "alarm_birds" -> R.raw.alarm_birds
            "alarm_arpeggio" -> R.raw.alarm_arpeggio
            "alarm_buzzer" -> R.raw.alarm_buzzer
            "alarm_chime" -> R.raw.alarm_chime
            "alarm_digital" -> R.raw.alarm_digital
            "alarm_sunrise" -> R.raw.alarm_sunrise
            "alarm_wakeup" -> R.raw.alarm_wakeup
            else -> R.raw.alarm_default
        }
    }

    private fun playRingingWithCustomSound(soundId: String?, volume: Float) {
        val resId = resolveSoundResourceId(soundId)
        val uri = Uri.parse("android.resource://$packageName/$resId")

        ringtone = RingtoneManager.getRingtone(this, uri)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // USAGE_ALARM giúp chuông vượt qua chế độ im lặng / không làm phiền.
            ringtone?.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            ringtone?.volume = volume.coerceIn(0.0f, 1.0f)
        }

        // Bật lặp: tệp âm thanh có thể ngắn hơn thời gian tự dừng.
        ringtone?.isLooping = true
        ringtone?.play()
    }

    /**
     * Phát nhạc chuông của báo thức.
     *
     * Ưu tiên file trong `res/raw`; nếu phát lỗi (file hỏng, codec không hỗ trợ)
     * thì lùi về âm báo mặc định của hệ thống để báo thức không bao giờ im.
     */
    private fun playRingtone(soundId: String?, volume: Float) {
        try {
            playRingingWithCustomSound(soundId, volume)
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi phát chuông '$soundId', lùi về âm hệ thống: ${e.message}")
            try {
                ringtone = RingtoneManager.getRingtone(
                    this,
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    ringtone?.audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                }
                ringtone?.isLooping = true
                ringtone?.play()
            } catch (e2: Exception) {
                Log.e(TAG, "Cả âm hệ thống cũng lỗi: ${e2.message}")
            }
        }
    }

    private fun startVibrating() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val timings = longArrayOf(0, 500, 500)
            val amplitudes = intArrayOf(0, 255, 0)
            vibrator?.vibrate(VibrationEffect.createWaveform(timings, amplitudes, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 500, 500), 0)
        }
    }

    // -----------------------------------------------------------------
    // Notification
    // -----------------------------------------------------------------

    private fun createNotification(alarmId: Int): Notification {
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("IS_ALARM_SCREEN", true)
            putExtra("ALARM_ID", alarmId)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, alarmId, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Báo thức")
            .setContentText("Đến giờ rồi!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for WakeUp+ alarm ringing"
                setBypassDnd(true)
            }
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    // -----------------------------------------------------------------
    // Vòng đời
    // -----------------------------------------------------------------

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(autoStopRunnable)
        clearAutoStopState()

        ringtone?.let {
            if (it.isPlaying) it.stop()
        }
        ringtone = null

        vibrator?.cancel()
        vibrator = null

        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}