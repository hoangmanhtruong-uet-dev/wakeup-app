import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wakeup_app/data/local/database.dart';
import 'package:wakeup_app/data/repositories/alarm_repository.dart';

/// Test hồi quy cho lỗi "báo thức lặp chỉ kêu đúng một lần rồi im".
///
/// Trước Giai đoạn 2, không có tầng nào lập lại lịch sau khi chuông vang, nên một
/// báo thức "7:00 hàng ngày" sẽ kêu đúng một lần rồi im luôn.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.wakeup.app/alarm');

  late AppDatabase db;
  late AlarmRepository repo;
  late List<MethodCall> calls;

  /// Danh sách id mà native giả lập trả về cho `getMissedAlarms`.
  List<int> missedFromNative = <int>[];

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AlarmRepository(db);
    calls = <MethodCall>[];
    missedFromNative = <int>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      if (call.method == 'getMissedAlarms') return missedFromNative;
      return true;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
  });

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Các lệnh scheduleAlarm đã gửi xuống OS.
  List<Map<Object?, Object?>> scheduleCalls() => calls
      .where((c) => c.method == 'scheduleAlarm')
      .map((c) => (c.arguments as Map).cast<Object?, Object?>())
      .toList();

  /// Thời điểm được lập lịch gần nhất (epoch ms).
  int? lastScheduledMillis() {
    final s = scheduleCalls();
    if (s.isEmpty) return null;
    return s.last['timeInMillis'] as int;
  }

  Future<int> insertAlarm({
    required int hour,
    required int minute,
    int repeatDays = 127,
    bool enabled = true,
    String? label,
    int snoozeMinutes = 5,
    bool missionEnabled = false,
    String missionType = 'math',
    String missionDifficulty = 'medium',
  }) {
    return db.insertAlarm(
      AlarmsCompanion.insert(
        hour: hour,
        minute: minute,
        repeatDays: Value(repeatDays),
        enabled: Value(enabled),
        label: Value(label),
        snoozeMinutes: Value(snoozeMinutes),
        missionEnabled: Value(missionEnabled),
        missionType: Value(missionType),
        missionDifficulty: Value(missionDifficulty),
      ),
    );
  }

  DateTime dt(int y, int m, int d, int hh, int mm) => DateTime(y, m, d, hh, mm);

  // ---------------------------------------------------------------------
  // Reschedule sau khi báo thức kêu
  // ---------------------------------------------------------------------

  group('rescheduleAfterFire — báo thức LẶP', () {
    test('báo thức hàng ngày kêu 07:00 -> lập lại cho 07:00 hôm sau', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      // 2026-10-18 là Chủ nhật.
      final firedAt = dt(2026, 10, 18, 7, 0);
      await repo.rescheduleAfterFire(id, firedAt: firedAt, action: 'dismissed');

      expect(scheduleCalls(), hasLength(1));
      expect(
        lastScheduledMillis(),
        dt(2026, 10, 19, 7, 0).millisecondsSinceEpoch,
        reason: 'Báo thức hàng ngày phải được lập lại cho ngày mai, không phải hôm nay',
      );
    });

    test('lần kế tiếp LUÔN nằm sau thời điểm đã kêu', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      final firedAt = dt(2026, 10, 18, 7, 0);

      await repo.rescheduleAfterFire(id, firedAt: firedAt);

      final scheduledAt = DateTime.fromMillisecondsSinceEpoch(lastScheduledMillis()!);
      expect(scheduledAt.isAfter(firedAt), isTrue);
    });

    test('báo thức chỉ lặp Thứ 5 -> lập lại cho tuần sau', () async {
      // repeatDays = 8 -> bitmask cho Thứ 5 (Dart weekday 4 -> 1 << 3).
      final id = await insertAlarm(hour: 7, minute: 0, repeatDays: 8);

      // 2026-10-22 là Thứ 5.
      final firedAt = dt(2026, 10, 22, 7, 0);
      expect(firedAt.weekday, DateTime.thursday);

      await repo.rescheduleAfterFire(id, firedAt: firedAt);

      final scheduledAt = DateTime.fromMillisecondsSinceEpoch(lastScheduledMillis()!);
      expect(scheduledAt.weekday, DateTime.thursday);
      expect(scheduledAt.isAfter(firedAt), isTrue);
      expect(scheduledAt.difference(firedAt).inDays, 7);
    });

    test('người dùng tắt trễ vẫn ra đúng ngày kế tiếp', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      // Người dùng tắt lúc 07:45 (đã quá giờ hôm nay).
      final firedAt = dt(2026, 10, 18, 7, 45);
      await repo.rescheduleAfterFire(id, firedAt: firedAt);

      expect(
        lastScheduledMillis(),
        dt(2026, 10, 19, 7, 0).millisecondsSinceEpoch,
        reason: 'Tắt trễ trong ngày vẫn phải ra ngày mai, không được lặp lại hôm nay',
      );
    });

    test('lập lại có mang theo đặc tả lặp lại cho native', () async {
      final id = await insertAlarm(hour: 6, minute: 30, repeatDays: 31);

      await repo.rescheduleAfterFire(id, firedAt: dt(2026, 10, 18, 6, 30));

      final s = scheduleCalls().single;
      expect(s['hour'], 6);
      expect(s['minute'], 30);
      expect(s['repeatDays'], 31);
    });

    test('ghi được dòng lịch sử đổ chuông', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      final firedAt = dt(2026, 10, 18, 7, 0);

      await repo.rescheduleAfterFire(id, firedAt: firedAt, action: 'dismissed');

      final events = await repo.getHistory(id);
      expect(events, hasLength(1));
      expect(events.first.action, 'dismissed');
      expect(events.first.scheduledAt, firedAt);
    });
  });

  group('rescheduleAfterFire — KHÔNG được lập lại', () {
    test('báo thức MỘT LẦN (repeatDays = 0) thì không lặp', () async {
      final id = await insertAlarm(hour: 7, minute: 0, repeatDays: 0);

      await repo.rescheduleAfterFire(id, firedAt: dt(2026, 10, 18, 7, 0));

      expect(
        scheduleCalls(),
        isEmpty,
        reason: 'Báo thức "không lặp" kêu xong thì phải kết thúc, không được tự lặp lại',
      );
    });

    test('báo thức đã bị TẮT thì không lập lại', () async {
      final id = await insertAlarm(hour: 7, minute: 0, enabled: false);

      await repo.rescheduleAfterFire(id, firedAt: dt(2026, 10, 18, 7, 0));

      expect(scheduleCalls(), isEmpty);
    });

    test('alarmId không tồn tại thì không ném lỗi', () async {
      await repo.rescheduleAfterFire(9999, firedAt: dt(2026, 10, 18, 7, 0));

      expect(scheduleCalls(), isEmpty);
    });
  });

  group('snooze', () {
    test('lập lịch bổ sung VÀ lấy lại lịch định kỳ', () async {
      final id = await insertAlarm(hour: 7, minute: 0, snoozeMinutes: 5);

      await repo.snooze(id, firedAt: dt(2026, 10, 18, 7, 0));

      final s = scheduleCalls();
      expect(s, hasLength(2),
          reason: 'Snooze phải tạo lần kêu bổ sung và giữ lại lần định kỳ kế tiếp');

      // Lần định kỳ kế tiếp dùng ID thật.
      final recurring = s.firstWhere((c) => c['id'] == id);
      expect(recurring['timeInMillis'],
          dt(2026, 10, 19, 7, 0).millisecondsSinceEpoch);

      // Lần báo lại dùng ID tạm để không đè lên lịch định kỳ.
      final snoozed = s.firstWhere((c) => c['id'] == id + AlarmRepository.snoozeIdOffset);
      expect(snoozed['id'], isNot(id));
    });

    test('báo lại không ghi đè lịch định kỳ', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      await repo.snooze(id, firedAt: dt(2026, 10, 18, 7, 0));

      final ids = scheduleCalls().map((c) => c['id']).toSet();
      expect(ids, hasLength(2),
          reason: 'Báo lại phải dùng ID riêng, không được trùng ID với lịch định kỳ');
    });

    test('ghi lịch sử với action = snoozed', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      await repo.snooze(id, firedAt: dt(2026, 10, 18, 7, 0));

      final events = await repo.getHistory(id);
      expect(events, hasLength(1));
      expect(events.first.action, 'snoozed');
      expect(events.first.snoozeCount, 1);
    });
  });

  group('rearmEnabledAlarms', () {
    test('lập lại lịch cho toàn bộ báo thức đang bật', () async {
      await insertAlarm(hour: 7, minute: 0);
      await insertAlarm(hour: 22, minute: 30);
      await insertAlarm(hour: 9, minute: 0, enabled: false);

      final count = await repo.rearmEnabledAlarms();

      expect(count, 2);
      expect(scheduleCalls(), hasLength(2));
    });

    test('lập lại lịch cho cả báo thức MỘT LẦN', () async {
      await insertAlarm(hour: 7, minute: 0, repeatDays: 0);

      final count = await repo.rearmEnabledAlarms();

      expect(count, 1,
          reason: 'Báo thức một lần vẫn phải được lập lại khi app mở, nếu không nó sẽ mất');
    });
  });

  group('autoStop — truyền thời gian tự dừng xuống native', () {
    test('lập lịch mới luôn mang autoStopMinutes', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      await repo.updateAlarm((await db.getAlarm(id)).copyWith(autoStopMinutes: 15));

      expect(scheduleCalls().last['autoStopMinutes'], 15);
    });

    test('giữ autoStopMinutes khi reschedule sau khi kêu', () async {
      final id = await insertAlarm(hour: 7, minute: 0);

      await repo.rescheduleAfterFire(id, firedAt: dt(2026, 10, 18, 7, 0));

      expect(scheduleCalls().last['autoStopMinutes'], 15,
          reason: 'autoStopMinutes mặc định của schema là 15 phút');
    });

    test('lập lại lịch khi app mở cũng mang autoStopMinutes', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      await repo.updateAlarm((await db.getAlarm(id)).copyWith(autoStopMinutes: 5));
      calls.clear();

      await repo.rearmEnabledAlarms();

      expect(scheduleCalls().single['autoStopMinutes'], 5);
    });
  });

  group('syncMissedAlarms — đồng bộ báo thức bị bỏ lỡ', () {
    test('ghi lịch sử cho mỗi báo thức native báo bị bỏ lỡ', () async {
      final id1 = await insertAlarm(hour: 7, minute: 0);
      final id2 = await insertAlarm(hour: 8, minute: 0);
      missedFromNative = <int>[id1, id2];

      final count = await repo.syncMissedAlarms();

      expect(count, 2);
      expect((await repo.getHistory(id1)).single.action, 'missed');
      expect((await repo.getHistory(id2)).single.action, 'missed');
    });

    test('KHÔNG lập lại lịch khi đồng bộ bỏ lỡ', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      missedFromNative = <int>[id];
      calls.clear();

      await repo.syncMissedAlarms();

      expect(scheduleCalls(), isEmpty,
          reason: 'Native đã tự lập lịch lần kế tiếp rồi; Dart chỉ ghi lịch sử, '
              'gọi lại sẽ gây hủy/tạo lại lịch thừa');
    });

    test('gọi getMissedAlarms của native', () async {
      await repo.syncMissedAlarms();

      expect(calls.any((c) => c.method == 'getMissedAlarms'), isTrue);
    });

    test('không có báo thức bỏ lỡ thì trả về 0', () async {
      await repo.syncMissedAlarms();

      final logged = await repo.syncMissedAlarms();
      expect(logged, 0);
    });

    test('bỏ qua báo thức đã bị xóa khỏi DB', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      await db.deleteAlarm(id);
      missedFromNative = <int>[id];

      final logged = await repo.syncMissedAlarms();

      expect(logged, 0, reason: 'Báo thức không còn trong DB thì không ghi được lịch sử');
    });
  });

  group('Ngân sách notification iOS — truyền xuống native', () {
    test('kế hoạch luôn được gửi kèm khi lập lịch', () async {
      await insertAlarm(hour: 7, minute: 0);

      await repo.rearmEnabledAlarms();

      final s = scheduleCalls().single;
      expect(s['chainLength'], isA<int>());
      expect(s['futureCount'], isA<int>());
    });

    test('1 báo thức: nhận gần hết ngân sách', () async {
      await insertAlarm(hour: 7, minute: 0);

      await repo.rearmEnabledAlarms();

      final s = scheduleCalls().single;
      final used = (s['chainLength'] as int) + 2 * (s['futureCount'] as int);
      expect(used, lessThanOrEqualTo(60));
      expect(s['futureCount'] as int, greaterThan(0),
          reason: 'báo thức hàng ngày phải được hẹn trước ít nhất vài ngày');
    });

    test('2 báo thức: KHÔNG báo thức nào ăn hết — tổng vẫn <= 60', () async {
      await insertAlarm(hour: 7, minute: 0);
      await insertAlarm(hour: 22, minute: 0);

      await repo.rearmEnabledAlarms();

      final calls = scheduleCalls();
      expect(calls, hasLength(2));

      var total = 0;
      for (final c in calls) {
        total += (c['chainLength'] as int) + 2 * (c['futureCount'] as int);
      }
      expect(total, lessThanOrEqualTo(60),
          reason: 'Đây chính là lỗi của thiết kế cũ: 2 báo thức là vượt hạn mức 64 của iOS');
    });

    test('mỗi báo thức nhận cùng một phần ngân sách', () async {
      await insertAlarm(hour: 7, minute: 0);
      await insertAlarm(hour: 22, minute: 0);

      await repo.rearmEnabledAlarms();

      final calls = scheduleCalls();
      expect(calls[0]['chainLength'], calls[1]['chainLength']);
      expect(calls[0]['futureCount'], calls[1]['futureCount']);
    });

    test('báo thức MỘT LẦN không hẹn trước lần kêu tương lai', () async {
      await insertAlarm(hour: 7, minute: 0, repeatDays: 0);

      await repo.rearmEnabledAlarms();

      expect(scheduleCalls().single['futureCount'], 0);
    });
  });

  group('deleteAlarm', () {
    test('xóa luôn lịch sử liên quan (không vi phạm khoá ngoại)', () async {
      final id = await insertAlarm(hour: 7, minute: 0);
      await repo.rescheduleAfterFire(id, firedAt: dt(2026, 10, 18, 7, 0));
      expect(await repo.getHistory(id), hasLength(1));

      await repo.deleteAlarm(id);

      expect(await repo.getHistory(id), isEmpty);
      expect(calls.where((c) => c.method == 'cancelAlarm'), hasLength(1));
    });
  });

  group('wipeAllData (Full Wipe)', () {
    test('hủy toàn bộ native alarm và xóa sạch dữ liệu trong DB', () async {
      final id1 = await insertAlarm(hour: 7, minute: 0);
      await insertAlarm(hour: 8, minute: 0);
      await repo.rescheduleAfterFire(id1, firedAt: dt(2026, 10, 18, 7, 0));

      expect(await db.getAllAlarms(), hasLength(2));
      expect(await repo.getHistory(id1), hasLength(1));

      await repo.wipeAllData();

      expect(await db.getAllAlarms(), isEmpty);
      expect(await repo.getHistory(id1), isEmpty);
      expect(calls.where((c) => c.method == 'cancelAlarm'), hasLength(2));
    });
  });

  // ---------------------------------------------------------------------
  // Cập nhật báo thức (updateAlarm)
  // ---------------------------------------------------------------------

  group('updateAlarm — Cập nhật báo thức', () {
    test('cập nhật giờ, phút, repeatDays và nhãn thành công trong DB và reschedule native', () async {
      final id = await insertAlarm(hour: 7, minute: 0, repeatDays: 127, label: 'Báo thức sáng');
      calls.clear();

      final existing = await db.getAlarm(id);
      final updated = existing.copyWith(
        hour: 8,
        minute: 30,
        repeatDays: 31, // T2 - T6
        label: const Value('Đi làm'),
      );

      await repo.updateAlarm(updated);

      // 1. Kiểm tra SQLite DB đã lưu giá trị mới
      final inDb = await db.getAlarm(id);
      expect(inDb.hour, 8);
      expect(inDb.minute, 30);
      expect(inDb.repeatDays, 31);
      expect(inDb.label, 'Đi làm');

      // 2. Kiểm tra Native calls: phải hủy lịch cũ và lập lịch mới
      expect(calls.any((c) => c.method == 'cancelAlarm' && (c.arguments as Map)['id'] == id), isTrue);
      final sched = scheduleCalls().last;
      expect(sched['id'], id);
      expect(sched['hour'], 8);
      expect(sched['minute'], 30);
      expect(sched['repeatDays'], 31);
      expect(sched['label'], 'Đi làm');
    });

    test('cập nhật báo thức chuyển sang tắt (enabled = false) thì hủy lịch và không lập lịch mới', () async {
      final id = await insertAlarm(hour: 7, minute: 0, enabled: true);
      calls.clear();

      final existing = await db.getAlarm(id);
      final updated = existing.copyWith(enabled: false);

      await repo.updateAlarm(updated);

      // 1. Kiểm tra DB lưu enabled = false
      final inDb = await db.getAlarm(id);
      expect(inDb.enabled, isFalse);

      // 2. Kiểm tra OS: hủy lịch cũ và KHÔNG lập lịch mới
      expect(calls.where((c) => c.method == 'cancelAlarm'), hasLength(1));
      expect(calls.where((c) => c.method == 'scheduleAlarm'), isEmpty);
    });

    test('cập nhật cấu hình nhiệm vụ thức dậy (missionEnabled, missionDifficulty)', () async {
      final id = await insertAlarm(hour: 6, minute: 0, missionEnabled: false);
      calls.clear();

      final existing = await db.getAlarm(id);
      final updated = existing.copyWith(
        missionEnabled: true,
        missionType: 'math',
        missionDifficulty: 'hard',
      );

      await repo.updateAlarm(updated);

      final inDb = await db.getAlarm(id);
      expect(inDb.missionEnabled, isTrue);
      expect(inDb.missionType, 'math');
      expect(inDb.missionDifficulty, 'hard');
    });

    test('toggleAlarm bật/tắt cập nhật đúng trạng thái và lập lại/hủy lịch', () async {
      final id = await insertAlarm(hour: 7, minute: 0, enabled: true);
      calls.clear();

      final alarm = await db.getAlarm(id);
      await repo.toggleAlarm(alarm, false);

      expect((await db.getAlarm(id)).enabled, isFalse);
      expect(calls.where((c) => c.method == 'cancelAlarm'), hasLength(1));
      expect(scheduleCalls(), isEmpty);

      calls.clear();
      final disabledAlarm = await db.getAlarm(id);
      await repo.toggleAlarm(disabledAlarm, true);

      expect((await db.getAlarm(id)).enabled, isTrue);
      expect(scheduleCalls(), hasLength(1));
    });

    test('giá trị mặc định của nhiệm vụ thức dậy khi không chỉ định (false, math, medium)', () async {
      final id = await db.insertAlarm(
        const AlarmsCompanion(
          hour: Value(6),
          minute: Value(30),
        ),
      );

      final alarm = await db.getAlarm(id);
      expect(alarm.missionEnabled, isFalse);
      expect(alarm.missionType, 'math');
      expect(alarm.missionDifficulty, 'medium');
    });
  });
}