import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeup_app/data/local/database.dart';
import 'package:wakeup_app/features/alarms/providers/alarm_list_provider.dart';
import 'package:wakeup_app/features/home/presentation/main_navigation_screen.dart';
import 'package:wakeup_app/features/timer/presentation/timer_stopwatch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> channelCalls = [];

  setUp(() {
    channelCalls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.wakeup.app/alarm'),
            (MethodCall call) async {
      channelCalls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.wakeup.app/alarm'), null);
  });

  Widget createSubject({Widget? child}) {
    return ProviderScope(
      overrides: [
        alarmListStreamProvider.overrideWith((ref) => Stream.value(<Alarm>[])),
      ],
      child: MaterialApp(
        home: child ?? const TimerStopwatchScreen(),
      ),
    );
  }

  group('CHALLENGER STRESS: Duration Picker & Zero Duration Validation', () {
    testWidgets('CupertinoTimerPicker configured in HMS mode with dark theme', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(minutes: 5)),
        ),
      ));
      await tester.pumpAndSettle();

      final pickerFinder = find.byType(CupertinoTimerPicker);
      expect(pickerFinder, findsOneWidget);

      final CupertinoTimerPicker picker = tester.widget(pickerFinder);
      expect(picker.mode, CupertinoTimerPickerMode.hms);
      expect(picker.initialTimerDuration, const Duration(minutes: 5));
    });

    testWidgets('Starting with 0 duration triggers SnackBar and stays in setup mode', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration.zero),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      expect(state.mode, TimerMode.setup);
      expect(state.selectedDuration, Duration.zero);

      // Tap Bắt đầu with 0 duration
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      // Mode must NOT change to running
      expect(state.mode, TimerMode.setup);

      // Warning SnackBar must be displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Vui lòng chọn thời lượng lớn hơn 0 giây.'), findsOneWidget);

      // Advance time to let SnackBar fade out
      await tester.pumpAndSettle();
    });

    testWidgets('Picker accepts large durations (e.g. 23h 59m 59s) without crash', (tester) async {
      const maxDuration = Duration(hours: 23, minutes: 59, seconds: 59);
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: maxDuration),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      expect(state.selectedDuration, maxDuration);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      expect(state.mode, TimerMode.running);
      expect(state.secondsRemaining, 86399);
      expect(find.text('23:59:59'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });
  });

  group('CHALLENGER STRESS: Preset Chips Sequence & Boundaries', () {
    testWidgets('Multiple preset chips tap accumulate duration correctly', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration.zero),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      expect(state.selectedDuration, Duration.zero);

      // Tap +1m -> 1 min
      await tester.tap(find.text('+1m'));
      await tester.pumpAndSettle();
      expect(state.selectedDuration, const Duration(minutes: 1));

      // Tap +5m -> 6 min
      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();
      expect(state.selectedDuration, const Duration(minutes: 6));

      // Tap +10m -> 16 min
      await tester.tap(find.text('+10m'));
      await tester.pumpAndSettle();
      expect(state.selectedDuration, const Duration(minutes: 16));

      // Tap +15m -> 31 min
      await tester.tap(find.text('+15m'));
      await tester.pumpAndSettle();
      expect(state.selectedDuration, const Duration(minutes: 31));

      // Tap +30m -> 61 min (1 hour 1 min)
      await tester.tap(find.text('+30m'));
      await tester.pumpAndSettle();
      expect(state.selectedDuration, const Duration(minutes: 61));
    });

    testWidgets('Preset chips clamp at 23h 59m 59s and never overflow beyond', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(hours: 23, minutes: 45)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));

      // Add +30m (would be 24h 15m without clamp)
      await tester.tap(find.text('+30m'));
      await tester.pumpAndSettle();

      // Clamped to 23:59:59 (86399 seconds)
      expect(state.selectedDuration, const Duration(hours: 23, minutes: 59, seconds: 59));
      expect(state.selectedDuration.inSeconds, 86399);
    });
  });

  group('CHALLENGER STRESS: State Machine Transitions & Re-run Cycles', () {
    testWidgets('Start -> Partial Run -> Reset -> Start runs full initial duration again', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 15)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));

      // 1. First run: tick 5 seconds
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(state.secondsRemaining, 10);
      expect(state.mode, TimerMode.running);

      // 2. Reset back to setup
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
      expect(state.mode, TimerMode.setup);

      // 3. Start second run: must start with 15 seconds, NOT 10 seconds!
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      expect(state.secondsRemaining, 15);
      expect(state.mode, TimerMode.running);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('Paused state -> Reset -> Setup cleans up cleanly', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 20)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(state.secondsRemaining, 16);

      // Pause
      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();
      expect(state.mode, TimerMode.paused);

      // Reset from paused state
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
      expect(state.mode, TimerMode.setup);
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
    });

    testWidgets('Rapid Pause / Resume toggles maintain single ticker integrity', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 30)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      // Rapidly toggle Pause / Resume
      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();
      expect(state.mode, TimerMode.paused);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      expect(state.mode, TimerMode.running);

      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();
      expect(state.mode, TimerMode.paused);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      expect(state.mode, TimerMode.running);

      // Now verify steady countdown: exactly 1 second per tick
      final remainingBefore = state.secondsRemaining;
      await tester.pump(const Duration(seconds: 2));
      expect(state.secondsRemaining, remainingBefore - 2);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });
  });

  group('CHALLENGER STRESS: Circular Progress & Time Formatter', () {
    testWidgets('Circular progress matches secondsRemaining / initialTotalSeconds', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 100)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      Finder progressFinder = find.byType(CircularProgressIndicator);
      CircularProgressIndicator progressIndicator = tester.widget(progressFinder);
      // 100/100 = 1.0
      expect(progressIndicator.value, 1.0);

      // Tick 25 seconds -> 75 remaining -> 0.75
      await tester.pump(const Duration(seconds: 25));
      progressIndicator = tester.widget(progressFinder);
      expect(progressIndicator.value, 0.75);

      // Tick 50 more seconds -> 25 remaining -> 0.25
      await tester.pump(const Duration(seconds: 50));
      progressIndicator = tester.widget(progressFinder);
      expect(progressIndicator.value, 0.25);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('Time format preserves HH:mm:ss when initialDuration >= 1 hour even when remaining < 1h', (tester) async {
      // 1 hour and 2 seconds
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(hours: 1, seconds: 2)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      expect(find.text('01:00:02'), findsOneWidget);

      // Tick 3 seconds -> remaining 00:59:59 (sub-hour, but format stays 3-part HH:mm:ss)
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:59:59'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('Time format uses mm:ss when initialDuration < 1 hour', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(minutes: 5, seconds: 3)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      expect(find.text('05:03'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('04:59'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });
  });

  group('CHALLENGER STRESS: Countdown Reaching 0 & Ringing Alert Dialog', () {
    testWidgets('Countdown reaching 0 fires native alarm, shows modal dialog and blocks pop', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 2)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      // Tick down to 0
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // State is ringing
      expect(state.mode, TimerMode.ringing);

      // Channel call verification
      final ringingCalls = channelCalls.where((c) => c.method == 'startRinging').toList();
      expect(ringingCalls.length, 1);
      expect(ringingCalls.first.arguments['soundId'], 'alarm_default');
      expect(ringingCalls.first.arguments['volume'], 1.0);
      expect(ringingCalls.first.arguments['autoStopMinutes'], 10);

      // Verify AlertDialog properties
      expect(find.byType(AlertDialog), findsOneWidget);
      final popScopeFinder = find.ancestor(
        of: find.byType(AlertDialog),
        matching: find.byType(PopScope),
      );
      expect(popScopeFinder, findsOneWidget);
      final PopScope popScope = tester.widget(popScopeFinder);
      expect(popScope.canPop, isFalse); // Non-dismissible via back button

      // Title & Content
      expect(find.text('Hết giờ!'), findsWidgets);
      expect(find.text('Bộ đếm 00:02 đã kết thúc.'), findsOneWidget);

      // "Dừng" button inside dialog
      final stopBtnFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Dừng'),
      );
      expect(stopBtnFinder, findsOneWidget);

      // Tap "Dừng"
      await tester.tap(stopBtnFinder);
      await tester.pumpAndSettle();

      // Dialog must be dismissed
      expect(find.byType(AlertDialog), findsNothing);

      // Native stopRinging must have been called
      expect(channelCalls.any((c) => c.method == 'stopRinging'), isTrue);

      // Mode is back to setup
      expect(state.mode, TimerMode.setup);
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Disposing while running cancels active ticker without ringing or crash', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 20)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Replace with another widget (unmount TimerView)
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: Text('Unmounted View'),
        ),
      ));
      await tester.pumpAndSettle();

      // Advance time by 30 seconds: ticker must NOT fire or throw setState() on unmounted state
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      // No startRinging should have been called
      expect(channelCalls.any((c) => c.method == 'startRinging'), isFalse);
    });
  });

  group('CHALLENGER STRESS: MainNavigationScreen Option A Incomplete Features Check', () {
    testWidgets('Navigation bar strictly contains only Alarm and Timer tabs', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const MainNavigationScreen(),
      ));
      await tester.pumpAndSettle();

      final BottomNavigationBar navBar = tester.widget(find.byType(BottomNavigationBar));
      expect(navBar.items.length, 2);
      expect(navBar.items.map((i) => i.label).toList(), ['Báo thức', 'Hẹn giờ']);

      // Apple Guideline 2.1 checks: absolutely no unfinished mock tabs
      expect(find.text('Thế giới'), findsNothing);
      expect(find.text('World Clock'), findsNothing);
      expect(find.text('Giấc ngủ'), findsNothing);
      expect(find.text('Sleep Sounds'), findsNothing);
    });
  });

  group('CHALLENGER STRESS: TabBarView Integration', () {
    testWidgets('Switching between BẤM GIỜ and HẸN GIỜ tabs preserves stability', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const TimerStopwatchScreen(),
      ));
      await tester.pumpAndSettle();

      // Initially on BẤM GIỜ (Stopwatch)
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('00:00.00'), findsOneWidget);

      // Switch to HẸN GIỜ (Timer)
      await tester.tap(find.text('HẸN GIỜ'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTimerPicker), findsOneWidget);

      // Add 5 minutes and start
      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      expect(find.text('Đang đếm ngược'), findsOneWidget);

      // Switch back to BẤM GIỜ while timer is running
      await tester.tap(find.text('BẤM GIỜ'));
      await tester.pumpAndSettle();

      expect(find.text('00:00.00'), findsOneWidget);

      // Switch back to HẸN GIỜ
      await tester.tap(find.text('HẸN GIỜ'));
      await tester.pumpAndSettle();

      // Timer should either be running or ready
      expect(find.byType(TimerView), findsOneWidget);
    });
  });
}
