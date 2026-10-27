class TimeUtils {
  /// Tính toán thời điểm đổ chuông tiếp theo dựa trên giờ, phút và các ngày lặp lại.
  /// [repeatDays] là một bitmask: 1=Thứ 2, 2=Thứ 3, 4=Thứ 4, 8=Thứ 5, 16=Thứ 6, 32=Thứ 7, 64=CN.
  /// Nếu repeatDays == 0, báo thức chỉ kêu 1 lần.
  /// [skipNextDate] là chuỗi ISO8601 (yyyy-MM-dd) của ngày cần bỏ qua (nếu người dùng bấm "Bỏ qua lần tới").
  ///
  /// [after] là mốc thời gian để tính "kêu tiếp theo". Mặc định là [DateTime.now].
  /// Khi báo thức đã kêu, truyền `after: <thời điểm đã kêu>` để lấy đúng lần kêu KẾ TIẾP
  /// (thay vì tính lại từ hiện tại và có thể trả về chính lần vừa rồi).
  static DateTime calculateNextAlarmTime(
    int hour,
    int minute,
    int repeatDays, {
    String? skipNextDate,
    DateTime? after,
  }) {
    final now = after ?? DateTime.now();
    var nextTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Parse ngày bỏ qua (nếu có)
    DateTime? skipDate;
    if (skipNextDate != null) {
      skipDate = DateTime.tryParse(skipNextDate);
    }

    if (repeatDays == 0) {
      // Báo thức không lặp: Nếu thời gian đã qua trong ngày, chuyển sang ngày mai
      if (nextTime.isBefore(now) || nextTime.isAtSameMomentAs(now)) {
        nextTime = nextTime.add(const Duration(days: 1));
      }
      // Nếu ngày này bị skip, chuyển sang ngày mai
      if (skipDate != null && _isSameDay(nextTime, skipDate)) {
        nextTime = nextTime.add(const Duration(days: 1));
      }
    } else {
      // Báo thức có lặp: Tìm ngày gần nhất khớp với bitmask
      // Nếu giờ hôm nay chưa tới, và hôm nay có trong bitmask -> chọn luôn hôm nay
      bool todayValid = isDayInBitmask(now.weekday, repeatDays);
      if (todayValid && nextTime.isAfter(now)) {
        // nextTime giữ nguyên
      } else {
        // Quét tối đa 8 ngày tới để tìm ngày phù hợp
        for (int i = 1; i <= 8; i++) {
          final candidateDate = now.add(Duration(days: i));
          if (isDayInBitmask(candidateDate.weekday, repeatDays)) {
            nextTime = DateTime(candidateDate.year, candidateDate.month, candidateDate.day, hour, minute);
            break;
          }
        }
      }

      // Nếu ngày tìm được bị skip, tìm ngày tiếp theo khớp bitmask trong vòng 8 ngày
      if (skipDate != null && _isSameDay(nextTime, skipDate)) {
        for (int i = 1; i <= 8; i++) {
          final candidateDate = nextTime.add(Duration(days: i));
          if (isDayInBitmask(candidateDate.weekday, repeatDays)) {
            nextTime = DateTime(candidateDate.year, candidateDate.month, candidateDate.day, hour, minute);
            break;
          }
        }
      }
    }

    return nextTime;
  }

  /// Kiểm tra xem hai DateTime có cùng ngày tháng năm hay không
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Tính thời điểm báo thức sau bấm Snooze (theo số phút)
  static DateTime calculateSnoozeTime(int minutes) {
    return DateTime.now().add(Duration(minutes: minutes));
  }

  /// Tính lần kêu TIẾP THEO sau một lần kêu đã xảy ra.
  ///
  /// Dùng cho cơ chế reschedule: sau khi chuông kêu lúc [firedAt], ta cần lập lịch
  /// cho lần kế tiếp (ngày mai / tuần sau...), chứ không phải lại lần vừa rồi.
  ///
  /// - Báo thức lặp ([repeatDays] != 0): trả về ngày hợp lệ kế tiếp sau [firedAt].
  /// - Báo thức một lần ([repeatDays] == 0): hàm này vẫn trả về ngày hôm sau,
  ///   nhưng **caller phải tự chặn** trước — `AlarmRepository.rescheduleAfterFire`
  ///   cố tình KHÔNG lập lại báo thức một lần, vì "không lặp" nghĩa là kêu xong là hết.
  static DateTime nextOccurrenceAfter(
    int hour,
    int minute,
    int repeatDays,
    DateTime firedAt, {
    String? skipNextDate,
  }) {
    return calculateNextAlarmTime(
      hour,
      minute,
      repeatDays,
      skipNextDate: skipNextDate,
      after: firedAt,
    );
  }

  /// Kiểm tra xem một ngày trong tuần (1-7, 1=Thứ 2) có nằm trong bitmask hay không
  static bool isDayInBitmask(int weekday, int bitmask) {
    // weekday của Dart: 1 = Thứ 2, 7 = Chủ nhật
    final dayBit = 1 << (weekday - 1);
    return (bitmask & dayBit) != 0;
  }
}
