import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/utils/notification_budget.dart';
import '../../core/utils/time_utils.dart';
import '../local/database.dart';
import '../local/native_alarm_service.dart';

/// Nguồn sự thật duy nhất cho vòng đời lịch báo thức.
///
/// ## Vì sao cần một "người giữ lịch" tập trung?
/// Mọi thao tác lập lịch (thêm / sửa / bật-tắt / reschedule / re-arm) đều đi qua
/// [_schedule] để logic không bị lệch ở nhiều nơi.
///
/// ## Vì sao reschedule KHÔNG thể chỉ dựa vào Dart?
/// Khi chuông vang, Flutter engine có thể không chạy (Android: app đã bị kill /
/// đang ở chế độ nền bị hệ thống dọn), và iOS thì CẤM dịch code nền hoàn toàn.
/// Vì vậy:
/// - **Native tự lập lịch tiếp theo** là lớp bảo vệ chính (xem AlarmTriggerReceiver.kt
///   và AlarmScheduler.swift). Đó là lý do [scheduleAlarm] bắt buộc truyền kèm
///   hour / minute / repeatDays.
/// - **Dart reschedule** ([rescheduleAfterFire], [rearmEnabledAlarms]) là lớp bổ sung:
///   ghi lịch sử, và bù lại cho các trường hợp native chưa tự lấy lại được.
class AlarmRepository {
  final AppDatabase _db;

  AlarmRepository(this._db);

  // ---------------------------------------------------------------------
  // Theo dõi
  // ---------------------------------------------------------------------

  /// Lấy danh sách tất cả báo thức theo dạng Stream (tự động cập nhật UI)
  Stream<List<Alarm>> watchAlarms() {
    return _db.watchAllAlarms();
  }

  /// Lấy lịch sử đổ chuông của một báo thức, mới nhất trước.
  Future<List<AlarmEvent>> getHistory(int alarmId) {
    return _db.getEventsForAlarm(alarmId);
  }

  // ---------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------

  /// Thêm báo thức mới
  Future<void> addAlarm(AlarmsCompanion alarmCompanion) async {
    final id = await _db.insertAlarm(alarmCompanion);

    final isEnabled =
        alarmCompanion.enabled.present ? alarmCompanion.enabled.value : true;
    if (!isEnabled) return;

    await _schedule(
      id: id,
      hour: alarmCompanion.hour.value,
      minute: alarmCompanion.minute.value,
      repeatDays: alarmCompanion.repeatDays.present
          ? alarmCompanion.repeatDays.value
          : 0,
      skipNextDate: alarmCompanion.skipNextDate.present
          ? alarmCompanion.skipNextDate.value
          : null,
      label: alarmCompanion.label.present ? alarmCompanion.label.value : null,
      soundId: alarmCompanion.soundId.present
          ? alarmCompanion.soundId.value
          : null,
      volume: alarmCompanion.volume.present ? alarmCompanion.volume.value : 1.0,
      autoStopMinutes: alarmCompanion.autoStopMinutes.present
          ? alarmCompanion.autoStopMinutes.value
          : 10,
    );
  }

  /// Cập nhật báo thức hiện có
  Future<void> updateAlarm(Alarm alarm) async {
    // 1. Cập nhật DB
    await _db.updateAlarm(alarm);

    // 2. Hủy lịch cũ ở OS (luôn hủy để tránh báo thức ảo)
    await NativeAlarmService.cancelAlarm(alarm.id);

    // 3. Nếu bật, lập lịch mới
    if (alarm.enabled) {
      await _schedule(
        id: alarm.id,
        hour: alarm.hour,
        minute: alarm.minute,
        repeatDays: alarm.repeatDays,
        skipNextDate: alarm.skipNextDate,
        label: alarm.label,
        soundId: alarm.soundId,
        volume: alarm.volume,
        autoStopMinutes: alarm.autoStopMinutes,
      );
    }
  }

  /// Bật / Tắt nhanh một báo thức (Toggle)
  Future<void> toggleAlarm(Alarm alarm, bool isEnabled) async {
    final updatedAlarm = alarm.copyWith(enabled: isEnabled);
    await updateAlarm(updatedAlarm);
  }

  /// Xóa báo thức (kèm lịch sử)
  Future<void> deleteAlarm(int id) async {
    // 1. Hủy trên OS
    await NativeAlarmService.cancelAlarm(id);

    // 2. Xóa khỏi DB (cascade xóa lịch sử)
    await _db.deleteAlarm(id);
  }

  // ---------------------------------------------------------------------
  // Reschedule — phần cốt lõi được thêm trong Giai đoạn 2
  // ---------------------------------------------------------------------

  /// Gọi sau khi chuông đã kêu và người dùng đã xử lý (tắt / báo lại).
  ///
  /// - Ghi 1 dòng vào lịch sử đổ chuông.
  /// - Nếu báo thức **lặp** (repeatDays != 0) và vẫn còn bật -> lập lịch cho lần kêu
  ///   kế tiếp. Đây chính là thứ trước đây còn thiếu, khiến báo thức "hàng ngày"
  ///   chỉ kêu đúng một lần rồi im.
  /// - Nếu báo thức **một lần** (repeatDays == 0) -> KHÔNG lập lại, đúng như ý nghĩa
  ///   của chế độ "không lặp".
  ///
  /// [firedAt] là thời điểm dự kiến chuông vang, dùng làm mốc để tìm lần kế tiếp.
  Future<void> rescheduleAfterFire(
    int alarmId, {
    required DateTime firedAt,
    String action = 'dismissed',
    int snoozeCount = 0,
  }) async {
    // 1. Ghi lịch sử (không chặn luồng reschedule nếu ghi log lỗi)
    try {
      await _db.insertAlarmEvent(
        AlarmEventsCompanion.insert(
          alarmId: alarmId,
          scheduledAt: firedAt,
          firedAt: DateTime.now(),
          action: action,
          snoozeCount: Value(snoozeCount),
        ),
      );
    } catch (_) {
      // Không ghi được lịch sử không được làm hỏng việc lập lịch tiếp theo.
    }

    // 2. Báo thức có còn tồn tại / còn bật không?
    final Alarm? alarm = await _getAlarmOrNull(alarmId);
    if (alarm == null) return;
    if (!alarm.enabled) return;
    if (alarm.repeatDays == 0) return; // báo thức một lần: xong việc

    // 3. Lập lịch cho lần kêu kế tiếp
    await _schedule(
      id: alarm.id,
      hour: alarm.hour,
      minute: alarm.minute,
      repeatDays: alarm.repeatDays,
      skipNextDate: alarm.skipNextDate,
      label: alarm.label,
      soundId: alarm.soundId,
      volume: alarm.volume,
      autoStopMinutes: alarm.autoStopMinutes,
      after: firedAt,
    );
  }

  /// Lập lại lịch cho TOÀN BỘ báo thức đang bật.
  ///
  /// Gọi khi app khởi động / quay lại foreground. Mục đích: bù lại cho các trường hợp
  /// mà lịch ở tầng OS bị mất (ví dụ người dùng dọn app trên một số hệ điều hành,
  /// hoặc native chưa kịp tự lập lại sau khi chuông kêu).
  ///
  /// Trả về số báo thức đã lập lại lịch thành công.
  Future<int> rearmEnabledAlarms() async {
    final alarms = await _db.getAllAlarms();
    final enabled = alarms.where((a) => a.enabled).toList();

    int rearmed = 0;
    for (final alarm in enabled) {
      final ok = await _schedule(
        id: alarm.id,
        hour: alarm.hour,
        minute: alarm.minute,
        repeatDays: alarm.repeatDays,
        skipNextDate: alarm.skipNextDate,
        label: alarm.label,
        soundId: alarm.soundId,
        volume: alarm.volume,
        autoStopMinutes: alarm.autoStopMinutes,
        // Đã biết số báo thức đang bật -> tránh truy vấn lặp lại N lần.
        activeAlarmCount: enabled.length,
      );
      if (ok) rearmed++;
    }
    return rearmed;
  }

  /// Lập lịch cho một báo thức khác sau khi bấm "Báo lại".
  ///
  /// Báo lại KHÔNG thay thế lần kêu định kỳ — nó chỉ là một lần kêu bổ sung.
  /// Vì vậy ta dùng một ID tạm (`id + snoozeIdOffset`) để không đè lên lịch định kỳ,
  /// đồng thời vẫn gọi [rescheduleAfterFire] để lấy lại lần kêu kế tiếp.
  Future<void> snooze(
    int alarmId, {
    required DateTime firedAt,
    int? minutes,
  }) async {
    final Alarm? alarm = await _getAlarmOrNull(alarmId);
    if (alarm == null) return;

    final snoozeMinutes = minutes ?? alarm.snoozeMinutes;
    final nextSnoozeAt =
        TimeUtils.calculateSnoozeTime(snoozeMinutes);

    // Báo lại là lần kêu MỘT LẦN -> không hẹn trước lần nào, chỉ cần chuỗi để vang.
    final snoozePlan = IosNotificationBudget.plan(
      activeAlarmCount: await _countEnabledAlarms(),
      autoStopMinutes: alarm.autoStopMinutes,
      isRepeating: false,
    );

    // 1. Lịch bổ sung dùng ID tạm để không đè lên lịch định kỳ.
    await NativeAlarmService.scheduleAlarm(
      id: alarmId + snoozeIdOffset,
      time: nextSnoozeAt,
      hour: nextSnoozeAt.hour,
      minute: nextSnoozeAt.minute,
      repeatDays: 0,
      label: alarm.label,
      soundId: alarm.soundId,
      volume: alarm.volume,
      autoStopMinutes: alarm.autoStopMinutes,
      chainLength: snoozePlan.chainLength,
      futureCount: 0,
    );

    // 2. Vẫn phải lấy lại lần kêu định kỳ kế tiếp.
    await rescheduleAfterFire(
      alarmId,
      firedAt: firedAt,
      action: 'snoozed',
      snoozeCount: 1,
    );
  }

  /// Ghi nhận báo thức bị bỏ lỡ (tự tắt sau autoStopMinutes mà không ai thao tác).
  Future<void> logMissed(int alarmId, {required DateTime firedAt}) async {
    final Alarm? alarm = await _getAlarmOrNull(alarmId);
    if (alarm == null) return;
    if (alarm.repeatDays == 0) return;

    await rescheduleAfterFire(alarmId, firedAt: firedAt, action: 'missed');
  }

  // ---------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------

  /// Offset cho ID của báo thức "báo lại". Khoảng cách đủ lớn để không trùng với
  /// id thật trong SQLite (id hiện là AUTOINCREMENT, nên rất nhỏ).
  static const int snoozeIdOffset = 1000000;

  /// Tính lần kêu tiếp theo rồi đẩy xuống OS.
  ///
  /// Đây là **điểm vào duy nhất** để lập lịch trong toàn bộ app.
  /// [after] cho phép tính "lần kế tiếp sau một mốc đã kêu" (dùng cho reschedule).
  /// Trả về `true` nếu đẩy lịch xuống OS thành công.
  Future<bool> _schedule({
    required int id,
    required int hour,
    required int minute,
    required int repeatDays,
    String? skipNextDate,
    String? label,
    String? soundId,
    double volume = 1.0,
    int autoStopMinutes = 10,
    DateTime? after,
    int? activeAlarmCount,
  }) async {
    final nextTime = TimeUtils.calculateNextAlarmTime(
      hour,
      minute,
      repeatDays,
      skipNextDate: skipNextDate,
      after: after,
    );

    // iOS chỉ nhận tối đa 64 notification đang chờ. Phải chia ngân sách giữa các
    // báo thức, nếu không thì báo thức tạo sau sẽ bị iOS từ chối âm thầm.
    final count = activeAlarmCount ?? await _countEnabledAlarms();
    final plan = IosNotificationBudget.plan(
      activeAlarmCount: count,
      autoStopMinutes: autoStopMinutes,
      isRepeating: repeatDays != 0,
    );

    return NativeAlarmService.scheduleAlarm(
      id: id,
      time: nextTime,
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      autoStopMinutes: autoStopMinutes,
      chainLength: plan.chainLength,
      futureCount: plan.futureCount,
      label: label,
      soundId: soundId,
      volume: volume,
    );
  }

  /// Đếm số báo thức đang bật — dùng làm mẫu số khi chia ngân sách notification iOS.
  Future<int> _countEnabledAlarms() async {
    final alarms = await _db.getAllAlarms();
    return alarms.where((a) => a.enabled).length;
  }

  /// Thu thập các báo thức bị BỎ LỜ mà Dart chưa kịp ghi nhận.
  ///
  /// Khi chuông tự tắt sau `autoStopMinutes`, native ghi lại id vào bộ nhớ tạm vì lúc đó
  /// Dart có thể không chạy. Hàm này được gọi mỗi khi app mở lên để đồng bộ lịch sử.
  /// Trả về số báo thức đã ghi nhận.
  Future<int> syncMissedAlarms() async {
    final missedIds = await NativeAlarmService.consumeMissedAlarms();
    if (missedIds.isEmpty) return 0;

    int logged = 0;
    final now = DateTime.now();
    for (final id in missedIds) {
      try {
        // Báo thức có thể đã bị xoá trong lúc app đang đóng -> bỏ qua.
        // Kiểm tra tường minh thay vì trông chờ vào ngoại lệ khoá ngoại, vì
        // SQLite chỉ kiểm tra khoá ngoại khi bật PRAGMA foreign_keys.
        if (await _getAlarmOrNull(id) == null) continue;

        // Ghi lịch sử. Không gọi rescheduleAfterFire vì native đã tự lập lịch lần
        // kế tiếp rồi; gọi lại chỉ gây hủy/tạo lại lịch thừa.
        await _db.insertAlarmEvent(
          AlarmEventsCompanion.insert(
            alarmId: id,
            scheduledAt: now,
            firedAt: now,
            action: 'missed',
          ),
        );
        logged++;
      } catch (_) {
        // Không ghi được thì bỏ qua, không được làm hỏng vòng đồng bộ.
      }
    }
    return logged;
  }

  Future<Alarm?> _getAlarmOrNull(int id) async {
    try {
      return await _db.getAlarm(id);
    } catch (_) {
      // getSingle() ném lỗi nếu không tìm thấy.
      return null;
    }
  }

  /// Hủy toàn bộ báo thức native và xóa sạch CSDL (dùng cho Xóa tài khoản / Full Wipe).
  Future<void> wipeAllData() async {
    try {
      final allAlarms = await _db.getAllAlarms();
      for (final alarm in allAlarms) {
        try {
          await NativeAlarmService.cancelAlarm(alarm.id);
        } catch (e) {
          debugPrint('[WakeUp] Lỗi huỷ native alarm ${alarm.id}: $e');
        }
      }
      await _db.clearAllData();
    } catch (e) {
      debugPrint('[WakeUp] Lỗi khi thực hiện wipeAllData: $e');
    }
  }
}