# Challenger Handoff Report: Milestone 1 (EPIC 2) — Alarm Update & Wake-up Missions

## 1. Observation

### 1.1 Scope & Direct Code Observations
1. **Schema Definition & Migration**:
   - `lib/data/local/database.dart` lines 36-38: added columns `missionEnabled` (default `false`), `missionType` (default `'math'`), `missionDifficulty` (default `'medium'`).
   - `lib/data/local/database.dart` line 65: `schemaVersion` is bumped to `2`.
   - `lib/data/local/database.dart` lines 68-79: `MigrationStrategy` handles `onUpgrade` from `< 2` by running `m.addColumn` for each of the three new columns.
2. **Alarm Update Implementation**:
   - `lib/data/repositories/alarm_repository.dart` lines 77-98: `updateAlarm(Alarm alarm)` calls `await _db.updateAlarm(alarm)`, unconditionally calls `NativeAlarmService.cancelAlarm(alarm.id)`, and if `alarm.enabled` is `true`, calls `_schedule(...)`.
   - `lib/features/alarms/presentation/edit_alarm_screen.dart` lines 75-109: `_saveAlarm()` properly branches on `widget.existingAlarm == null` vs `!= null`. When updating an existing alarm, it updates hour, minute, repeatDays, label (nullable Value), vibrate, mission configuration (`_missionEnabled`, `_missionType`, `_missionDifficulty`), resets `skipNextDate: const Value(null)`, and awaits `ref.read(alarmRepositoryProvider).updateAlarm(...)`.
3. **Ringing Screen Mission Gate & Snooze Decoding**:
   - `lib/features/alarms/presentation/ringing_screen.dart` lines 47-49: `_realId` correctly un-offsets snoozed alarms (`widget.alarmId >= AlarmRepository.snoozeIdOffset ? widget.alarmId - AlarmRepository.snoozeIdOffset : widget.alarmId`).
   - `lib/features/alarms/presentation/ringing_screen.dart` lines 122-159: `_dismissAlarm()` queries `missionEnabled` and `missionDifficulty`. If `missionEnabled == true`, it launches `MathMissionScreen`. If not solved (`success != true`), dismissal aborts without stopping native ringing or rescheduling. If `missionEnabled == false`, math challenge is completely bypassed.
4. **Alarm Card Indicator**:
   - `lib/features/alarms/presentation/widgets/alarm_card.dart` lines 118-121: displays `Icons.calculate` with label `'Toán'` when `alarm.missionEnabled` is `true`.

### 1.2 Verification Commands & Outputs
1. **Existing Unit Tests**:
   - Command: `flutter test`
   - Output: `00:03 +54: All tests passed!` (54 tests passing prior to challenger harness).
2. **Empirical Challenger Test Suite**:
   - Created test suite: `test/data/m1_challenger_verification_test.dart` (11 new empirical tests covering v1 -> v2 schema migration on pre-populated databases, updateAlarm edge cases, rapid successive updates, and mission gating).
   - Command: `flutter test test/data/m1_challenger_verification_test.dart`
   - Output: `00:00 +11: All tests passed!`
3. **Full Suite Execution**:
   - Command: `flutter test`
   - Output: `00:01 +65: All tests passed!` (65 tests passed, 0 failures).
4. **Static Analysis**:
   - Command: `flutter analyze lib/data/local/database.dart lib/data/local/database.g.dart lib/features/alarms/presentation/edit_alarm_screen.dart lib/features/alarms/presentation/ringing_screen.dart lib/features/alarms/presentation/widgets/alarm_card.dart test/data/alarm_repository_reschedule_test.dart test/data/m1_challenger_verification_test.dart`
   - Output: `No issues found! (ran in 1.6s)`

---

## 2. Logic Chain

### 2.1 SQLite Schema Migration (v1 -> v2) Stress-Testing
1. An empirical test was constructed by initializing a raw SQLite database at `PRAGMA user_version = 1` with 3 pre-existing alarms having varying configurations (repeating daily with label, one-time disabled without label with skipNextDate, repeating weekdays with custom sound/volume).
2. The database was then opened via `AppDatabase.forTesting`, triggering `MigrationStrategy.onUpgrade(from: 1, to: 2)`.
3. Observations confirmed:
   - Migration succeeded with 0 SQLite syntax or schema errors.
   - All 3 pre-existing records remained completely intact across all original columns.
   - Newly added columns were populated with their default values: `missionEnabled == false`, `missionType == 'math'`, `missionDifficulty == 'medium'`.
   - `updateAlarm` performed on a migrated record successfully updated both SQLite and native scheduling parameters.
   - New alarms inserted into the migrated database successfully coexisted with migrated records.

### 2.2 Alarm Update Logic & Native Rescheduling Edge Cases
1. **Time-Only Update**: Verifies that updating `hour: 8, minute: 15` properly replaces the record in SQLite, invokes `cancelAlarm(id)`, and invokes `scheduleAlarm` with the new time while preserving sound, volume, repeatDays, and mission configurations.
2. **Label Modification & Clearing**: Verifies that changing a label from `'Họp'` to empty/null sets `label: null` in SQLite, while `NativeAlarmService` safely maps `null` to `''` over MethodChannel to avoid platform null-pointer exceptions.
3. **Max-Length Constraint**: Verifies that a 50-character label (the max length constraint in `Alarms.label`) updates and stores correctly.
4. **Repeat Bitmask Change**: Verifies that toggling repeatDays from `0` to `127` updates the iOS notification budget allocation (`futureCount > 0`).
5. **Enabled Toggle**: Verifies that updating an alarm with `enabled = false` calls `cancelAlarm(id)` and skips `scheduleAlarm`, preventing ghost alarms. Updating from `false` to `true` re-schedules the alarm.
6. **Rapid Successive Updates**: Executed 5 successive updates on the same alarm in a loop; confirmed that SQLite and OS scheduling match the final 5th state without race conditions or corrupted data.
7. **Boundary Times**: Verified updates for `00:00` and `23:59` execute cleanly.

### 2.3 Ringing Screen & Wake-up Mission Gate
1. Tested string parsing for `missionDifficulty`: `'easy'` -> `MathDifficulty.easy`, `'medium'` -> `MathDifficulty.medium`, `'hard'` -> `MathDifficulty.hard`, unknown/null -> default `MathDifficulty.medium`.
2. Verified `_realId` extraction when `widget.alarmId` has `snoozeIdOffset` (`1000000`). Snoozed alarms correctly query and reschedule the root alarm ID while stopping audio for the temporary snooze notification ID.
3. Verified conditional logic: when `missionEnabled == false`, dismissal is immediate; when `missionEnabled == true`, math completion is mandatory.

---

## 3. Caveats

1. **Hardware / Foreground Service Execution**: Unit and integration tests verify the Dart application layer, Drift SQLite engine, and MethodChannel communication. Physical device OS behavior (such as aggressive battery killer daemons on specific OEM Android skins or iOS lockscreen notification banners) is reliant on the native platform implementations in `AlarmTriggerReceiver.kt` and `AlarmScheduler.swift`.
2. **Additional Mission Types**: Only the math mission is implemented in UI and ringing gates for Milestone 1; barcode and shake missions are planned for subsequent milestones.

---

## 4. Conclusion & Verdict

Verdict: **APPROVE**

All requirements specified for Milestone 1 (EPIC 2) in `ORIGINAL_REQUEST.md` and `PROJECT.md` have been empirically challenged, rigorously tested, and verified to be correct:
- SQLite schema migration from v1 to v2 preserves existing user data and correctly assigns default values for mission fields (`false`, `'math'`, `'medium'`).
- `updateAlarm` correctly updates SQLite database records and synchronizes with native OS alarm scheduling, cancelling old alarms and re-scheduling only when enabled.
- Ringing screen respects the `missionEnabled` flag: alarms without missions dismiss immediately; alarms with missions enforce math challenge completion.
- Edge cases in alarm updates (time-only, label-only, repeat bitmasks, enabled toggle, rapid consecutive updates, boundary values) all pass without error.
- Full test suite passes 100% (65/65 tests passed), with 0 analyze warnings across all owned files.

---

## 5. Verification Method

### 5.1 Run Full Test Suite
```powershell
flutter test
```
**Expected Result**: `All tests passed!` (65 tests passed).

### 5.2 Run Specific Challenger Empirical Test Suite
```powershell
flutter test test/data/m1_challenger_verification_test.dart
```
**Expected Result**: `00:00 +11: All tests passed!`

### 5.3 Static Code Analysis
```powershell
flutter analyze lib/data/local/database.dart lib/data/local/database.g.dart lib/features/alarms/presentation/edit_alarm_screen.dart lib/features/alarms/presentation/ringing_screen.dart lib/features/alarms/presentation/widgets/alarm_card.dart test/data/alarm_repository_reschedule_test.dart test/data/m1_challenger_verification_test.dart
```
**Expected Result**: `No issues found!`
