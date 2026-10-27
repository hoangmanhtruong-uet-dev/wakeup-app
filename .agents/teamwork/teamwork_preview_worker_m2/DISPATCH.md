# DISPATCH — Worker M2: Flexible Timer & Navigation Simplification (EPIC 3 - Option A)

## Mission
Implement Milestone 2: Replace fixed 15-minute timer with a flexible duration selector (hours, minutes, seconds), sound + vibration + system notification upon completion, and temporarily hide 'World Clock' and 'Sleep Sounds' tabs from `MainNavigationScreen` (Option A).

## References & Inputs
- Original Request: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md` § R2
- Project Master Plan: `d:/MyProjects/Medium-project/app/app_clock/PROJECT.md`
- Survey Explorer 2 Report: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_2/handoff.md`

## File Ownership
You have exclusive write access to:
- `lib/features/timer/presentation/timer_stopwatch_screen.dart`
- `lib/features/home/presentation/main_navigation_screen.dart`
- `android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`
- `test/features/timer/timer_screen_test.dart`
- `test/features/home/main_navigation_screen_test.dart`
Do NOT modify files outside of this boundary.

## Instructions
1. In `lib/features/timer/presentation/timer_stopwatch_screen.dart`:
   - Replace the hardcoded `15 * 60` seconds in `_TimerView` with a state machine:
     `TimerMode { setup, running, paused, ringing }`.
   - In `setup` mode:
     - Provide `CupertinoTimerPicker(mode: CupertinoTimerPickerMode.hms, ...)` wrapped in `CupertinoTheme` with dark brightness.
     - Support hours (0-23), minutes (0-59), seconds (0-59).
     - Provide quick preset chips (+1m, +5m, +10m, +15m, +30m).
     - Provide a "Bắt đầu" (Start) button.
   - In `running` and `paused` modes:
     - Render `CircularProgressIndicator` with dynamic `_secondsRemaining / _initialTotalSeconds`.
     - Display formatted remaining time (`HH:mm:ss` or `mm:ss`).
     - Provide "Tạm dừng" (Pause) / "Tiếp tục" (Resume) and "Đặt lại" (Reset) buttons.
   - In `ringing` mode:
     - When countdown reaches 0:
       - Call `NativeAlarmService.startRinging()`.
       - Trigger `HapticFeedback.vibrate()`.
       - Show "Hết giờ!" dialog or persistent modal with a prominent "Dừng" (Stop) button.
       - When user taps "Dừng", call `NativeAlarmService.stopRinging()`, dismiss dialog, and return to `setup` mode.
   - In `_TimerViewState`, implement `dispose()`: cancel active `_timer` and ensure `stopRinging()` is called.
   - Remove unused `import 'dart:ui';` and replace `.withOpacity()` with `.withValues(alpha:)`.
2. In `android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`:
   - In `startRinging` handler, call `AlarmService.startService(this, -999, "alarm_default", 1.0f, 600000L)` so that Android rings with looping audio, vibration, wakelock, and high-priority notification.
3. In `lib/features/home/presentation/main_navigation_screen.dart`:
   - Retain only 2 screens in `_screens`: `AlarmDashboardScreen` and `TimerStopwatchScreen`.
   - Retain only 2 items in `BottomNavigationBar`:
     1. `BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Báo thức')`
     2. `BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom), label: 'Hẹn giờ')`
   - This cleanly hides "World Clock" and "Sleep Sounds" tabs for MVP v1.0.
4. Add automated tests:
   - `test/features/timer/timer_screen_test.dart`: verify tabs, duration picker in setup mode, countdown ticking, pause/reset, and ringing state.
   - `test/features/home/main_navigation_screen_test.dart`: verify exactly 2 navigation tabs exist and screen switching works.
5. Verification:
   - Run `flutter analyze` on modified files (must be 0 issues).
   - Run `flutter test` (all 77 existing tests + new timer & navigation tests must PASS 100%).

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Completion Deliverable
Write your report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m2/handoff.md` and call send_message when done.


## 2026-10-18T20:06:02Z
You are Worker M2 for WakeUp+ app core feature completion.
Your working directory is: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m2
Read d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md, d:/MyProjects/Medium-project/app/app_clock/PROJECT.md, and d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m2/DISPATCH.md before starting.

Scope: Milestone 2 (Flexible Timer & Navigation Simplification - EPIC 3 Option A)
Implement the changes specified in DISPATCH.md across your owned files:
- lib/features/timer/presentation/timer_stopwatch_screen.dart (state machine, CupertinoTimerPicker, dynamic progress, ringing modal with sound/vibration, dispose ticker cleanup, fix deprecations/imports)
- android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt (wire startRinging to AlarmService)
- lib/features/home/presentation/main_navigation_screen.dart (Option A: 2 tabs Báo thức & Hẹn giờ)
- test/features/timer/timer_screen_test.dart (timer state machine and interaction tests)
- test/features/home/main_navigation_screen_test.dart (navigation tab verification tests)

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Run tests (`flutter test`) and `flutter analyze` on modified files.
Write your report to d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m2/handoff.md and call send_message when done.
