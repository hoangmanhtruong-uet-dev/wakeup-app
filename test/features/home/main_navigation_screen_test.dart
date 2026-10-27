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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.wakeup.app/alarm'),
            (MethodCall call) async {
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

  group('MainNavigationScreen Option A Simplification', () {
    testWidgets('displays exactly 2 navigation tabs: Báo thức and Hẹn giờ', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      final BottomNavigationBar navBar = tester.widget(navBarFinder);
      expect(navBar.items.length, 2);

      expect(navBar.items[0].label, 'Báo thức');
      expect((navBar.items[0].icon as Icon).icon, Icons.alarm);

      expect(navBar.items[1].label, 'Hẹn giờ');
      expect((navBar.items[1].icon as Icon).icon, Icons.hourglass_bottom);
    });

    testWidgets('does not show World Clock or Sleep Soundscape tabs in MVP v1.0', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Thế giới'), findsNothing);
      expect(find.text('Giấc ngủ'), findsNothing);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.bedtime), findsNothing);
    });

    testWidgets('initially displays AlarmDashboardScreen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AlarmDashboardScreen), findsOneWidget);
      expect(find.byType(TimerStopwatchScreen), findsNothing);
    });

    testWidgets('tapping Hẹn giờ tab switches to TimerStopwatchScreen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap on 'Hẹn giờ' tab
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();

      expect(find.byType(TimerStopwatchScreen), findsOneWidget);
      expect(find.byType(AlarmDashboardScreen), findsNothing);
      expect(find.text('BẤM GIỜ'), findsOneWidget);
      expect(find.text('HẸN GIỜ'), findsOneWidget);
    });

    testWidgets('tapping Báo thức tab switches back to AlarmDashboardScreen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // First navigate to Hẹn giờ
      await tester.tap(find.text('Hẹn giờ'));
      await tester.pumpAndSettle();
      expect(find.byType(TimerStopwatchScreen), findsOneWidget);

      // Now navigate back to Báo thức
      await tester.tap(find.text('Báo thức'));
      await tester.pumpAndSettle();

      expect(find.byType(AlarmDashboardScreen), findsOneWidget);
      expect(find.byType(TimerStopwatchScreen), findsNothing);
    });
  });
}
