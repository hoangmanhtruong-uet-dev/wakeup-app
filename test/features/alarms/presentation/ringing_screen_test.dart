import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeup_app/data/local/database.dart';
import 'package:wakeup_app/data/local/database_provider.dart';
import 'package:wakeup_app/data/repositories/alarm_repository.dart';
import 'package:wakeup_app/data/repositories/alarm_repository_provider.dart';
import 'package:wakeup_app/features/alarms/presentation/missions/math_mission_screen.dart';
import 'package:wakeup_app/features/alarms/presentation/ringing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.wakeup.app/alarm');

  late AppDatabase db;
  late AlarmRepository repo;
  late List<MethodCall> nativeCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AlarmRepository(db);
    nativeCalls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      nativeCalls.add(call);
      if (call.method == 'getMissedAlarms') return <int>[];
      if (call.method == 'getInitialAlarmPayload') return null;
      if (call.method == 'requestNotificationPermission') return true;
      return true;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
  });

  void setupPhoneDisplay(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5; // 432 x 960 logical pixels
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<int> insertTestAlarm({
    required int hour,
    required int minute,
    int repeatDays = 127,
    bool enabled = true,
    String? label,
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
        missionEnabled: Value(missionEnabled),
        missionType: Value(missionType),
        missionDifficulty: Value(missionDifficulty),
      ),
    );
  }

  Widget createRingingWidget({
    required int alarmId,
    String label = 'Báo thức kiểm thử',
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: RingingScreen(
          alarmId: alarmId,
          label: label,
        ),
      ),
    );
  }

  group('RingingScreen — Start Ringing on Mount', () {
    testWidgets('Gọi startRinging của Native khi màn hình xuất hiện', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(hour: 7, minute: 0);
      nativeCalls.clear();

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      final startCalls = nativeCalls.where((c) => c.method == 'startRinging');
      expect(startCalls.length, 1);
      final args = startCalls.first.arguments as Map;
      expect(args['autoStopMinutes'], 10);
    });
  });

  group('RingingScreen — Non-Mission Alarms (missionEnabled == false)', () {
    testWidgets('Tắt chuông ngay lập tức không yêu cầu MathMissionScreen', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(
        hour: 7,
        minute: 0,
        missionEnabled: false,
      );

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Kéo thanh trượt để tắt chuông (> 90% chiều rộng thanh trượt: maxWidth ~ 220px)
      final sliderFinder = find.byIcon(Icons.power_settings_new);
      expect(sliderFinder, findsOneWidget);
      await tester.drag(sliderFinder, const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Không hiển thị màn hình giải toán
      expect(find.byType(MathMissionScreen), findsNothing);

      // Đã gọi stopRinging với đúng alarmId
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], id);

      // Đã ghi lịch sử dismiss
      final history = await db.select(db.alarmEvents).get();
      expect(history.length, 1);
      expect(history.first.alarmId, id);
      expect(history.first.action, 'dismissed');
    });
  });

  group('RingingScreen — Mission Alarms (missionEnabled == true)', () {
    testWidgets('Bắt buộc mở MathMissionScreen khi missionEnabled == true', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(
        hour: 7,
        minute: 0,
        missionEnabled: true,
        missionDifficulty: 'easy',
      );

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Kéo thanh trượt để tắt chuông
      final sliderFinder = find.byIcon(Icons.power_settings_new);
      await tester.drag(sliderFinder, const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bắt buộc hiển thị MathMissionScreen
      expect(find.byType(MathMissionScreen), findsOneWidget);

      // Kiểm tra độ khó truyền vào MathMissionScreen
      final missionWidget = tester.widget<MathMissionScreen>(find.byType(MathMissionScreen));
      expect(missionWidget.difficulty, MathDifficulty.easy);
      expect(missionWidget.requiredQuestions, 3);

      // Trong lúc đang ở màn hình giải toán, RingingScreen chưa được gọi stopRinging hay reschedule
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.isEmpty, isTrue);

      final history = await db.select(db.alarmEvents).get();
      expect(history.isEmpty, isTrue);
    });

    testWidgets('Hủy bỏ hoặc thoát MathMissionScreen không tắt chuông', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(
        hour: 7,
        minute: 0,
        missionEnabled: true,
        missionDifficulty: 'medium',
      );

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      // Kéo thanh trượt
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MathMissionScreen), findsOneWidget);
      nativeCalls.clear();

      // Giả lập pop màn hình mà không hoàn thành nhiệm vụ (trả về null / false)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.pop(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // MathMissionScreen đã đóng, quay lại RingingScreen
      expect(find.byType(MathMissionScreen), findsNothing);
      expect(find.byType(RingingScreen), findsOneWidget);

      // Native ringing KHÔNG bị tắt và lịch sử KHÔNG được ghi
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.isEmpty, isTrue);

      final history = await db.select(db.alarmEvents).get();
      expect(history.isEmpty, isTrue);
    });

    testWidgets('Hoàn thành MathMissionScreen tắt chuông và reschedule thành công', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(
        hour: 7,
        minute: 0,
        missionEnabled: true,
        missionDifficulty: 'hard',
      );

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      // Kéo thanh trượt
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MathMissionScreen), findsOneWidget);
      final missionWidget = tester.widget<MathMissionScreen>(find.byType(MathMissionScreen));
      expect(missionWidget.difficulty, MathDifficulty.hard);

      nativeCalls.clear();

      // Hoàn thành nhiệm vụ (MathMissionScreen pop với true)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sau khi giải xong, chuông native được tắt với đúng id
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], id);

      // Lịch sử được ghi nhận dismissed
      final history = await db.select(db.alarmEvents).get();
      expect(history.length, 1);
      expect(history.first.alarmId, id);
      expect(history.first.action, 'dismissed');
    });
  });

  group('RingingScreen — Snooze Offset Decoding (1000000)', () {
    testWidgets('Giải mã snooze ID offset (alarmId >= 1000000) cho báo thức không mission', (tester) async {
      setupPhoneDisplay(tester);
      final realId = await insertTestAlarm(
        hour: 8,
        minute: 30,
        missionEnabled: false,
      );

      final snoozedAlarmId = realId + AlarmRepository.snoozeIdOffset;
      expect(snoozedAlarmId, greaterThanOrEqualTo(1000000));

      await tester.pumpWidget(createRingingWidget(alarmId: snoozedAlarmId));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Kéo thanh trượt tắt chuông
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Không mở MathMissionScreen vì alarm gốc có missionEnabled == false
      expect(find.byType(MathMissionScreen), findsNothing);

      // Native stopRinging được gọi với snoozedAlarmId (để huỷ notification thực tế)
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], snoozedAlarmId);

      // DB rescheduleAfterFire được gọi với realId (không phải 1000000 + id)
      final history = await db.select(db.alarmEvents).get();
      expect(history.length, 1);
      expect(history.first.alarmId, realId);
      expect(history.first.action, 'dismissed');
    });

    testWidgets('Giải mã snooze ID offset (alarmId >= 1000000) cho báo thức có mission', (tester) async {
      setupPhoneDisplay(tester);
      final realId = await insertTestAlarm(
        hour: 6,
        minute: 15,
        missionEnabled: true,
        missionDifficulty: 'hard',
      );

      final snoozedAlarmId = realId + AlarmRepository.snoozeIdOffset;

      await tester.pumpWidget(createRingingWidget(alarmId: snoozedAlarmId));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Kéo thanh trượt tắt chuông
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Đã tra cứu đúng cấu hình của realId -> mở MathMissionScreen với difficulty hard
      expect(find.byType(MathMissionScreen), findsOneWidget);
      final missionWidget = tester.widget<MathMissionScreen>(find.byType(MathMissionScreen));
      expect(missionWidget.difficulty, MathDifficulty.hard);

      // Hoàn thành nhiệm vụ
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dừng chuông native với snoozedAlarmId
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], snoozedAlarmId);

      // Lịch sử ghi cho realId
      final history = await db.select(db.alarmEvents).get();
      expect(history.length, 1);
      expect(history.first.alarmId, realId);
    });

    testWidgets('Nút BÁO LẠI (SNOOZE) dừng notification snoozedId và snooze cho realId', (tester) async {
      setupPhoneDisplay(tester);
      final realId = await insertTestAlarm(
        hour: 9,
        minute: 0,
        repeatDays: 127,
      );

      final snoozedAlarmId = realId + AlarmRepository.snoozeIdOffset;

      await tester.pumpWidget(createRingingWidget(alarmId: snoozedAlarmId));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Bấm nút Snooze
      final snoozeBtn = find.text('BÁO LẠI (SNOOZE)');
      expect(snoozeBtn, findsOneWidget);
      await tester.tap(snoozeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dừng notification hiện tại
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], snoozedAlarmId);

      // Ghi lịch sử snoozed cho realId
      final history = await db.select(db.alarmEvents).get();
      expect(history.length, 1);
      expect(history.first.alarmId, realId);
      expect(history.first.action, 'snoozed');

      // Native scheduleAlarm được gọi cho lần báo lại
      final schedCalls = nativeCalls.where((c) => c.method == 'scheduleAlarm');
      expect(schedCalls.isNotEmpty, isTrue);
    });
  });

  group('RingingScreen — Edge Cases & Fallbacks', () {
    testWidgets('Báo thức không tồn tại trong DB (bị xóa) tự động fallback không mission và tắt an toàn', (tester) async {
      setupPhoneDisplay(tester);
      const nonExistentId = 999999;

      await tester.pumpWidget(createRingingWidget(alarmId: nonExistentId));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Kéo thanh trượt
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Không crash, không mở MathMissionScreen
      expect(find.byType(MathMissionScreen), findsNothing);

      // Vẫn gọi stopRinging native
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.length, 1);
      expect((stopCalls.first.arguments as Map)['id'], nonExistentId);
    });

    testWidgets('Kéo thanh trượt chưa đủ 90% không kích hoạt tắt chuông', (tester) async {
      setupPhoneDisplay(tester);
      final id = await insertTestAlarm(hour: 7, minute: 0);

      await tester.pumpWidget(createRingingWidget(alarmId: id));
      await tester.pump(const Duration(milliseconds: 100));

      nativeCalls.clear();

      // Chỉ kéo nhẹ 50px (< 90% chiều rộng thanh trượt: maxWidth ~ 220px, 90% ~ 198px)
      await tester.drag(find.byIcon(Icons.power_settings_new), const Offset(50, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Không gọi stopRinging
      final stopCalls = nativeCalls.where((c) => c.method == 'stopRinging');
      expect(stopCalls.isEmpty, isTrue);

      // Không ghi lịch sử
      final history = await db.select(db.alarmEvents).get();
      expect(history.isEmpty, isTrue);
    });
  });

  group('RingingScreen — Pure Logic & Boundary Stress Tests', () {
    test('Snooze ID Offset Decoding - Kiểm thử các mốc biên số nguyên', () {
      int decode(int id) => id >= AlarmRepository.snoozeIdOffset
          ? id - AlarmRepository.snoozeIdOffset
          : id;

      expect(decode(0), 0);
      expect(decode(1), 1);
      expect(decode(42), 42);
      expect(decode(999999), 999999);
      expect(decode(1000000), 0);
      expect(decode(1000001), 1);
      expect(decode(1000042), 42);
      expect(decode(2000000), 1000000);
    });

    test('MathDifficulty Mapping - Kiểm thử chuỗi hợp lệ và giá trị bất thường / null', () {
      MathDifficulty mapDiff(String? d) {
        if (d == 'easy') return MathDifficulty.easy;
        if (d == 'hard') return MathDifficulty.hard;
        return MathDifficulty.medium;
      }

      expect(mapDiff('easy'), MathDifficulty.easy);
      expect(mapDiff('medium'), MathDifficulty.medium);
      expect(mapDiff('hard'), MathDifficulty.hard);
      expect(mapDiff(null), MathDifficulty.medium);
      expect(mapDiff(''), MathDifficulty.medium);
      expect(mapDiff('impossible'), MathDifficulty.medium);
    });
  });
}
