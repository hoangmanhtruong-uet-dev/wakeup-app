/// Phân bổ ngân sách notification trên iOS.
///
/// ## Vì sao cần?
/// iOS chỉ cho phép **64 notification đang chờ** cho mỗi app. Nếu vượt quá, các
/// notification mới sẽ bị hệ thống từ chối trong im lặng — và báo thức sẽ không kêu
/// mà người dùng không hề biết.
///
/// Trước đây mỗi báo thức dùng cố định ~60 notification (chuỗi 40 + 20 lần kêu tương lai).
/// Chỉ cần **hai** báo thức là vượt hạn mức và các báo thức sau sẽ bị âm thầm bỏ qua.
///
/// ## Nguyên tắc phân bổ
/// 1. **Lần kêu ngay tới quan trọng nhất** — luôn phải có chuỗi để chuông vang.
/// 2. Chia đều ngân sách theo số báo thức đang bật, báo thức nào cũng phải được hứa
///    như nhau, không để báo thức nào "chiếm hết".
/// 3. Phần dư dùng để hẹn trước các lần kêu tương lai, mỗi lần dùng 2 notification
///    (1 thông báo + 1 nốt để kéo dài âm thanh).
library;

class NotificationBudgetPlan {
  /// Số notification cho chuỗi "kêu liên tục" của lần kêu ngay tới.
  final int chainLength;

  /// Số lần kêu tương lai được hẹn trước (báo thức lặp).
  final int futureCount;

  /// Ngân sách tính được cho báo thức này.
  final int perAlarmBudget;

  /// Tổng số notification thực sự sẽ tạo ra.
  final int totalPlanned;

  const NotificationBudgetPlan({
    required this.chainLength,
    required this.futureCount,
    required this.perAlarmBudget,
    required this.totalPlanned,
  });

  @override
  String toString() =>
      'NotificationBudgetPlan(chain: $chainLength, future: $futureCount, '
      'perAlarm: $perAlarmBudget, total: $totalPlanned)';
}

class IosNotificationBudget {
  IosNotificationBudget._();

  /// Hạn mức cứng của iOS.
  static const int limit = 64;

  /// Chừa chỗ cho các notification khác mà app có thể dùng.
  static const int safetyMargin = 4;

  /// Mỗi notification của iOS chỉ kêu được khoảng 30 giây.
  static const int secondsPerNotification = 30;

  /// Trần cho chuỗi của lần kêu ngay tới (~5 phút).
  ///
  /// Không nên dùng cả 20 notification cho chuỗi vì sẽ "ăn" hết ngân sách và các
  /// lần kêu tương lai mất sạch — mà mất lần kêu tương lai còn tệ hơn là chuỗi
  /// ngắn lại, vì Dart sẽ lấp lại khi app mở còn chuỗi thì không.
  static const int maxChainLength = 10;

  /// Chi phí cho MỘT lần kêu tương lai: 1 thông báo + 1 nốt kéo dài âm thanh.
  static const int futureOccurrenceCost = 2;

  /// Tính kế hoạch cho một báo thức.
  ///
  /// [activeAlarmCount] là số báo thức đang được bật. [isRepeating] = false
  /// (báo thức một lần) thì không hẹn trước lần kêu nào.
  static NotificationBudgetPlan plan({
    required int activeAlarmCount,
    required int autoStopMinutes,
    required bool isRepeating,
  }) {
    const usable = limit - safetyMargin;
    final alarms = activeAlarmCount < 1 ? 1 : activeAlarmCount;

    // Chia đều. Dùng phép chia nguyên; phần dư bỏ lại vẫn an toàn.
    final perAlarm = usable ~/ alarms;

    // Số notification cần để chuông vang đúng autoStopMinutes.
    final needed = (autoStopMinutes * 60) ~/ secondsPerNotification;

    // Chuỗi không vượt quá trần, và không vượt ngân sách riêng của báo thức này.
    var chain = needed < maxChainLength ? needed : maxChainLength;
    if (chain > perAlarm) chain = perAlarm;
    if (chain < 0) chain = 0;

    // Báo thức một lần không hẹn trước gì cả.
    if (!isRepeating) {
      return NotificationBudgetPlan(
        chainLength: chain,
        futureCount: 0,
        perAlarmBudget: perAlarm,
        totalPlanned: chain,
      );
    }

    final remaining = perAlarm - chain;
    final future = remaining < 0 ? 0 : remaining ~/ futureOccurrenceCost;

    return NotificationBudgetPlan(
      chainLength: chain,
      futureCount: future,
      perAlarmBudget: perAlarm,
      totalPlanned: chain + future * futureOccurrenceCost,
    );
  }
}