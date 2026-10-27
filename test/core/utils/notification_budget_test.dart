import 'package:flutter_test/flutter_test.dart';

import 'package:wakeup_app/core/utils/notification_budget.dart';

/// Test cho chính sách phân bổ hạn mức 64 notification của iOS.
///
/// Bug gốc: mỗi báo thức dùng cố định ~60 notification. Chỉ cần 2 báo thức là vượt
/// hạn mức, các notification mới sẽ bị iOS từ chối trong im lặng.
void main() {
  group('Bất biến quan trọng nhất: KHÔNG BAO GIỜ vượt hạn mức', () {
    test('tổng notification mọi báo thức luôn <= 60', () {
      for (int alarms = 1; alarms <= 20; alarms++) {
        for (final autoStop in <int>[1, 5, 10, 15, 30]) {
          final plan = IosNotificationBudget.plan(
            activeAlarmCount: alarms,
            autoStopMinutes: autoStop,
            isRepeating: true,
          );
          final total = plan.totalPlanned * alarms;

          expect(
            total,
            lessThanOrEqualTo(IosNotificationBudget.limit - IosNotificationBudget.safetyMargin),
            reason: '$alarms báo thức x autoStop=$autoStop phải tạo tổng <= 60, '
                'nhưng đang tính ra $total',
          );
        }
      }
    });

    test('tổng cho 2 báo thức nằm gọn trong hạn mức', () {
      final a = IosNotificationBudget.plan(
          activeAlarmCount: 2, autoStopMinutes: 15, isRepeating: true);
      final b = IosNotificationBudget.plan(
          activeAlarmCount: 2, autoStopMinutes: 15, isRepeating: true);

      expect(a.totalPlanned + b.totalPlanned,
          lessThanOrEqualTo(IosNotificationBudget.limit));
    });
  });

  group('Công bằng: mọi báo thức phải được phân bổ như nhau', () {
    test('không báo thức nào chiếm hết ngân sách', () {
      final first = IosNotificationBudget.plan(
          activeAlarmCount: 3, autoStopMinutes: 10, isRepeating: true);
      final second = IosNotificationBudget.plan(
          activeAlarmCount: 3, autoStopMinutes: 10, isRepeating: true);
      final third = IosNotificationBudget.plan(
          activeAlarmCount: 3, autoStopMinutes: 10, isRepeating: true);

      expect(second.totalPlanned, first.totalPlanned);
      expect(third.totalPlanned, first.totalPlanned);
      expect(second.futureCount, greaterThan(0),
          reason: 'Báo thức thứ 2 phải vẫn có lần kêu tương lai, không bị báo thức đầu ăn hết');
    });

    test('ngân sách chia đều giảm dần khi số báo thức tăng', () {
      final sizes = <int>[1, 2, 4, 8, 16].map((n) {
        return IosNotificationBudget.plan(
                activeAlarmCount: n, autoStopMinutes: 10, isRepeating: true)
            .perAlarmBudget;
      }).toList();

      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i], lessThanOrEqualTo(sizes[i - 1]),
            reason: 'perAlarmBudget phải đơn điệu giảm');
      }
    });
  });

  group('Lần kêu ngay tới luôn được ưu tiên', () {
    test('luôn có ít nhất 1 notification cho chuỗi', () {
      for (int alarms = 1; alarms <= 40; alarms++) {
        final plan = IosNotificationBudget.plan(
            activeAlarmCount: alarms, autoStopMinutes: 10, isRepeating: true);
        expect(plan.chainLength, greaterThan(0),
            reason: 'với $alarms báo thức, lần kêu ngay tới vẫn phải vang được');
      }
    });

    test('chuỗi bị chặn trên 10 dù autoStop dài hơn', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 60, isRepeating: true);

      expect(plan.chainLength, IosNotificationBudget.maxChainLength);
      expect(plan.futureCount, greaterThan(0),
          reason: 'Phần dư phải dùng để hẹn lần kêu tương lai, không phải để kéo dài chuỗi');
    });

    test('autoStop ngắn thì chuỗi ngắn theo, không bị làm phình', () {
      final short = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 1, isRepeating: true);
      expect(short.chainLength, 2, reason: '1 phút = 2 notification x 30s');

      final longer = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 10, isRepeating: true);
      expect(longer.chainLength, greaterThan(short.chainLength));
    });
  });

  group('Báo thức MỘT LẦN', () {
    test('không hẹn trước lần kêu tương lai nào', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 10, isRepeating: false);

      expect(plan.futureCount, 0);
      expect(plan.totalPlanned, plan.chainLength);
    });
  });

  group('Trường hợp biên', () {
    test('autoStop bằng 0 vẫn không sinh notification âm', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 0, isRepeating: true);
      expect(plan.chainLength, greaterThanOrEqualTo(0));
      expect(plan.totalPlanned, greaterThanOrEqualTo(0));
    });

    test('số báo thức bằng 0 vẫn cho kế hoạch hợp lệ', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 0, autoStopMinutes: 10, isRepeating: true);

      expect(plan.perAlarmBudget, greaterThan(0));
      expect(plan.totalPlanned, greaterThan(0));
    });

    test('rất nhiều báo thức vẫn không vượt hạn mức', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 50, autoStopMinutes: 10, isRepeating: true);

      expect(plan.totalPlanned * 50,
          lessThanOrEqualTo(IosNotificationBudget.limit));
    });
  });

  group('Ví dụ thực tế', () {
    test('1 báo thức hàng ngày, autoStop 10 phút', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 1, autoStopMinutes: 10, isRepeating: true);

      expect(plan.chainLength, 10);
      expect(plan.futureCount, 25,
          reason: '50 notification còn lại / 2 = 25 ngày hẹn trước');
      expect(plan.totalPlanned, 60);
    });

    test('2 báo thức hàng ngày, autoStop 10 phút', () {
      final plan = IosNotificationBudget.plan(
          activeAlarmCount: 2, autoStopMinutes: 10, isRepeating: true);

      expect(plan.chainLength, 10);
      expect(plan.futureCount, 10, reason: 'mỗi báo thức còn 20 notification / 2 = 10 ngày');
      expect(plan.totalPlanned, 30);
    });
  });
}