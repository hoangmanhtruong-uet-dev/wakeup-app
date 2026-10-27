import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakeup_app/features/timer/presentation/timer_stopwatch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> channelCalls = [];

  setUp(() {
    channelCalls.clear();
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
      child: MaterialApp(
        home: child ?? const TimerStopwatchScreen(),
      ),
    );
  }

  group('TimerStopwatchScreen Tabs & Structure', () {
    testWidgets('renders both tabs BẤM GIỜ and HẸN GIỜ', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('BẤM GIỜ'), findsOneWidget);
      expect(find.text('HẸN GIỜ'), findsOneWidget);
    });

    testWidgets('switching tab to HẸN GIỜ renders TimerView in setup mode', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('HẸN GIỜ'));
      await tester.pumpAndSettle();

      // CupertinoTimerPicker is present
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
      // Preset chips are present
      expect(find.text('+1m'), findsOneWidget);
      expect(find.text('+5m'), findsOneWidget);
      expect(find.text('+10m'), findsOneWidget);
      expect(find.text('+15m'), findsOneWidget);
      expect(find.text('+30m'), findsOneWidget);
      // Start button is present
      expect(find.text('Bắt đầu'), findsOneWidget);
    });
  });

  group('TimerView State Machine & Controls', () {
    testWidgets('preset chips increment duration', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(minutes: 5)),
        ),
      ));
      await tester.pumpAndSettle();

      final stateFinder = find.byType(TimerView);
      final TimerViewState state = tester.state(stateFinder);
      expect(state.selectedDuration, const Duration(minutes: 5));

      // Tap +5m chip
      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();

      expect(state.selectedDuration, const Duration(minutes: 10));

      // Tap +1m chip
      await tester.tap(find.text('+1m'));
      await tester.pumpAndSettle();

      expect(state.selectedDuration, const Duration(minutes: 11));
    });

    testWidgets('starting timer transitions from setup to running mode', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 10)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      expect(state.mode, TimerMode.setup);

      // Tap Bắt đầu
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      expect(state.mode, TimerMode.running);
      expect(find.text('Đang đếm ngược'), findsOneWidget);
      expect(find.text('Tạm dừng'), findsOneWidget);
      expect(find.text('Đặt lại'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up timer by resetting
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('countdown decrements seconds in running mode', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 10)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      expect(state.secondsRemaining, 10);

      // Advance by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      expect(state.secondsRemaining, 7);

      // Reset to cancel timer
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('pause and resume toggle state and freeze countdown', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 20)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      // Tick 2 seconds
      await tester.pump(const Duration(seconds: 2));
      expect(state.secondsRemaining, 18);

      // Tap Tạm dừng
      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();

      expect(state.mode, TimerMode.paused);
      expect(find.text('Đã tạm dừng'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Advance time while paused: should not decrement
      await tester.pump(const Duration(seconds: 5));
      expect(state.secondsRemaining, 18);

      // Tap Tiếp tục
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();

      expect(state.mode, TimerMode.running);
      await tester.pump(const Duration(seconds: 3));
      expect(state.secondsRemaining, 15);

      // Reset
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('reset button returns timer to setup mode', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 30)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 5));
      expect(state.mode, TimerMode.running);

      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();

      expect(state.mode, TimerMode.setup);
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('countdown completion triggers ringing mode and native alarm', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 2)),
        ),
      ));
      await tester.pumpAndSettle();

      final TimerViewState state = tester.state(find.byType(TimerView));
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();

      // Countdown 2 seconds to zero
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(state.mode, TimerMode.ringing);

      // Native startRinging must be invoked
      final startRingingCalls = channelCalls.where((c) => c.method == 'startRinging').toList();
      expect(startRingingCalls.length, 1);
      expect(startRingingCalls.first.arguments['soundId'], 'alarm_default');

      // "Hết giờ!" dialog and "Dừng" button are visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hết giờ!'), findsWidgets);
      final stopButtonFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Dừng'),
      );
      expect(stopButtonFinder, findsOneWidget);

      // Tap "Dừng" inside AlertDialog
      await tester.tap(stopButtonFinder);
      await tester.pumpAndSettle();

      // Native stopRinging must be invoked
      final stopRingingCalls = channelCalls.where((c) => c.method == 'stopRinging').toList();
      expect(stopRingingCalls.length, 1);

      // Transitions back to setup mode
      expect(state.mode, TimerMode.setup);
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
    });

    testWidgets('disposing TimerView while ringing calls stopRinging and cleans up', (tester) async {
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: TimerView(initialDuration: Duration(seconds: 1)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(channelCalls.any((c) => c.method == 'startRinging'), isTrue);

      // Dispose widget tree while ringing
      await tester.pumpWidget(createSubject(
        child: const Scaffold(
          body: Text('Replaced'),
        ),
      ));
      await tester.pumpAndSettle();

      // Native stopRinging should be called on dispose
      expect(channelCalls.any((c) => c.method == 'stopRinging'), isTrue);
    });
  });
}
