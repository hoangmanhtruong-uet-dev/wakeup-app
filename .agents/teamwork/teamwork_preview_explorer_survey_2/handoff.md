# HANDOFF — Survey Explorer 2
**Mission**: Survey EPIC 3 (R2 - Option A) - Flexible Timer & Clean Navigation  
**Author**: Survey Explorer 2  
**Date**: 2026-10-18T19:46:00Z  
**Target Milestone**: EPIC 3 Implementation Ready  

---

## 1. Observation

### 1.1 Current Timer Implementation
- **File**: `lib/features/timer/presentation/timer_stopwatch_screen.dart`
- **Component**: `TimerStopwatchScreen` (ConsumerStatefulWidget, lines 7-50) hosts a `TabBar` and `TabBarView` with two tabs:
  1. `_StopwatchView` (lines 53-163): Functional stopwatch with lap recording and 30ms timer ticker.
  2. `_TimerView` (lines 166-264): Hardcoded 15-minute countdown timer.
- **Specific code findings in `_TimerView`**:
  - **Hardcoded 15-minute duration** (line 176):
    ```dart
    int _secondsRemaining = 15 * 60; // 15 phút mặc định
    bool _isRunning = false;
    Timer? _timer;
    ```
  - **No duration picker**: The user cannot choose hours, minutes, or seconds.
  - **Unaddressed TODO & no alarm on completion** (lines 188-193):
    ```dart
    } else {
      _timer?.cancel();
      _isRunning = false;
      // TODO: Báo chuông Native
    }
    ```
    When countdown reaches 0, it simply stops. No audio plays, no vibration is triggered, and no system notification or in-app alert is shown.
  - **Missing `dispose()` method in `_TimerViewState`**:
    `_TimerViewState` does NOT cancel `_timer` in `dispose()`. If the user leaves the screen while the timer is ticking, `setState()` is called after disposal, triggering Flutter framework errors.
  - **Hardcoded progress calculation** (line 225):
    `value: _secondsRemaining / (15 * 60)` assumes a 900-second baseline.
  - **Time formatting ignores hours** (lines 211-213):
    `int m = _secondsRemaining ~/ 60; int s = _secondsRemaining % 60; String timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';`
  - **Lint warnings in `timer_stopwatch_screen.dart`** (detected via `flutter analyze`):
    - Line 1: `import 'dart:ui';` is unnecessary.
    - Lines 121, 127, 252: `.withOpacity()` is deprecated in Flutter 3.27+ (use `.withValues()`).

### 1.2 Main Navigation & Shell Architecture
- **File**: `lib/features/home/presentation/main_navigation_screen.dart`
- **Screens list** (lines 18-23):
  ```dart
  final List<Widget> _screens = const [
    AlarmDashboardScreen(),
    WorldClockScreen(),
    TimerStopwatchScreen(),
    SleepSoundscapeScreen(),
  ];
  ```
- **Navigation Bar items** (lines 48-66):
  4 tabs defined:
  - Tab 0: "Báo thức" (`Icons.alarm`) -> `AlarmDashboardScreen`
  - Tab 1: "Thế giới" (`Icons.language`) -> `WorldClockScreen`
  - Tab 2: "Bấm giờ" (`Icons.hourglass_empty`) -> `TimerStopwatchScreen`
  - Tab 3: "Giấc ngủ" (`Icons.bedtime`) -> `SleepSoundscapeScreen`
- **State of Tab 1 (`WorldClockScreen`)**:
  - File: `lib/features/world_clock/presentation/world_clock_screen.dart`
  - Line 19 contains: `// TODO: Mở danh sách tìm kiếm múi giờ`
  - Body contains 4 static dummy cards (`Hà Nội`, `New York`, `Tokyo`, `London`).
- **State of Tab 3 (`SleepSoundscapeScreen`)**:
  - File: `lib/features/sleep/presentation/sleep_soundscape_screen.dart`
  - Line 12: `// Thực tế ở Giai đoạn 4, mỗi slider này sẽ tương ứng với 1 AudioPlayer của just_audio`
  - Line 24: `// TODO: Gửi lệnh Play/Pause xuống các player của just_audio`
  - Sliders and play button have no audio backing.
- **Navigation references to `MainNavigationScreen`**:
  - `lib/core/app_router.dart:173`: `return const MainNavigationScreen();`
  - `lib/features/onboarding/presentation/system_permission_guide_screen.dart:57`: `Navigator.pushReplacement(..., MaterialPageRoute(builder: (_) => const MainNavigationScreen()))`
  - `lib/features/auth/login_screen.dart:41, 79`: `Navigator.pushReplacement(..., MaterialPageRoute(builder: (_) => const MainNavigationScreen()))`
  - No caller ever passes an initial index or expects 4 tabs.
  - Neither `WorldClockScreen` nor `SleepSoundscapeScreen` is referenced anywhere else in the project.

### 1.3 Audio, Vibration & Notification Infrastructure
- **Sound Assets**:
  - `assets/sounds/` contains 12 WAV files (`alarm_default.wav`, `alarm_beep.wav`, etc.).
  - As documented in `pubspec.yaml` (lines 44-57), `assets/sounds/` is deliberately omitted from Flutter assets to prevent duplicate APK bloat.
  - Audio files are natively bundled:
    - Android: `android/app/src/main/res/raw/` (12 files)
    - iOS: `ios/Runner/Sounds/` (12 files)
- **Native MethodChannel (`com.wakeup.app/alarm`)**:
  - `lib/data/local/native_alarm_service.dart`:
    - `startRinging({String? soundId, double volume = 1.0, int autoStopMinutes = 10})`
    - `stopRinging({int? id})`
  - **iOS implementation (`ios/Runner/AlarmPlugin.swift`)**:
    - `startRinging` calls `AlarmAudioPlayer.start(soundId, volume, durationSeconds)`, playing looped audio via `AVAudioSession` category `.playback` (bypassing silent mode).
    - `stopRinging` calls `AlarmAudioPlayer.stop()`.
  - **Android implementation (`android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`)**:
    - Line 50: `startRinging` is currently a no-op returning `result.success(true)`.
    - Line 46: `stopRinging` calls `AlarmService.stopService(this)`.
    - `AlarmService.kt` already contains:
      - Looping audio playback (`playRingtone`)
      - Continuous vibration pattern (`startVibrating`)
      - High-priority foreground notification (`createNotification`, channel `WakeUpAlarmChannel`)
      - Auto-stop deadline handler
      - WakeLock management
- **Haptic Feedback**:
  - `package:flutter/services.dart` provides `HapticFeedback.vibrate()`.

### 1.4 Test Suite Status
- Command: `flutter test`
- Current result: **49 passing tests** (across `notification_budget_test.dart`, `time_utils_test.dart`, `alarm_repository_reschedule_test.dart`, and `widget_test.dart`).
- Existing tests for Timer or Main Navigation: **0**.

---

## 2. Logic Chain

1. **Why `_TimerView` must be overhauled**:
   - `_secondsRemaining = 15 * 60` is hardcoded (Obs 1.1).
   - Requirements explicitly state: *"Thay thế thời gian 15 phút cố định bằng bộ chọn thời lượng linh hoạt (Giờ, Phút, Giây). Khi đếm ngược về 0, phát âm thanh báo + rung và gửi thông báo hệ thống."*
   - Missing `dispose()` in `_TimerViewState` is a bug that leaks tickers and causes crashes when users navigate away during a countdown (Obs 1.1).

2. **How to structure the Flexible Duration Picker**:
   - We need a 3-phase state machine:
     - `setup`: duration picker + quick preset chips + "Bắt đầu" (Start) button.
     - `running` / `paused`: circular countdown display + "Tạm dừng" / "Tiếp tục" + "Đặt lại" (Cancel/Reset) button.
     - `ringing`: countdown has reached 0; triggers alarm sound + vibration + system notification, displays modal alert/dialog with "Dừng" (Stop) button.
   - For duration selection:
     - Use `CupertinoTimerPicker(mode: CupertinoTimerPickerMode.hms, ...)` wrapped in `CupertinoTheme(data: CupertinoThemeData(brightness: Brightness.dark), ...)`. This is built into Flutter, requires no extra dependencies, and matches the app's dark theme.
     - Support hours (0-23), minutes (0-59), seconds (0-59).
     - Provide quick preset chips (+1m, +5m, +10m, +15m, +30m).
   - For circular countdown:
     - Track `_initialTotalSeconds`. Calculate progress as `_secondsRemaining / _initialTotalSeconds`.
     - Display time as `HH:mm:ss` (or `mm:ss` when hours == 0) using tabular figures.

3. **How to implement Audio, Vibration & Notification on completion**:
   - Audio & Vibration:
     - Native assets are already present in Android `res/raw/` and iOS bundle (Obs 1.3).
     - On iOS, `NativeAlarmService.startRinging()` already plays looping alarm audio (Obs 1.3).
     - On Android, `MainActivity.kt`'s `startRinging` is currently a no-op (Obs 1.3). Updating `startRinging` to start `AlarmService` with `ALARM_ID = -999` immediately gives Android looping ringtone, vibration, wakelock, and high-priority notification!
     - In Flutter, also invoke `HapticFeedback.vibrate()` periodically while ringing.
     - When user taps "Dừng", call `NativeAlarmService.stopRinging()`.
   - Notification:
     - On Android, starting `AlarmService` automatically posts an ongoing high-priority notification in `WakeUpAlarmChannel`.
     - On iOS, schedule a local notification via `UNUserNotificationCenter` when the timer starts (with `UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds)`), or trigger immediately when hitting 0.
     - In-App UX: Show a persistent bottom sheet or dialog: *"Hết giờ!"* with a big "Dừng" button.

4. **How to cleanly hide World Clock and Sleep Sounds (Option A)**:
   - In `MainNavigationScreen`, update `_screens` to only contain `AlarmDashboardScreen` and `TimerStopwatchScreen`.
   - Update `BottomNavigationBar.items` to only have 2 items: "Báo thức" and "Hẹn giờ".
   - Because no external caller references tab indices 1, 2, or 3, and no other files import `WorldClockScreen` or `SleepSoundscapeScreen` (Obs 1.2), this change is completely non-breaking.
   - It eliminates all unclickable or dummy UI (Obs 1.2), fully complying with Apple Guideline 2.1 (Incomplete Features).

5. **Test coverage plan**:
   - Add `test/features/timer/timer_screen_test.dart` to verify duration picker rendering, countdown decrement, pause, reset, and completion handling.
   - Add `test/features/home/main_navigation_screen_test.dart` to verify that exactly 2 tabs exist in MVP v1.0 and navigation between them succeeds.

---

## 3. Caveats

1. **Background Timer execution**:
   - In MVP v1.0, countdown runs in Dart via `Timer.periodic`. If the user leaves the app or turns off the screen, mobile operating systems may suspend Dart execution.
   - *Mitigation*: When starting the timer, also schedule a native notification at `now + totalSeconds` (using native `scheduleAlarm` or `UNNotificationRequest`). If the app stays in foreground, Dart rings the timer; if the app is backgrounded, the OS notification wakes the device on time.
2. **Sound Assets in Flutter**:
   - `assets/sounds/` is deliberately excluded from Flutter's asset manifest in `pubspec.yaml` to avoid APK size bloat. Playing sounds via `just_audio` in Dart would fail unless asset paths are added to `pubspec.yaml`. Playing via native `NativeAlarmService` is the correct, architecturally sound route.
3. **Lint cleanup**:
   - When modifying `timer_stopwatch_screen.dart`, replace `.withOpacity()` with `.withValues()` and remove `import 'dart:ui';` to satisfy EPIC 5 zero-lint requirement.

---

## 4. Conclusion

EPIC 3 (R2 - Option A) is well-bounded, low-risk, and ready for implementation. The roadmap comprises four focused changes:

### Implementation Roadmap

#### Step 1: Overhaul `_TimerView` in `lib/features/timer/presentation/timer_stopwatch_screen.dart`
- Introduce state machine: `TimerMode { setup, running, paused, ringing }`.
- In `setup` mode:
  - Display `CupertinoTimerPicker` with dark theme styling.
  - Add quick duration preset chips (1m, 5m, 10m, 15m, 30m).
  - Add "Bắt đầu" (Start) button.
- In `running` / `paused` mode:
  - Display `CircularProgressIndicator` with dynamic `_secondsRemaining / _initialTotalSeconds`.
  - Format remaining time string as `HH:mm:ss` or `mm:ss`.
  - Provide "Tạm dừng" / "Tiếp tục" and "Đặt lại" buttons.
- In `ringing` mode:
  - Call `NativeAlarmService.startRinging()`, trigger `HapticFeedback.vibrate()`.
  - Display "Hết giờ!" dialog with "Dừng" button.
  - On stop, call `NativeAlarmService.stopRinging()`.
- Add proper `dispose()` to cancel `_timer` and call `stopRinging()`.
- Fix lint warnings (`withOpacity` -> `withValues`, remove unused `dart:ui` import).

#### Step 2: Implement Android Native `startRinging` in `android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`
- Replace line 50 (`result.success(true)`) with logic that starts `AlarmService` via `startForegroundService` (with `ALARM_ID = -999`, `soundId = "alarm_default"`, `autoStopMs`).
- This instantly activates ringtone playback, vibration, wakelock, and notification on Android.

#### Step 3: Simplify `MainNavigationScreen` in `lib/features/home/presentation/main_navigation_screen.dart`
- Retain only 2 screens in `_screens`: `AlarmDashboardScreen` and `TimerStopwatchScreen`.
- Retain only 2 items in `BottomNavigationBar`:
  1. `BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Báo thức')`
  2. `BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom), label: 'Hẹn giờ')`
- Leave `world_clock_screen.dart` and `sleep_soundscape_screen.dart` untouched in their respective folders for future release phases.

#### Step 4: Add Automated Unit & Widget Tests in `test/`
- Create `test/features/timer/timer_screen_test.dart`:
  - Verify `TimerStopwatchScreen` renders both tabs ("BẤM GIỜ", "HẸN GIỜ").
  - Verify duration picker appears in setup mode.
  - Verify countdown updates on start.
- Create `test/features/home/main_navigation_screen_test.dart`:
  - Verify `MainNavigationScreen` displays exactly 2 tabs ("Báo thức", "Hẹn giờ").
  - Verify "Thế giới" and "Giấc ngủ" tabs are absent.
  - Verify tapping tab switches screen.

---

## 5. Verification Method

To independently verify after implementation:

1. **Verify Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Expected*: Zero issues found in `timer_stopwatch_screen.dart` and `main_navigation_screen.dart`.

2. **Verify All Automated Tests**:
   ```powershell
   flutter test
   ```
   *Expected*: All 49 existing tests + new timer & navigation tests PASS (Total ~53+ tests passing).

3. **Verify Code Layout & Guidelines**:
   - Inspect `lib/features/home/presentation/main_navigation_screen.dart`: confirm only 2 tabs exist in `_screens` and `items`.
   - Inspect `lib/features/timer/presentation/timer_stopwatch_screen.dart`: confirm `CupertinoTimerPicker`, state machine, dynamic circular indicator, `dispose()`, and ringing alert exist.
   - Confirm no files under `.agents/teamwork/` contain source code or test code.
