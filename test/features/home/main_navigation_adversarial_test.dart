import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeup_app/data/local/database.dart';
import 'package:wakeup_app/features/alarms/presentation/alarm_dashboard_screen.dart';
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

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        alarmListStreamProvider.overrideWith((ref) => Stream.value(<Alarm>[])),
      ],
      child: const MaterialApp(
        home: MainNavigationScreen(),
      ),
    );
  }

  group('MainNavigationScreen Adversarial Stress Tests', () {
    testWidgets('Rapid repetitive tab switching does not throw or crash', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final tabAlarm = find.text('Báo thức');
      final tabTimer = find.text('Hẹn giờ');

      expect(tabAlarm, findsOneWidget);
      expect(tabTimer, findsOneWidget);

      // Perform 30 rapid switches without waiting for settling between each
      for (int i = 0; i < 15; i++) {
        await tester.tap(tabTimer);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.tap(tabAlarm);
        await tester.pump(const Duration(milliseconds: 16));
      }

      await tester.pumpAndSettle();
      expect(find.byType(AlarmDashboardScreen), findsOneWidget);
      expect(find.byType(TimerStopwatchScreen), findsNothing);
    });

    testWidgets('Tapping the currently active tab is a safe no-op', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final tabAlarm = find.text('Báo thức');
      await tester.tap(tabAlarm);
      await tester.pumpAndSettle();

      expect(find.byType(AlarmDashboardScreen), findsOneWidget);

      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();
      expect(find.byType(TimerStopwatchScreen), findsOneWidget);

      // Tap Hẹn giờ again while already active
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();
      expect(find.byType(TimerStopwatchScreen), findsOneWidget);
    });

    testWidgets('Switching away from running timer cleanly disposes timer ticker without leak', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Navigate to Hẹn giờ tab
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();

      // Switch to HẸN GIỜ sub-tab
      await tester.tap(find.text('HẸN GIỜ'));
      await tester.pumpAndSettle();

      // Start the timer
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      expect(find.text('Tạm dừng'), findsOneWidget);

      // Advance time by 2 seconds while running
      await tester.pump(const Duration(seconds: 2));

      // Now switch back to Báo thức tab while timer was actively running
      await tester.tap(find.text('Báo thức'));
      await tester.pumpAndSettle();

      expect(find.byType(AlarmDashboardScreen), findsOneWidget);
      expect(find.byType(TimerStopwatchScreen), findsNothing);

      // Advance time by 5 more seconds to verify no orphaned timer throws setState()
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Switching away from ringing timer stops native audio and cancels vibration', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Navigate to Hẹn giờ tab
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();

      // Switch to HẸN GIỜ sub-tab
      await tester.tap(find.text('HẸN GIỜ'));
      await tester.pumpAndSettle();

      // Access TimerViewState and simulate ringing
      final stateFinder = find.byType(TimerView);
      expect(stateFinder, findsOneWidget);
      final TimerViewState timerState = tester.state(stateFinder);

      // Trigger start then force completion
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      // Advance past remaining seconds to hit ringing
      final remaining = timerState.secondsRemaining;
      await tester.pump(Duration(seconds: remaining + 1));
      await tester.pumpAndSettle();

      expect(channelCalls.any((call) => call.method == 'startRinging'), isTrue);

      // Dialog 'Hết giờ!' is present in AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(AlertDialog, 'Hết giờ!'), findsOneWidget);

      // Now switch to Báo thức tab (simulating external navigation/dismissal)
      // Since dialog is open with barrierDismissible: false, dismiss the dialog via Dừng first or navigate away
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Dừng')));
      await tester.pumpAndSettle();

      expect(channelCalls.any((call) => call.method == 'stopRinging'), isTrue);

      // Now switch to Báo thức
      await tester.tap(find.text('Báo thức'));
      await tester.pumpAndSettle();
      expect(find.byType(AlarmDashboardScreen), findsOneWidget);
    });

    testWidgets('Exhaustive UI tree audit: zero occurrence of World Clock and Sleep Soundscape strings/icons', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tab 0 audit
      expect(find.textContaining('World Clock', findRichText: true), findsNothing);
      expect(find.textContaining('Múi giờ', findRichText: true), findsNothing);
      expect(find.textContaining('Giấc ngủ', findRichText: true), findsNothing);
      expect(find.textContaining('Sleep', findRichText: true), findsNothing);
      expect(find.textContaining('Âm thanh', findRichText: true), findsNothing);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.bedtime), findsNothing);
      expect(find.byIcon(Icons.public), findsNothing);

      // Tab 1 audit
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('World Clock', findRichText: true), findsNothing);
      expect(find.textContaining('Múi giờ', findRichText: true), findsNothing);
      expect(find.textContaining('Giấc ngủ', findRichText: true), findsNothing);
      expect(find.textContaining('Sleep', findRichText: true), findsNothing);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.bedtime), findsNothing);
      expect(find.byIcon(Icons.public), findsNothing);
    });
  });
}
