import 'package:flutter_test/flutter_test.dart';
import 'package:wakeup_app/core/utils/time_utils.dart'; // Giả sử package name là wakeup_app

void main() {
  group('TimeUtils - Bitmask Logic', () {
    test('isDayInBitmask trả về đúng ngày', () {
      // 1: T2, 2: T3, 4: T4, 8: T5, 16: T6, 32: T7, 64: CN
      expect(TimeUtils.isDayInBitmask(1, 1), isTrue); // T2 nằm trong bitmask 1
      expect(TimeUtils.isDayInBitmask(7, 64), isTrue); // CN nằm trong bitmask 64
      
      // Cuối tuần (T7 + CN) = 32 + 64 = 96
      expect(TimeUtils.isDayInBitmask(6, 96), isTrue); // T7 nằm trong 96
      expect(TimeUtils.isDayInBitmask(7, 96), isTrue); // CN nằm trong 96
      expect(TimeUtils.isDayInBitmask(5, 96), isFalse); // T6 KHÔNG nằm trong 96
      
      // Ngày làm việc (T2 - T6) = 1 + 2 + 4 + 8 + 16 = 31
      expect(TimeUtils.isDayInBitmask(1, 31), isTrue);
      expect(TimeUtils.isDayInBitmask(3, 31), isTrue);
      expect(TimeUtils.isDayInBitmask(6, 31), isFalse);
    });
  });

  // Lưu ý: DateTime.now() sẽ trả về giờ hiện tại nên việc test calculateNextAlarmTime 
  // có thể thay đổi tùy thuộc vào thời điểm chạy test. 
  // Trong thực tế, cần sử dụng mock clock (như thư viện clock) để cố định thời gian.
  // Ở đây chúng ta test cơ bản dựa trên thời gian thực tế.
  
  group('TimeUtils - Alarm Time Calculation', () {
    test('Báo thức 1 lần (Không lặp) - Giờ trong tương lai gần (hôm nay)', () {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(hours: 1));
      
      final nextAlarm = TimeUtils.calculateNextAlarmTime(futureTime.hour, futureTime.minute, 0);
      
      expect(nextAlarm.day, now.day);
      expect(nextAlarm.hour, futureTime.hour);
      expect(nextAlarm.minute, futureTime.minute);
    });

    test('Báo thức 1 lần (Không lặp) - Giờ đã qua (chuyển sang ngày mai)', () {
      final now = DateTime.now();
      final pastTime = now.subtract(const Duration(hours: 1));
      
      final nextAlarm = TimeUtils.calculateNextAlarmTime(pastTime.hour, pastTime.minute, 0);
      
      final tomorrow = now.add(const Duration(days: 1));
      expect(nextAlarm.day, tomorrow.day);
      expect(nextAlarm.hour, pastTime.hour);
      expect(nextAlarm.minute, pastTime.minute);
    });

    test('Báo thức có lặp - Tìm ngày đúng trong tuần (bitmask)', () {
      // Thứ 5 (bitmask 8 = 1 << 3)
      final nextAlarm = TimeUtils.calculateNextAlarmTime(7, 0, 8);
      
      // Kiểm tra ngày báo thức là Thứ 5 (weekday 5)
      expect(TimeUtils.isDayInBitmask(nextAlarm.weekday, 8), isTrue);
      expect(nextAlarm.hour, 7);
      expect(nextAlarm.minute, 0);
    });

    test('Báo thức có lặp - Bỏ qua ngày hôm nay (skipNextDate)', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      // Báo thức lúc 23:00 hằng ngày (bitmask 127 = mọi ngày)
      // Bỏ qua hôm nay (giả sử bây giờ chưa tới 23:00)
      final skipDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final nextAlarm = TimeUtils.calculateNextAlarmTime(23, 0, 127, skipNextDate: skipDate);
      
      // Ngày hôm nay bị skip -> chuyển sang ngày mai
      expect(nextAlarm.day, isNot(now.day));
      expect(nextAlarm.day, tomorrow.day);
    });

    test('calculateSnoozeTime - Kêu lại sau đúng số phút', () {
      final now = DateTime.now();
      final snoozeTime = TimeUtils.calculateSnoozeTime(10);
      
      final difference = snoozeTime.difference(now).inMinutes;
      expect(difference, 10);
    });
  });
}
