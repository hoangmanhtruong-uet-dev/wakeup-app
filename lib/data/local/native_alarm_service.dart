import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cầu nối giao tiếp với Native (Kotlin / Swift) qua MethodChannel.
///
/// Channel: `com.wakeup.app/alarm`
///
/// ### Khác biệt giữa Android và iOS
/// - **Android**: `AlarmService` (Foreground Service) tự phát chuông, nên
///   [startRinging] là no-op.
/// - **iOS**: notification bị giới hạn ~30s, nên phải gọi [startRinging] để
///   `AlarmAudioPlayer` phát chuông lặp khi app đã mở `RingingScreen`.
class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('com.wakeup.app/alarm');

  /// Lập lịch báo thức ở Native.
  /// - [id] là ID của báo thức trong SQLite.
  /// - [time] là thời điểm chuông kêu (chuyển thành epoch ms khi gửi qua channel).
  /// - [label], [soundId], [volume] chỉ được iOS dùng; Android bỏ qua các tham số này.
  ///
  /// [hour], [minute], [repeatDays] là **đặc tả lặp lại** và là thông tin BẮT BUỘC:
  /// native cần chúng để tự tính lần kêu kế tiếp sau khi chuông vang, vì lúc đó
  /// Flutter engine có thể không chạy (Android) hoặc bị hệ thống cấm chạy nền (iOS).
  /// Thiếu 3 trường này thì báo thức lặp sẽ chỉ kêu đúng một lần rồi im.
  ///
  /// [autoStopMinutes] là thời gian tự dừng chuông nếu không có tương tác (yêu cầu F-07).
  /// Nếu không truyền, native sẽ reo vô hạn — rất hao pin và khó chịu.
  ///
  /// [chainLength] và [futureCount] là kế hoạch phân bổ notification cho iOS, do
  /// [IosNotificationBudget] tính sẵn vì iOS chỉ cho phép 64 notification đang chờ.
  /// Android không dùng hai tham số này.
  static Future<bool> scheduleAlarm({
    required int id,
    required DateTime time,
    required int hour,
    required int minute,
    required int repeatDays,
    int autoStopMinutes = 10,
    int chainLength = 10,
    int futureCount = 0,
    String? label,
    String? soundId,
    double volume = 1.0,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'id': id,
        'timeInMillis': time.millisecondsSinceEpoch,
        'hour': hour,
        'minute': minute,
        'repeatDays': repeatDays,
        'autoStopMinutes': autoStopMinutes,
        'chainLength': chainLength,
        'futureCount': futureCount,
        'label': label ?? '',
        'soundId': soundId ?? 'default',
        'volume': volume,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to schedule alarm: '${e.message}'.");
      return false;
    } on MissingPluginException {
      debugPrint('Failed to schedule alarm: native plugin chưa được đăng ký.');
      return false;
    }
  }

  /// Hủy một báo thức đã lập lịch.
  static Future<bool> cancelAlarm(int id) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'id': id,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to cancel alarm: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Dừng chuông đang kêu.
  /// Trên iOS còn huỷ luôn chuỗi notification còn sót nếu truyền [id].
  static Future<bool> stopRinging({int? id}) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('stopRinging', {
        if (id != null) 'id': id,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to stop ringing: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Bắt đầu phát chuông lặp khi màn hình đổ chuông đang mở.
  ///
  /// Chỉ có tác dụng thực sự trên iOS. Trên Android, Foreground Service đã tự phát
  /// chuông nên hàm này trả về `true` mà không làm gì.
  ///
  /// [autoStopMinutes] áp dụng cho cả 2 nền tảng: chuông sẽ tự tắt sau khoảng thời
  /// gian này nếu người dùng không tương tác. Thiếu cơ chế này thì chuông reo vô hạn.
  static Future<bool> startRinging({
    String? soundId,
    double volume = 1.0,
    int autoStopMinutes = 10,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('startRinging', {
        'soundId': soundId ?? 'alarm_default',
        'volume': volume,
        'autoStopMinutes': autoStopMinutes,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to start ringing: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Lấy danh sách id báo thức đã bị BỎ LỜ (tự tắt sau autoStopMinutes mà không ai
  /// tương tác), đồng thời XÓA danh sách đó ở native.
  ///
  /// Dart có thể không chạy lúc báo thức bị bỏ lỡ, nên native phải tự ghi lại vào bộ
  /// nhớ tạm. Hàm này được gọi mỗi khi app mở lên để đồng bộ lịch sử.
  static Future<List<int>> consumeMissedAlarms() async {
    try {
      final List<int>? result =
          await _channel.invokeListMethod<int>('getMissedAlarms');
      return result ?? <int>[];
    } on PlatformException catch (e) {
      debugPrint("Failed to get missed alarms: '${e.message}'.");
      return <int>[];
    } on MissingPluginException {
      return <int>[];
    }
  }

  /// Xin quyền gửi thông báo (bắt buộc với iOS — không có quyền thì báo thức không kêu).
  static Future<bool> requestNotificationPermission() async {
    try {
      final bool? granted =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to request notification permission: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Lấy alarm id nếu app được mở bởi thao tác bấm notification.
  /// Trả về `null` nếu app được mở bình thường.
  static Future<int?> getInitialAlarmPayload() async {
    try {
      return await _channel.invokeMethod<int>('getInitialAlarmPayload');
    } on PlatformException catch (e) {
      debugPrint("Failed to get initial alarm payload: '${e.message}'.");
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}