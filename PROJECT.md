# Project: WakeUp+ Core Features & Refinement

## Architecture
- **Framework**: Flutter 3.x / Dart 3.x, Riverpod state management.
- **Database & Persistence**: Drift (SQLite) with schema versioning and code generation (`build_runner`).
- **Alarm Engine**: Native Alarm MethodChannel (`com.wakeup.app/alarm`) interfacing with Android `AlarmManager`/`AlarmService` and iOS `UNUserNotificationCenter`/`AVAudioSession`.
- **Timer Engine**: Dart `Timer.periodic` with `CupertinoTimerPicker`, paired with native audio, haptics, and foreground notification.
- **Monetization**: RevenueCat (`purchases_flutter`) with graceful offline/unconfigured fallback.
- **Analytics & Crash Reporting**: Firebase Crashlytics and Mixpanel with `--dart-define` environment configuration and safe no-op fallbacks.
- **Legal Compliance**: Privacy Policy and EULA links on paywall via `url_launcher`.
- **Branding**: Official WakeUp+ app icon via `flutter_launcher_icons` and populated store assets.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Alarm Edit DB Update | Update existing alarm in SQLite table `Alarms` on save | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Alarm Edit Native Reschedule | Cancel old OS alarm and reschedule with new time/parameters | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Wake-up Mission Schema | Add `missionEnabled`, `missionType`, `missionDifficulty` to SQLite schema | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Wake-up Mission UI in Edit | Add mission toggle switch and difficulty dropdown in `edit_alarm_screen.dart` | M1 | ORIGINAL_REQUEST §R1 |
| 5 | Conditional Ringing Mission | In `ringing_screen.dart`, require math puzzle only if `missionEnabled == true` | M1 | ORIGINAL_REQUEST §R1 |
| 6 | Alarm Update Unit Tests | Add unit tests for `updateAlarm` covering reschedule, disable, and mission fields | M1 | ORIGINAL_REQUEST §Testing |
| 7 | Flexible Duration Timer | Replace 15-min fixed timer with Hours/Minutes/Seconds picker in `timer_stopwatch_screen.dart` | M2 | ORIGINAL_REQUEST §R2 |
| 8 | Timer Sound, Vibration & Notification | Play audio, vibrate, and notify upon countdown reaching 0 | M2 | ORIGINAL_REQUEST §R2 |
| 9 | Navigation Simplification (Option A) | Hide 'World Clock' and 'Sleep Sounds' from `MainNavigationScreen` for MVP v1.0 | M2 | ORIGINAL_REQUEST §R2 |
| 10 | Timer & Navigation Tests | Add tests for flexible timer state machine and 2-tab navigation | M2 | ORIGINAL_REQUEST §Testing |
| 11 | Safe RevenueCat Initialization | Initialize RevenueCat safely in `main.dart` with try-catch and `--dart-define` check | M3 | ORIGINAL_REQUEST §R3 |
| 12 | Safe Paywall Upgrade & Restore | Connect CTA buttons in `PaywallScreen` with full exception handling (no crash) | M3 | ORIGINAL_REQUEST §R3 |
| 13 | Legal Links (Privacy & EULA) | Add external links to Privacy Policy and EULA in `PaywallScreen` via `url_launcher` | M3 | ORIGINAL_REQUEST §R3 |
| 14 | Safe Analytics & Crashlytics | Configure Mixpanel and Firebase with `--dart-define` and no-op fallback | M4 | ORIGINAL_REQUEST §R4 |
| 15 | Deprecated API & Lint Elimination | Fix all 57 `flutter analyze` issues (replace `withOpacity`, `activeColor`, `print`, etc.) | M4 | ORIGINAL_REQUEST §R4 |
| 16 | Official App Icon Generation | Configure `flutter_launcher_icons` with official brand icon for Android & iOS | M5 | ORIGINAL_REQUEST §R5 |
| 17 | Store Screenshot Assets | Populate required store asset directories with compliant images | M5 | ORIGINAL_REQUEST §R5 |
| 18 | Full Test Suite Pass & Clean Analyze | Ensure 100% test pass (>=55 tests) and 0 analyze warnings | M6 | ORIGINAL_REQUEST §Testing |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Alarm Update & Wake-up Missions (EPIC 2) | Schema migration (v2), Drift generation, edit_alarm_screen save logic, ringing_screen mission gate, unit tests | None | DONE |
| M2 | Flexible Timer & Clean Navigation (EPIC 3) | CupertinoTimerPicker, timer state machine, native ringing, 2-tab MainNavigationScreen | None | DONE |
| M3 | Monetization & Legal (EPIC 4) | RevenueCat safe init, PaywallScreen buttons exception handling, Privacy/EULA links | None | DONE |
| M4 | Infrastructure & Zero-Lint (EPIC 5) | Mixpanel & Crashlytics --dart-define safe fallback, resolve all 57 flutter analyze issues | M1, M2, M3 | DONE |
| M5 | App Icon & Store Assets (EPIC 6) | flutter_launcher_icons config, assets/images/app_icon.png, store/ directory assets | None | DONE |
| M6 | Final Verification & Quality Gate | 100% test pass, flutter analyze 0 issues, end-to-end acceptance check | M1, M2, M3, M4, M5 | DONE |

## Interface Contracts
### Alarms Table ↔ Drift ORM / Alarm Model
- Table `Alarms`:
  - `missionEnabled`: `boolean().withDefault(const Constant(false))()`
  - `missionType`: `text().withDefault(const Constant('math'))()`
  - `missionDifficulty`: `text().withDefault(const Constant('medium'))()`
- `schemaVersion`: 2
- `MigrationStrategy.onUpgrade`: calls `m.addColumn` for the 3 new columns when `from < 2`.

### EditAlarmScreen ↔ AlarmRepository
- `_saveAlarm()`:
  - If `widget.existingAlarm == null`: `await ref.read(alarmRepositoryProvider).addAlarm(alarmData)`
  - If `widget.existingAlarm != null`: `await ref.read(alarmRepositoryProvider).updateAlarm(updatedAlarm)`
  - `updatedAlarm`: `widget.existingAlarm!.copyWith(...)` preserving `id`, `createdAt`, updating `updatedAt`, `skipNextDate: const Value(null)`.

### RingingScreen ↔ AlarmRepository & NativeAlarmService
- `realId`: `widget.alarmId >= AlarmRepository.snoozeIdOffset ? widget.alarmId - AlarmRepository.snoozeIdOffset : widget.alarmId`
- Lookup alarm from `databaseProvider` using `realId`.
- If `missionEnabled == true`: navigate to `MathMissionScreen(difficulty: ..., requiredQuestions: 3)`. If puzzle cancelled/unsolved, keep ringing.
- If `missionEnabled == false`: bypass puzzle.
- Call `NativeAlarmService.stopRinging(id: widget.alarmId)`.
- Call `repo.rescheduleAfterFire(realId, firedAt: ..., action: 'dismissed')`.

### MainNavigationScreen
- `_screens`: `const [AlarmDashboardScreen(), TimerStopwatchScreen()]`
- `BottomNavigationBar.items`: 2 items (Báo thức, Hẹn giờ).

### RevenueCat & Analytics Environment
- `REVENUECAT_API_KEY`: via `--dart-define=REVENUECAT_API_KEY=...`. Fallback: offline mock.
- `MIXPANEL_TOKEN`: via `--dart-define=MIXPANEL_TOKEN=...`. Fallback: no-op.
- `FIREBASE_API_KEY`: via `--dart-define=FIREBASE_API_KEY=...`. Fallback: skip Crashlytics.

## Code Layout
- `lib/data/local/`: `database.dart`, `database.g.dart`, `database_provider.dart`, `native_alarm_service.dart`
- `lib/data/repositories/`: `alarm_repository.dart`
- `lib/features/alarms/presentation/`: `alarm_dashboard_screen.dart`, `edit_alarm_screen.dart`, `ringing_screen.dart`, `widgets/alarm_card.dart`
- `lib/features/alarms/presentation/missions/`: `math_mission_screen.dart`
- `lib/features/timer/presentation/`: `timer_stopwatch_screen.dart`
- `lib/features/home/presentation/`: `main_navigation_screen.dart`
- `lib/features/monetization/presentation/`: `paywall_screen.dart`
- `lib/core/services/`: `analytics_service.dart`, `firebase_options.dart`
- `assets/images/`: `app_icon.png`
- `test/`: unit and widget tests
- `store/`: store screenshot directories
