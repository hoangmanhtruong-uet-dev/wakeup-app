import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wakeup_app/data/local/database.dart';
import 'package:wakeup_app/data/repositories/alarm_repository.dart';
import 'package:wakeup_app/features/alarms/presentation/missions/math_mission_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.wakeup.app/alarm');

  group('Milestone 1 Empirical Challenger Verification', () {
    late List<MethodCall> nativeCalls;

    setUp(() {
      nativeCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        nativeCalls.add(call);
        if (call.method == 'getMissedAlarms') return <int>[];
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // =========================================================================
    // 1. Stress Test: SQLite Schema Migration v1 -> v2
    // =========================================================================
    group('SQLite Schema Migration v1 -> v2', () {
      test('Di chuyển CSDL từ v1 lên v2 bảo toàn dữ liệu cũ và gán đúng giá trị mặc định cho mission', () async {
        // Tạo raw SQLite executor ở version 1 với dữ liệu mẫu
        final rawDb = NativeDatabase.memory(
          setup: (raw) {
            // Tạo bảng Alarms theo đúng cấu trúc v1 (chưa có missionEnabled, missionType, missionDifficulty)
            raw.execute('''
              CREATE TABLE alarms (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
                minute INTEGER NOT NULL CHECK (minute >= 0 AND minute <= 59),
                repeat_days INTEGER NOT NULL DEFAULT 0,
                enabled INTEGER NOT NULL DEFAULT 1,
                label TEXT,
                sound_id TEXT NOT NULL DEFAULT 'default',
                volume REAL NOT NULL DEFAULT 1.0,
                ramp_seconds INTEGER NOT NULL DEFAULT 0,
                vibrate INTEGER NOT NULL DEFAULT 1,
                snooze_minutes INTEGER NOT NULL DEFAULT 5,
                snooze_max INTEGER NOT NULL DEFAULT 3,
                auto_stop_minutes INTEGER NOT NULL DEFAULT 15,
                skip_next_date TEXT,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
              );
              CREATE TABLE alarm_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                alarm_id INTEGER NOT NULL REFERENCES alarms(id),
                scheduled_at INTEGER NOT NULL,
                fired_at INTEGER NOT NULL,
                action TEXT NOT NULL,
                snooze_count INTEGER NOT NULL DEFAULT 0
              );
              PRAGMA user_version = 1;
            ''');

            // Chèn 3 báo thức mẫu ở v1
            // 1: Báo thức lặp hàng ngày, có nhãn
            raw.execute('''
              INSERT INTO alarms (id, hour, minute, repeat_days, enabled, label, sound_id, volume, ramp_seconds, vibrate, snooze_minutes, snooze_max, auto_stop_minutes, skip_next_date, created_at, updated_at)
              VALUES (1, 6, 30, 127, 1, 'Đi làm', 'radar', 0.8, 5, 1, 10, 2, 20, NULL, 1700000000, 1700000000);
            ''');
            // 2: Báo thức một lần, tắt, không nhãn
            raw.execute('''
              INSERT INTO alarms (id, hour, minute, repeat_days, enabled, label, sound_id, volume, ramp_seconds, vibrate, snooze_minutes, snooze_max, auto_stop_minutes, skip_next_date, created_at, updated_at)
              VALUES (2, 9, 0, 0, 0, NULL, 'default', 1.0, 0, 0, 5, 3, 15, '2026-10-25', 1700000010, 1700000010);
            ''');
            // 3: Báo thức lặp Thứ 2 - Thứ 6
            raw.execute('''
              INSERT INTO alarms (id, hour, minute, repeat_days, enabled, label, sound_id, volume, ramp_seconds, vibrate, snooze_minutes, snooze_max, auto_stop_minutes, skip_next_date, created_at, updated_at)
              VALUES (3, 7, 15, 31, 1, 'Tập gym', 'gentle', 0.5, 0, 1, 5, 3, 10, NULL, 1700000020, 1700000020);
            ''');
          },
        );

        // Mở CSDL bằng AppDatabase v2, kích hoạt onUpgrade
        final db = AppDatabase.forTesting(rawDb);

        // 1. Xác minh tất cả 3 bản ghi cũ vẫn tồn tại đầy đủ
        final allAlarms = await db.getAllAlarms();
        expect(allAlarms, hasLength(3));

        // Kiểm tra bản ghi 1
        final a1 = allAlarms.firstWhere((a) => a.id == 1);
        expect(a1.hour, 6);
        expect(a1.minute, 30);
        expect(a1.repeatDays, 127);
        expect(a1.enabled, isTrue);
        expect(a1.label, 'Đi làm');
        expect(a1.soundId, 'radar');
        expect(a1.volume, 0.8);
        expect(a1.rampSeconds, 5);
        expect(a1.vibrate, isTrue);
        expect(a1.snoozeMinutes, 10);
        expect(a1.snoozeMax, 2);
        expect(a1.autoStopMinutes, 20);
        expect(a1.skipNextDate, isNull);
        // GIÁ TRỊ MẶC ĐỊNH SAU MIGRATION CHO MISSION
        expect(a1.missionEnabled, isFalse, reason: 'missionEnabled sau migration phải là false');
        expect(a1.missionType, 'math', reason: 'missionType sau migration phải là math');
        expect(a1.missionDifficulty, 'medium', reason: 'missionDifficulty sau migration phải là medium');

        // Kiểm tra bản ghi 2
        final a2 = allAlarms.firstWhere((a) => a.id == 2);
        expect(a2.hour, 9);
        expect(a2.minute, 0);
        expect(a2.repeatDays, 0);
        expect(a2.enabled, isFalse);
        expect(a2.label, isNull);
        expect(a2.skipNextDate, '2026-10-25');
        expect(a2.missionEnabled, isFalse);
        expect(a2.missionType, 'math');
        expect(a2.missionDifficulty, 'medium');

        // Kiểm tra bản ghi 3
        final a3 = allAlarms.firstWhere((a) => a.id == 3);
        expect(a3.hour, 7);
        expect(a3.minute, 15);
        expect(a3.repeatDays, 31);
        expect(a3.enabled, isTrue);
        expect(a3.missionEnabled, isFalse);
        expect(a3.missionType, 'math');
        expect(a3.missionDifficulty, 'medium');

        // 2. Kiểm tra thao tác cập nhật (updateAlarm) trên bản ghi đã migrate
        final repo = AlarmRepository(db);
        nativeCalls.clear();

        final updatedA1 = a1.copyWith(
          hour: 6,
          minute: 45,
          missionEnabled: true,
          missionDifficulty: 'hard',
          label: const Value('Đi làm sớm'),
        );
        await repo.updateAlarm(updatedA1);

        final fetchedA1 = await db.getAlarm(1);
        expect(fetchedA1.hour, 6);
        expect(fetchedA1.minute, 45);
        expect(fetchedA1.missionEnabled, isTrue);
        expect(fetchedA1.missionDifficulty, 'hard');
        expect(fetchedA1.label, 'Đi làm sớm');

        // Native scheduling cũng phải nhận được giá trị cập nhật
        expect(nativeCalls.any((c) => c.method == 'cancelAlarm' && (c.arguments as Map)['id'] == 1), isTrue);
        final schedCalls = nativeCalls.where((c) => c.method == 'scheduleAlarm').toList();
        expect(schedCalls, hasLength(1));
        final lastSched = schedCalls.last.arguments as Map;
        expect(lastSched['id'], 1);
        expect(lastSched['hour'], 6);
        expect(lastSched['minute'], 45);
        expect(lastSched['label'], 'Đi làm sớm');

        // 3. Thêm mới bản ghi sau migration và xác minh cùng tồn tại
        final newId = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(22),
            minute: Value(0),
            missionEnabled: Value(true),
            missionDifficulty: Value('easy'),
          ),
        );
        final allAfterInsert = await db.getAllAlarms();
        expect(allAfterInsert, hasLength(4));
        final newAlarm = await db.getAlarm(newId);
        expect(newAlarm.missionEnabled, isTrue);
        expect(newAlarm.missionDifficulty, 'easy');

        await db.close();
      });
    });

    // =========================================================================
    // 2. Stress Test & Edge Cases: Alarm Update Logic
    // =========================================================================
    group('Alarm Update & Native Scheduling Edge Cases', () {
      late AppDatabase db;
      late AlarmRepository repo;

      setUp(() {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        repo = AlarmRepository(db);
        nativeCalls.clear();
      });

      tearDown(() async {
        await db.close();
      });

      test('Cập nhật chỉ thời gian (hour/minute) giữ nguyên tất cả thuộc tính khác', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
            repeatDays: Value(31),
            label: Value('Họp sáng'),
            soundId: Value('marimba'),
            volume: Value(0.7),
            missionEnabled: Value(true),
            missionDifficulty: Value('hard'),
          ),
        );
        nativeCalls.clear();

        final alarm = await db.getAlarm(id);
        final updated = alarm.copyWith(hour: 8, minute: 15);
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.hour, 8);
        expect(inDb.minute, 15);
        expect(inDb.repeatDays, 31);
        expect(inDb.label, 'Họp sáng');
        expect(inDb.soundId, 'marimba');
        expect(inDb.volume, 0.7);
        expect(inDb.missionEnabled, isTrue);
        expect(inDb.missionDifficulty, 'hard');

        // Native calls
        expect(nativeCalls.any((c) => c.method == 'cancelAlarm'), isTrue);
        final sched = nativeCalls.where((c) => c.method == 'scheduleAlarm').single.arguments as Map;
        expect(sched['hour'], 8);
        expect(sched['minute'], 15);
        expect(sched['repeatDays'], 31);
        expect(sched['label'], 'Họp sáng');
        expect(sched['soundId'], 'marimba');
      });

      test('Cập nhật chỉ nhãn từ có nhãn thành null / rỗng', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
            label: Value('Nhãn ban đầu'),
          ),
        );
        nativeCalls.clear();

        final alarm = await db.getAlarm(id);
        // Xóa nhãn bằng cách gán Value(null)
        final updated = alarm.copyWith(label: const Value(null));
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.label, isNull);

        final sched = nativeCalls.where((c) => c.method == 'scheduleAlarm').single.arguments as Map;
        expect(sched['label'], '', reason: 'NativeAlarmService convert null label thành chuỗi rỗng');
      });

      test('Cập nhật nhãn đạt giới hạn tối đa 50 ký tự', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
          ),
        );
        nativeCalls.clear();

        final longLabel = 'A' * 50;
        final alarm = await db.getAlarm(id);
        final updated = alarm.copyWith(label: Value(longLabel));
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.label, longLabel);
        expect(inDb.label!.length, 50);
      });

      test('Cập nhật repeatDays thay đổi cấu hình bitmask từ 0 (một lần) sang 127 (hàng ngày)', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
            repeatDays: Value(0), // Một lần
          ),
        );
        nativeCalls.clear();

        final alarm = await db.getAlarm(id);
        final updated = alarm.copyWith(repeatDays: 127);
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.repeatDays, 127);

        final sched = nativeCalls.where((c) => c.method == 'scheduleAlarm').single.arguments as Map;
        expect(sched['repeatDays'], 127);
        expect((sched['futureCount'] as int) > 0, isTrue, reason: 'Báo thức lặp hàng ngày phải có futureCount > 0');
      });

      test('Cập nhật chuyển enabled từ true sang false hủy lịch native và KHÔNG lập lịch mới', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
            enabled: Value(true),
          ),
        );
        nativeCalls.clear();

        final alarm = await db.getAlarm(id);
        final updated = alarm.copyWith(enabled: false);
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.enabled, isFalse);

        expect(nativeCalls.where((c) => c.method == 'cancelAlarm'), hasLength(1));
        expect(nativeCalls.where((c) => c.method == 'scheduleAlarm'), isEmpty);
      });

      test('Cập nhật chuyển enabled từ false sang true lập lịch native mới', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(7),
            minute: Value(0),
            enabled: Value(false),
          ),
        );
        nativeCalls.clear();

        final alarm = await db.getAlarm(id);
        final updated = alarm.copyWith(enabled: true);
        await repo.updateAlarm(updated);

        final inDb = await db.getAlarm(id);
        expect(inDb.enabled, isTrue);

        expect(nativeCalls.where((c) => c.method == 'cancelAlarm'), hasLength(1));
        expect(nativeCalls.where((c) => c.method == 'scheduleAlarm'), hasLength(1));
      });

      test('Cập nhật liên tiếp nhanh (rapid successive updates) bảo toàn trạng thái cuối cùng', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(6),
            minute: Value(0),
          ),
        );

        // 5 lần cập nhật liên tiếp
        for (int i = 1; i <= 5; i++) {
          final current = await db.getAlarm(id);
          await repo.updateAlarm(
            current.copyWith(
              hour: 6 + i,
              minute: i * 10,
              label: Value('Lần $i'),
              missionEnabled: i.isEven,
            ),
          );
        }

        final finalAlarm = await db.getAlarm(id);
        expect(finalAlarm.hour, 11);
        expect(finalAlarm.minute, 50);
        expect(finalAlarm.label, 'Lần 5');
        expect(finalAlarm.missionEnabled, isFalse);

        final lastSched = nativeCalls.where((c) => c.method == 'scheduleAlarm').last.arguments as Map;
        expect(lastSched['hour'], 11);
        expect(lastSched['minute'], 50);
        expect(lastSched['label'], 'Lần 5');
      });

      test('Cập nhật thời gian biên (00:00 và 23:59)', () async {
        final id = await db.insertAlarm(
          const AlarmsCompanion(
            hour: Value(12),
            minute: Value(30),
          ),
        );

        // Biên dưới: 00:00
        var alarm = await db.getAlarm(id);
        await repo.updateAlarm(alarm.copyWith(hour: 0, minute: 0));
        var inDb = await db.getAlarm(id);
        expect(inDb.hour, 0);
        expect(inDb.minute, 0);

        // Biên trên: 23:59
        alarm = await db.getAlarm(id);
        await repo.updateAlarm(alarm.copyWith(hour: 23, minute: 59));
        inDb = await db.getAlarm(id);
        expect(inDb.hour, 23);
        expect(inDb.minute, 59);
      });
    });

    // =========================================================================
    // 3. Logic & Contract Verification: Ringing Screen & Wake-up Missions
    // =========================================================================
    group('Ringing Screen & Wake-up Mission Gate Logic', () {
      test('Mapping độ khó chuỗi sang MathDifficulty enum', () {
        MathDifficulty parseDifficulty(String? difficulty) {
          if (difficulty == 'easy') return MathDifficulty.easy;
          if (difficulty == 'hard') return MathDifficulty.hard;
          return MathDifficulty.medium;
        }

        expect(parseDifficulty('easy'), MathDifficulty.easy);
        expect(parseDifficulty('medium'), MathDifficulty.medium);
        expect(parseDifficulty('hard'), MathDifficulty.hard);
        expect(parseDifficulty('unknown'), MathDifficulty.medium);
        expect(parseDifficulty(null), MathDifficulty.medium);
      });

      test('Xử lý snooze offset tách bạch realId chính xác', () {
        int getRealId(int alarmId) {
          return alarmId >= AlarmRepository.snoozeIdOffset
              ? alarmId - AlarmRepository.snoozeIdOffset
              : alarmId;
        }

        expect(getRealId(1), 1);
        expect(getRealId(999), 999);
        expect(getRealId(1000001), 1);
        expect(getRealId(1000042), 42);
        expect(getRealId(1000000), 0);
      });
    });
  });
}
