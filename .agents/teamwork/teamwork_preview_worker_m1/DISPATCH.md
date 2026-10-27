# DISPATCH — Worker M1: Alarm Update & Wake-up Missions (EPIC 2)

## Mission
Implement Milestone 1: Fix alarm update logic in SQLite and Native Alarm Engine, add wake-up mission fields (`missionEnabled`, `missionType`, `missionDifficulty`) to database schema and `edit_alarm_screen.dart`, update `ringing_screen.dart` to require math puzzle only if `missionEnabled == true`, and add unit tests for `updateAlarm`.

## References & Inputs
- Original Request: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md`
- Project Master Plan: `d:/MyProjects/Medium-project/app/app_clock/PROJECT.md`
- Explorer 1 Survey Report: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_1/handoff.md`

## File Ownership
You have exclusive write access to:
- `lib/data/local/database.dart`
- `lib/data/local/database.g.dart`
- `lib/features/alarms/presentation/edit_alarm_screen.dart`
- `lib/features/alarms/presentation/ringing_screen.dart`
- `lib/features/alarms/presentation/widgets/alarm_card.dart`
- `test/data/alarm_repository_reschedule_test.dart`
Do NOT modify files outside of this boundary.

## Instructions
1. In `lib/data/local/database.dart`:
   - Add columns to `Alarms` table:
     ```dart
     BoolColumn get missionEnabled => boolean().withDefault(const Constant(false))();
     TextColumn get missionType => text().withDefault(const Constant('math'))();
     TextColumn get missionDifficulty => text().withDefault(const Constant('medium'))();
     ```
   - Bump `schemaVersion` to 2.
   - Implement `MigrationStrategy.onUpgrade` with `addColumn` for the 3 columns when `from < 2`.
2. Run code generation:
   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```
3. In `lib/features/alarms/presentation/edit_alarm_screen.dart`:
   - Add state: `_missionEnabled`, `_missionType`, `_missionDifficulty`, and a lifecycle-managed `_labelController`.
   - Initialize state in `initState()` from `widget.existingAlarm`.
   - Add `_buildMissionCard()` with toggle switch and difficulty dropdown.
   - Replace line 70 (`// TODO: Cập nhật thông qua repository`) so that when `widget.existingAlarm != null`, it calls `await ref.read(alarmRepositoryProvider).updateAlarm(...)` using `widget.existingAlarm!.copyWith(...)`.
   - Fix deprecated `Switch.activeColor` (use `activeThumbColor`) and `.withOpacity` (use `.withValues(alpha:)`).
4. In `lib/features/alarms/presentation/ringing_screen.dart`:
   - Compute `realId = widget.alarmId >= AlarmRepository.snoozeIdOffset ? widget.alarmId - AlarmRepository.snoozeIdOffset : widget.alarmId`.
   - Read the alarm from `databaseProvider`.
   - In `_dismissAlarm()`: if `alarm?.missionEnabled == true`, navigate to `MathMissionScreen(difficulty: ..., requiredQuestions: 3)`. If puzzle not completed, do not dismiss. If `missionEnabled == false`, bypass mission, immediately call `NativeAlarmService.stopRinging(id: widget.alarmId)`, and reschedule via `repo.rescheduleAfterFire(...)`.
   - In `_snoozeAlarm()`: use `realId`.
5. In `lib/features/alarms/presentation/widgets/alarm_card.dart`:
   - If `alarm.missionEnabled`, display mission icon/badge. Fix `Switch.activeColor`.
6. In `test/data/alarm_repository_reschedule_test.dart`:
   - Remove unused variable `id2` (line 414).
   - Add unit test group for `updateAlarm` (update time/repeat/label, update with `enabled = false` to cancel native alarm, update mission fields).
7. Verification:
   - Run `flutter analyze` on the modified files to ensure 0 errors/warnings.
   - Run `flutter test` to ensure all tests pass (existing 49 + new unit tests).

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Completion Deliverable
Write your report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m1/handoff.md` and send a message when done.

## 2026-10-18T19:49:35Z
You are Worker M1 for WakeUp+ app core feature completion.
Your working directory is: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m1
Read d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md, d:/MyProjects/Medium-project/app/app_clock/PROJECT.md, and d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m1/DISPATCH.md before starting.

Scope: Milestone 1 (Alarm Update & Wake-up Missions - EPIC 2)
Implement the changes specified in DISPATCH.md across your owned files:
- lib/data/local/database.dart & database.g.dart (add mission fields, bump schemaVersion to 2, run build_runner)
- lib/features/alarms/presentation/edit_alarm_screen.dart (wire up updateAlarm on edit, add mission card with switch & difficulty, fix label controller lifecycle, fix deprecations)
- lib/features/alarms/presentation/ringing_screen.dart (check missionEnabled before demanding math puzzle, handle snooze offset 1000000)
- lib/features/alarms/presentation/widgets/alarm_card.dart (show mission badge, fix Switch deprecation)
- test/data/alarm_repository_reschedule_test.dart (remove unused id2, add comprehensive unit tests for updateAlarm)

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Run tests (`flutter test`) and `flutter analyze` on the modified files to verify your work.
Write your completion report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m1/handoff.md` and call send_message when finished.
