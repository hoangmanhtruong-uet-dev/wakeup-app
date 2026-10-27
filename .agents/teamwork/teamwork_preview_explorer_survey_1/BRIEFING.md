# BRIEFING — 2026-10-18T19:46:00Z

## Mission
Investigate and roadmap EPIC 2 (R1) - Alarm Update & Wake-up Missions for WakeUp+ app core feature completion.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigator, synthesizer
- Working directory: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_1
- Original parent: 02c07653-2f5a-416a-8c52-98a382d4e916
- Milestone: EPIC 2 Survey

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Scope limited to EPIC 2 (R1): Alarm Update & Wake-up Missions

## Current Parent
- Conversation ID: 02c07653-2f5a-416a-8c52-98a382d4e916
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `lib/data/local/database.dart`, `database.g.dart`, `database_provider.dart`
  - `lib/data/repositories/alarm_repository.dart`, `alarm_repository_provider.dart`
  - `lib/data/local/native_alarm_service.dart`
  - `lib/features/alarms/presentation/edit_alarm_screen.dart`
  - `lib/features/alarms/presentation/ringing_screen.dart`
  - `lib/features/alarms/presentation/missions/math_mission_screen.dart`
  - `lib/features/alarms/presentation/alarm_dashboard_screen.dart`
  - `lib/features/alarms/presentation/widgets/alarm_card.dart`
  - `lib/features/alarms/providers/alarm_list_provider.dart`
  - `android/app/src/main/kotlin/com/wakeup/app/MainActivity.kt`, `AlarmScheduler.kt`, `AlarmService.kt`
  - `ios/Runner/AlarmPlugin.swift`
  - `test/data/alarm_repository_reschedule_test.dart`, `test/widget_test.dart`
- **Key findings**:
  - `updateAlarm` logic is already fully written in `AlarmRepository` and `AppDatabase`, but `EditAlarmScreen._saveAlarm()` had line 70 as `// TODO: Cập nhật thông qua repository` and did nothing when `existingAlarm != null`.
  - Schema migration needed: Drift schema version 1 -> 2, adding `missionEnabled` (bool, default false), `missionType` (text, default 'math'), `missionDifficulty` (text, default 'medium') to `Alarms` table. `build_runner` generates updated `database.g.dart`.
  - `edit_alarm_screen.dart` needs UI components: Switch for `missionEnabled`, DropdownButton for `missionDifficulty` ('easy', 'medium', 'hard'), and wiring to `copyWith(...)` + `updateAlarm(...)`.
  - `ringing_screen.dart` currently hardcodes jumping to `MathMissionScreen(difficulty: MathDifficulty.medium)`. It needs to fetch the `Alarm` via `databaseProvider` / `alarmRepositoryProvider` using `alarmId` (accounting for `snoozeIdOffset`), inspect `missionEnabled`, and only open `MathMissionScreen` if `true`, otherwise dismiss immediately.
  - Existing tests: 49 unit tests pass. Additional unit tests needed for `updateAlarm` (CRUD, reschedule, disable, mission fields).
- **Unexplored areas**: None within EPIC 2 scope. All target files and dependencies inspected and verified.

## Key Decisions Made
- Confirmed root cause of update bug is the missing invocation in `EditAlarmScreen`.
- Designed exact Drift schema migration and code patch for `database.dart`.
- Designed exact UI structure and state bindings for `EditAlarmScreen`.
- Designed exact dismiss/mission gate for `RingingScreen`.
- Outlined comprehensive unit test suite for `updateAlarm`.

## Artifact Index
- handoff.md — 5-component handoff report with exact findings, code snippets, and implementation roadmap.
- progress.md — Liveness heartbeat.
