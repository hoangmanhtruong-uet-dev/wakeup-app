package com.wakeup.app

import java.util.Calendar

/**
 * Tính thời điểm kêu tiếp theo của một báo thức LẶP.
 *
 * ## Vì sao phải có class này?
 * Khi chuông vang, Flutter engine có thể KHÔNG chạy (app đã bị hệ điều hành dọn,
 * hoặc app đang ở nền). Vì vậy tầng native phải tự tính và tự lập lịch lại —
 * không được chờ Dart.
 *
 * Thuật toán ở đây là bản ánh xạ 1-1 với `TimeUtils.calculateNextAlarmTime` bên Dart.
 * Hai bên PHẢI giữ đúng logic, nếu không sẽ xảy ra trường hợp báo thức "kêu ở app,
 * nhưng lại lặp theo ngày khác".
 */
object NextOccurrenceCalculator {

    /** Trả về khi báo thức không còn lần kêu nào nữa. */
    const val NO_NEXT_OCCURRENCE = -1L

    /**
     * Trả về epoch millis của lần kêu kế tiếp, tính từ [referenceMillis].
     *
     * @param referenceMillis thời điểm báo thức vừa kêu.
     * @param repeatDays bitmask: 1=T2, 2=T3, 4=T4, 8=T5, 16=T6, 32=T7, 64=CN.
     * @return [NO_NEXT_OCCURRENCE] nếu không có lần kêu tiếp theo.
     */
    fun nextOccurrence(
        referenceMillis: Long,
        hour: Int,
        minute: Int,
        repeatDays: Int
    ): Long {
        // Báo thức "không lặp" (một lần) -> không có lần kế tiếp.
        // Khớp với hành vi phía Dart trong AlarmRepository.rescheduleAfterFire.
        if (repeatDays == 0) return NO_NEXT_OCCURRENCE

        // Ứng viên: đúng giờ phút đã cấu hình, trong ngày của referenceMillis.
        val candidate = Calendar.getInstance().apply {
            timeInMillis = referenceMillis
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // Bắt đầu từ NGÀY HÔM SAU: ngày vừa kêu rồi không được kêu lại.
        // Quét tối đa 8 ngày (đủ để bao phủ mọi tổ hợp ngày trong tuần).
        for (dayOffset in 1..8) {
            val probe = candidate.clone() as Calendar
            probe.add(Calendar.DAY_OF_YEAR, dayOffset)
            if (isDayInBitmask(probe.get(Calendar.DAY_OF_WEEK), repeatDays)) {
                // Đặt lại giờ phút cho chắc chắn (phòng trường hợp thao tác add() bị ảnh hưởng bởi DST).
                probe.set(Calendar.HOUR_OF_DAY, hour)
                probe.set(Calendar.MINUTE, minute)
                return probe.timeInMillis
            }
        }

        return NO_NEXT_OCCURRENCE
    }

    /**
     * Trả về lần kêu sớm nhất **từ [fromMillis] trở đi** (bao gồm chính ngày đó).
     *
     * Dùng khi khôi phục lịch sau khi máy khởi động lại / đổi múi giờ: lúc này các
     * PendingIntent cũ đã mất, nên phải tìm lần kêu sắp tới kể từ thời điểm hiện tại.
     *
     * Khác với [nextOccurrence], hàm này xét **ngay cả hôm nay** — nếu máy khởi động
     * lúc 06:59 với báo thức 07:00 hằng ngày thì phải ra 07:00 HÔM NAY, không phải ngày mai.
     *
     * @return [NO_NEXT_OCCURRENCE] nếu không có lần kêu nào phù hợp.
     */
    fun nextOccurrenceAtOrAfter(
        fromMillis: Long,
        hour: Int,
        minute: Int,
        repeatDays: Int
    ): Long {
        if (repeatDays == 0) return NO_NEXT_OCCURRENCE

        val candidate = Calendar.getInstance().apply {
            timeInMillis = fromMillis
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // Hôm nay có hợp lệ và giờ chưa trôi qua -> dùng luôn hôm nay.
        if (candidate.timeInMillis >= fromMillis &&
            isDayInBitmask(candidate.get(Calendar.DAY_OF_WEEK), repeatDays)
        ) {
            return candidate.timeInMillis
        }

        // Ngày mai trở đi.
        for (dayOffset in 1..8) {
            val probe = candidate.clone() as Calendar
            probe.add(Calendar.DAY_OF_YEAR, dayOffset)
            if (isDayInBitmask(probe.get(Calendar.DAY_OF_WEEK), repeatDays)) {
                probe.set(Calendar.HOUR_OF_DAY, hour)
                probe.set(Calendar.MINUTE, minute)
                return probe.timeInMillis
            }
        }

        return NO_NEXT_OCCURRENCE
    }

    /** Kiểm tra một ngày trong tuần có nằm trong bitmask không.
     *
     * @param dayOfWeek theo [Calendar.DAY_OF_WEEK]: 1=CN, 2=T2 ... 7=T7.
     *
     * Lưu ý phép ánh xạ dễ sai:
     * - Dart `DateTime.weekday`: 1=T2 ... 7=CN  -> bit index = weekday - 1
     * - Java `Calendar.DAY_OF_WEEK`: 1=CN ... 7=T7
     *
     * Nên bit index = 6 cho Chủ nhật, còn lại là dayOfWeek - 2.
     */
    fun isDayInBitmask(dayOfWeek: Int, bitmask: Int): Boolean {
        val bitIndex = if (dayOfWeek == Calendar.SUNDAY) 6 else dayOfWeek - 2
        return (bitmask and (1 shl bitIndex)) != 0
    }
}