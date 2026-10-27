# Orchestration Master Plan — WakeUp+ Core Features & Refinement

## Objectives
1. Implement all requirements from EPIC 2 through EPIC 6 as detailed in `ORIGINAL_REQUEST.md` and `PROJECT.md`.
2. Ensure 100% test pass on existing (49 tests) and all newly added unit/widget tests.
3. Bring `flutter analyze` to 0 issues (zero warnings, zero infos).
4. Verify complete integrity and adherence to Flutter and store standards.

## Execution Sequence

### Milestone 1: Alarm Update & Wake-up Missions (EPIC 2 / R1)
- **Files Owned**:
  - `lib/data/local/database.dart`
  - `lib/data/local/database.g.dart` (generated)
  - `lib/features/alarms/presentation/edit_alarm_screen.dart`
  - `lib/features/alarms/presentation/ringing_screen.dart`
  - `lib/features/alarms/presentation/widgets/alarm_card.dart`
  - `test/data/alarm_repository_reschedule_test.dart`
- **Actions**:
  1. Add `missionEnabled`, `missionType`, `missionDifficulty` to `Alarms` table in `database.dart`.
  2. Set `schemaVersion = 2` with `MigrationStrategy.onUpgrade` using `addColumn`.
  3. Run `dart run build_runner build --delete-conflicting-outputs`.
  4. In `edit_alarm_screen.dart`: add mission UI (switch & difficulty dropdown), wire up `updateAlarm` when `widget.existingAlarm != null`, manage `TextEditingController` lifecycle.
  5. In `ringing_screen.dart`: query alarm by `realId` (account for snooze offset); if `missionEnabled == true` require `MathMissionScreen`; if `false` dismiss immediately.
  6. Add unit tests for `updateAlarm` in `alarm_repository_reschedule_test.dart` and remove unused `id2`.
  7. Run `flutter test` and `flutter analyze`.
- **Verification Gate**:
  - 1 Worker -> 2 Reviewers + 2 Challengers + 1 Auditor -> Gate check in `GATE_STATUS.md`.

### Milestone 2: Flexible Duration Timer & Navigation Simplification (EPIC 3 / R2 - Option A)
- **Files Owned**:
  - `lib/features/timer/presentation/timer_stopwatch_screen.dart`
  - `lib/features/home/presentation/main_navigation_screen.dart`
  - `android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`
  - `test/features/timer/timer_screen_test.dart`
  - `test/features/home/main_navigation_screen_test.dart`
- **Actions**:
  1. Replace fixed 15-min countdown with `CupertinoTimerPicker` (hours, minutes, seconds) with dark theme styling.
  2. State machine: setup, running, paused, ringing. Quick preset chips (+1m, +5m, +10m, +15m, +30m).
  3. Dynamic progress indicator and time display (`HH:mm:ss`).
  4. Native ringing on completion via `NativeAlarmService.startRinging()`, haptic feedback, and ringing modal dialog with "Dừng" button.
  5. Proper `dispose()` method in timer view state.
  6. In `MainActivity.kt`, wire `startRinging` MethodChannel to launch `AlarmService` foreground service.
  7. In `main_navigation_screen.dart`, reduce screens and navigation bar items to 2: "Báo thức" and "Hẹn giờ" (Option A).
  8. Add tests for timer state machine and 2-tab navigation.
- **Verification Gate**:
  - 1 Worker -> 2 Reviewers + 2 Challengers + 1 Auditor -> Gate check in `GATE_STATUS.md`.

### Milestone 3: Monetization & Legal Compliance (EPIC 4 / R3)
- **Files Owned**:
  - `pubspec.yaml`
  - `lib/main.dart`
  - `lib/features/monetization/presentation/paywall_screen.dart`
  - `test/features/monetization/paywall_screen_test.dart`
- **Actions**:
  1. Add `url_launcher: ^6.3.0` to `pubspec.yaml`.
  2. Initialize RevenueCat safely in `main.dart` using `--dart-define=REVENUECAT_API_KEY` and try-catch with timeout.
  3. Wire `PaywallScreen` buttons ("Nâng Cấp Ngay", "Khôi phục giao dịch") to `Purchases` with thorough exception handling (`PlatformException`, `PurchasesErrorCode`, generic).
  4. Add clickable Privacy Policy and EULA links using `url_launcher`.
  5. Add widget tests for safe paywall behavior.
- **Verification Gate**:
  - 1 Worker -> 2 Reviewers + 2 Challengers + 1 Auditor -> Gate check in `GATE_STATUS.md`.

### Milestone 4: Infrastructure Fallback & Lint Cleanliness (EPIC 5 / R4)
- **Files Owned**:
  - `lib/core/services/analytics_service.dart`
  - `lib/core/services/firebase_options.dart`
  - Codebase-wide lint targets for deprecated APIs and prints.
- **Actions**:
  1. Make Mixpanel and Firebase initialization conditional on `--dart-define` with safe no-op fallbacks.
  2. Eliminate all remaining `flutter analyze` issues (replace `withOpacity` with `withValues(alpha:)`, `activeColor` with `activeThumbColor`, `anonKey` with `publishableKey`, replace `print` with `debugPrint`, add missing `const`).
  3. Ensure `flutter analyze` returns `No issues found!`.
- **Verification Gate**:
  - 1 Worker -> 2 Reviewers + 2 Challengers + 1 Auditor -> Gate check.

### Milestone 5: App Icon & Store Assets (EPIC 6 / R5)
- **Files Owned**:
  - `pubspec.yaml` (dev_dependencies: `flutter_launcher_icons: ^0.13.1`)
  - `assets/images/app_icon.png`
  - `store/` directories
- **Actions**:
  1. Generate official 1024x1024 master app icon.
  2. Configure and run `dart run flutter_launcher_icons`.
  3. Populate store directories with compliant icons and screenshots.
- **Verification Gate**:
  - 1 Worker -> 2 Reviewers + 2 Challengers + 1 Auditor -> Gate check.

### Milestone 6: Final Acceptance & Quality Gate
- Run full test suite (`flutter test`) and static analysis (`flutter analyze`).
- Verify all requirements from EPIC 2 through EPIC 6 are fulfilled.
- Send completion message to parent.
