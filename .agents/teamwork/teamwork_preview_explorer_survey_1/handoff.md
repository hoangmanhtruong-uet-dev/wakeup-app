# Handoff Report: Survey EPIC 2 (R1) - Alarm Update & Wake-up Missions

## 1. Observation

### 1.1 Architecture & Component Mapping
- **Database Layer**:
  - `lib/data/local/database.dart`: Defines `Alarms` table via Drift ORM and `AppDatabase` class. Currently `schemaVersion = 1` (line 60). Table defines columns: `id`, `hour`, `minute`, `repeatDays`, `enabled`, `label`, `soundId`, `volume`, `rampSeconds`, `vibrate`, `snoozeMinutes`, `snoozeMax`, `autoStopMinutes`, `skipNextDate`, `createdAt`, `updatedAt` (lines 12–37).
  - `lib/data/local/database.g.dart`: Generated Drift classes (`$AlarmsTable`, `Alarm`, `AlarmsCompanion`). Verified Drift code generator is present via `build_runner: ^2.4.8` and `drift_dev: ^2.14.0` in `pubspec.yaml` (lines 35–36).
  - `lib/data/local/database_provider.dart`: Exposes `databaseProvider` (lines 5–14).
- **Repository Layer**:
  - `lib/data/repositories/alarm_repository.dart`: `AlarmRepository` is the single source of truth for scheduling. Contains `updateAlarm(Alarm alarm)` at line 77:
    ```dart
    77:   Future<void> updateAlarm(Alarm alarm) async {
    78:     // 1. Cập nhật DB
    79:     await _db.updateAlarm(alarm);
    80: 
    81:     // 2. Hủy lịch cũ ở OS (luôn hủy để tránh báo thức ảo)
    82:     await NativeAlarmService.cancelAlarm(alarm.id);
    83: 
    84:     // 3. Nếu bật, lập lịch mới
    85:     if (alarm.enabled) {
    86:       await _schedule(
    87:         id: alarm.id,
    88:         hour: alarm.hour,
    89:         minute: alarm.minute,
    90:         repeatDays: alarm.repeatDays,
    91:         skipNextDate: alarm.skipNextDate,
    92:         label: alarm.label,
    93:         soundId: alarm.soundId,
    94:         volume: alarm.volume,
    95:         autoStopMinutes: alarm.autoStopMinutes,
    96:       );
    97:     }
    98:   }
    ```
- **Native Alarm Bridge**:
  - `lib/data/local/native_alarm_service.dart`: MethodChannel `com.wakeup.app/alarm` methods: `scheduleAlarm`, `cancelAlarm`, `stopRinging`, `startRinging`, `consumeMissedAlarms`, `requestNotificationPermission`, `getInitialAlarmPayload`.
  - Android: `MainActivity.kt` lines 16–45, `AlarmScheduler.kt` lines 28–91. Correctly cancels via `AlarmManager.cancel` and reschedules with `FLAG_UPDATE_CURRENT`.
  - iOS: `AlarmPlugin.swift` lines 44–93, `AlarmScheduler.swift`. Correctly cancels existing UNNotification requests and reschedules future chains.
- **Presentation Layer**:
  - `lib/features/alarms/presentation/edit_alarm_screen.dart`: Lines 58–73 in `_saveAlarm()`:
    ```dart
    58:   void _saveAlarm() {
    59:     final alarmData = AlarmsCompanion.insert(
    60:       hour: _selectedTime.hour,
    61:       minute: _selectedTime.minute,
    62:       repeatDays: drift.Value(_encodeRepeatDays(_selectedDays)),
    63:       label: _label.isEmpty ? const drift.Value.absent() : drift.Value(_label),
    64:       vibrate: drift.Value(_isVibrate),
    65:     );
    66: 
    67:     if (widget.existingAlarm == null) {
    68:       ref.read(alarmRepositoryProvider).addAlarm(alarmData);
    69:     } else {
    70:       // TODO: Cập nhật thông qua repository
    71:     }
    72:     Navigator.pop(context);
    73:   }
    ```
    Line 70 is literally an unhandled `// TODO: Cập nhật thông qua repository`.
  - `lib/features/alarms/presentation/ringing_screen.dart`: Lines 99–111 in `_dismissAlarm()`:
    ```dart
    99:   void _dismissAlarm() async {
    100:     // Tạm thời điều hướng sang màn Toán học (Medium, 3 câu)
    101:     // Trong thực tế, cần đọc cấu hình Mission của Alarm từ CSDL
    102:     if (mounted) {
    103:       final success = await Navigator.push<bool>(
    104:         context,
    105:         MaterialPageRoute(
    106:           builder: (context) => const MathMissionScreen(
    107:             difficulty: MathDifficulty.medium,
    108:             requiredQuestions: 3,
    109:           ),
    110:         ),
    111:       );
    ```
    Lines 100–101 explicitly note that navigating unconditionally to `MathMissionScreen(difficulty: MathDifficulty.medium, requiredQuestions: 3)` is temporary and needs to read mission configuration from SQLite.
  - `lib/features/alarms/presentation/missions/math_mission_screen.dart`: Full math puzzle UI with `MathDifficulty { easy, medium, hard }` already implemented. Returns `true` when completed.

### 1.2 Test Suite State
- Executed `flutter test`: 49 tests passed (0 failures) in 1.4s.
- Executed `flutter analyze`: 57 issues reported, including:
  - `unused_local_variable` at `test\data\alarm_repository_reschedule_test.dart:414:13` (`id2`).
  - Deprecated `withOpacity` in `edit_alarm_screen.dart`, `ringing_screen.dart`, `math_mission_screen.dart`, etc.
  - Deprecated `activeColor` on `Switch` in `edit_alarm_screen.dart:201:15` and `alarm_card.dart:89:19`.
- Verified `build_runner`: Executed `dart run build_runner build` and completed successfully in 88s with exit code 0.

---

## 2. Logic Chain

### 2.1 Why Alarm Update Logic Was Failing
1. `AlarmRepository.updateAlarm(Alarm alarm)` and `AppDatabase.updateAlarm(Alarm alarm)` were already implemented and tested in part in `alarm_repository_reschedule_test.dart`.
2. However, when the user tapped an existing alarm in `AlarmDashboardScreen`, `AlarmCard` navigated to `EditAlarmScreen(existingAlarm: alarm)`.
3. When the user edited time, repeat days, or label, and pressed the checkmark icon in `AppBar`, `_saveAlarm()` evaluated:
   ```dart
   if (widget.existingAlarm == null) {
     ref.read(alarmRepositoryProvider).addAlarm(alarmData);
   } else {
     // TODO: Cập nhật thông qua repository
   }
   Navigator.pop(context);
   ```
4. Because the `else` branch contained only a comment, `updateAlarm` was **never invoked**. The edits were discarded, SQLite was never touched, and `NativeAlarmService.cancelAlarm` / `scheduleAlarm` were never called.
5. In addition, `_saveAlarm()` was synchronous (`void _saveAlarm()`), so even for `addAlarm`, database/native futures were not awaited before `Navigator.pop(context)`.

### 2.2 Schema Addition & Migration Logic
1. The table `Alarms` currently lacks fields for Wake-up Missions.
2. Requirements specify: `missionEnabled` (bool), `missionType` (String/enum), and `missionDifficulty` (String/enum).
3. Drift column definitions to add to `lib/data/local/database.dart`:
   ```dart
   BoolColumn get missionEnabled => boolean().withDefault(const Constant(false))();
   TextColumn get missionType => text().withDefault(const Constant('math'))();
   TextColumn get missionDifficulty => text().withDefault(const Constant('medium'))();
   ```
4. Bumping `schemaVersion` from `1` to `2` and defining `MigrationStrategy` in `AppDatabase`:
   ```dart
   @override
   int get schemaVersion => 2;

   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) async {
       await m.createAll();
     },
     onUpgrade: (m, from, to) async {
       if (from < 2) {
         await m.addColumn(alarms, alarms.missionEnabled);
         await m.addColumn(alarms, alarms.missionType);
         await m.addColumn(alarms, alarms.missionDifficulty);
       }
     },
     beforeOpen: (details) async {
       // foreign keys setup handled in _openConnection
     },
   );
   ```
5. Running `dart run build_runner build --delete-conflicting-outputs` will regenerate `database.g.dart` with:
   - `AlarmsCompanion` accepting optional `missionEnabled`, `missionType`, `missionDifficulty`.
   - `Alarm` data class containing `missionEnabled`, `missionType`, `missionDifficulty`.
   - `Alarm.copyWith(...)` accepting the new fields.
6. Because defaults are defined at the schema level (`false`, `'math'`, `'medium'`), all existing tests creating alarms via `AlarmsCompanion.insert(...)` will continue to compile and pass with zero breakage.

### 2.3 Edit Alarm Screen Implementation Logic
1. In `_EditAlarmScreenState`:
   - Add state variables:
     ```dart
     bool _missionEnabled = false;
     String _missionType = 'math';
     String _missionDifficulty = 'medium';
     ```
   - In `initState()`:
     ```dart
     if (widget.existingAlarm != null) {
       _selectedTime = TimeOfDay(hour: widget.existingAlarm!.hour, minute: widget.existingAlarm!.minute);
       _selectedDays = _decodeRepeatDays(widget.existingAlarm!.repeatDays);
       _isVibrate = widget.existingAlarm!.vibrate;
       _label = widget.existingAlarm!.label ?? '';
       _missionEnabled = widget.existingAlarm!.missionEnabled;
       _missionType = widget.existingAlarm!.missionType;
       _missionDifficulty = widget.existingAlarm!.missionDifficulty;
     } else {
       _selectedTime = TimeOfDay.now();
       _selectedDays = List.generate(7, (index) => false);
       _missionEnabled = false;
       _missionType = 'math';
       _missionDifficulty = 'medium';
     }
     ```
   - Replace on-the-fly `TextEditingController` in `build()` with a proper `late final TextEditingController _labelController` created in `initState()` and disposed in `dispose()`.
2. Add dedicated Mission UI card (`_buildMissionCard()`):
   - Switch for `_missionEnabled` ("Nhiệm vụ thức dậy", "Bắt buộc giải đố để tắt chuông").
   - When enabled: show mission type selector ("Giải toán") and difficulty dropdown (`'easy'` -> 'Dễ', `'medium'` -> 'Vừa', `'hard'` -> 'Khó').
3. Fix `_saveAlarm()`:
   ```dart
   Future<void> _saveAlarm() async {
     final repeatDays = _encodeRepeatDays(_selectedDays);
     final labelText = _labelController.text.trim();

     if (widget.existingAlarm == null) {
       final alarmData = AlarmsCompanion.insert(
         hour: _selectedTime.hour,
         minute: _selectedTime.minute,
         repeatDays: drift.Value(repeatDays),
         label: labelText.isEmpty ? const drift.Value.absent() : drift.Value(labelText),
         vibrate: drift.Value(_isVibrate),
         missionEnabled: drift.Value(_missionEnabled),
         missionType: drift.Value(_missionType),
         missionDifficulty: drift.Value(_missionDifficulty),
       );
       await ref.read(alarmRepositoryProvider).addAlarm(alarmData);
     } else {
       final updatedAlarm = widget.existingAlarm!.copyWith(
         hour: _selectedTime.hour,
         minute: _selectedTime.minute,
         repeatDays: repeatDays,
         label: drift.Value(labelText.isEmpty ? null : labelText),
         vibrate: _isVibrate,
         missionEnabled: _missionEnabled,
         missionType: _missionType,
         missionDifficulty: _missionDifficulty,
         skipNextDate: const drift.Value(null), // reset skip when schedule changes
         updatedAt: DateTime.now(),
       );
       await ref.read(alarmRepositoryProvider).updateAlarm(updatedAlarm);
     }
     if (mounted) {
       Navigator.pop(context);
     }
   }
   ```

### 2.4 Ringing Screen Mission Gate Logic
1. When alarm fires, `RingingScreen` receives `widget.alarmId`.
2. Snooze offset caveat: `AlarmRepository.snoozeIdOffset` is `1000000`. If the alarm was triggered from snooze, `widget.alarmId >= 1000000`, so `realId = widget.alarmId >= AlarmRepository.snoozeIdOffset ? widget.alarmId - AlarmRepository.snoozeIdOffset : widget.alarmId`.
3. In `RingingScreen`:
   - Read the alarm from `databaseProvider` via `ref.read(databaseProvider).getAlarm(realId)` (or `_getAlarmOrNull`).
   - Extract `missionEnabled` and `missionDifficulty`.
4. In `_dismissAlarm()`:
   - If `missionEnabled == true`:
     Map `missionDifficulty` string to `MathDifficulty` enum (`easy` -> `MathDifficulty.easy`, `hard` -> `MathDifficulty.hard`, default -> `MathDifficulty.medium`).
     Navigate to `MathMissionScreen(difficulty: difficulty, requiredQuestions: 3)`.
     If result != `true` (user cancelled or mission not completed), do NOT dismiss; let alarm continue ringing.
   - If `missionEnabled == false`:
     Immediately stop ringing via `NativeAlarmService.stopRinging(id: widget.alarmId)`.
     Reschedule next occurrence via `ref.read(alarmRepositoryProvider).rescheduleAfterFire(realId, firedAt: _referenceFiredAt(), action: 'dismissed')`.
     Navigate back to `AppRouter`.
5. In `_snoozeAlarm()`:
   - Ensure snooze uses `realId` so `AlarmRepository.snooze` looks up the real database record rather than `1000000 + id`.

---

## 3. Caveats
1. **Mission Types**: Currently, WakeUp+ only implements math puzzle mission (`MathMissionScreen`). The schema provides `missionType` (default `'math'`) for forward extensibility (e.g. photo/shake/memory in future versions), but only math is active in UI.
2. **Notification Budget on OS**: `scheduleAlarm` in `AlarmRepository._schedule` calculates `chainLength` and `futureCount` using `IosNotificationBudget.plan`. Updating an alarm replaces its OS slot without consuming extra notification budget.
3. **In-Memory Test Database**: Tests using `AppDatabase.forTesting(NativeDatabase.memory())` create the database fresh at `schemaVersion = 2`. To verify `onUpgrade`, an explicit migration test can verify migration from v1 to v2 schema.
4. **Lint Deprecations**: `Switch.activeColor` is deprecated in Flutter 3.31+; replacing with `activeThumbColor` and `activeTrackColor` eliminates warnings. Also, `.withValues(alpha: ...)` should replace `.withOpacity(...)`.

---

## 4. Conclusion
The root cause of the broken alarm update logic is completely located in `lib/features/alarms/presentation/edit_alarm_screen.dart` line 70 (`// TODO: Cập nhật thông qua repository`). The underlying SQLite update method and native alarm cancellation/rescheduling logic are already built and functioning in `AlarmRepository.updateAlarm`.

EPIC 2 (R1) can be resolved completely and cleanly by:
1. Adding `missionEnabled`, `missionType`, and `missionDifficulty` to `lib/data/local/database.dart`, setting `schemaVersion = 2` with Drift `MigrationStrategy`, and executing `dart run build_runner build --delete-conflicting-outputs`.
2. Updating `edit_alarm_screen.dart` to manage mission toggle and difficulty selection, and calling `ref.read(alarmRepositoryProvider).updateAlarm(...)` when `widget.existingAlarm != null`.
3. Updating `ringing_screen.dart` to fetch the alarm record by ID, inspect `missionEnabled`, and allow instant dismiss when `false`, while requiring `MathMissionScreen` when `true`.
4. Adding comprehensive unit tests in `test/data/alarm_repository_reschedule_test.dart` for `updateAlarm` verifying time update, repeat days update, label update, disabling alarm, and mission field persistence.

---

## 5. Verification Method

### 5.1 Verification Commands
1. Run Drift generator:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   *Expected result*: Succeeded with 0 errors, `database.g.dart` updated.
2. Run test suite:
   ```bash
   flutter test
   ```
   *Expected result*: All 49 existing tests pass + new unit tests for `updateAlarm` pass (>= 53 tests total).
3. Run static analysis:
   ```bash
   flutter analyze lib/data/local/ lib/data/repositories/ lib/features/alarms/
   ```
   *Expected result*: 0 errors, 0 warnings in affected files.

### 5.2 Implementation Roadmap for Implementer

#### Step 1: Database Schema & Migration (`lib/data/local/database.dart`)
1. Add columns to `Alarms` table:
   ```dart
   BoolColumn get missionEnabled => boolean().withDefault(const Constant(false))();
   TextColumn get missionType => text().withDefault(const Constant('math'))();
   TextColumn get missionDifficulty => text().withDefault(const Constant('medium'))();
   ```
2. Update `AppDatabase`:
   ```dart
   @override
   int get schemaVersion => 2;

   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) async {
       await m.createAll();
     },
     onUpgrade: (m, from, to) async {
       if (from < 2) {
         await m.addColumn(alarms, alarms.missionEnabled);
         await m.addColumn(alarms, alarms.missionType);
         await m.addColumn(alarms, alarms.missionDifficulty);
       }
     },
   );
   ```
3. Run `dart run build_runner build --delete-conflicting-outputs`.

#### Step 2: Edit Alarm Screen (`lib/features/alarms/presentation/edit_alarm_screen.dart`)
1. Add state variables: `_missionEnabled`, `_missionDifficulty`, `_missionType`, and `_labelController`.
2. Initialize them from `widget.existingAlarm` in `initState()`, dispose `_labelController` in `dispose()`.
3. Add `_buildMissionCard()` containing the switch and difficulty dropdown.
4. Update `_saveAlarm()` to `await ref.read(alarmRepositoryProvider).updateAlarm(...)` using `widget.existingAlarm!.copyWith(...)`.
5. Fix deprecated `Switch.activeColor` and `withOpacity`.

#### Step 3: Ringing Screen (`lib/features/alarms/presentation/ringing_screen.dart`)
1. In `_RingingScreenState`, fetch the `Alarm` record via `ref.read(databaseProvider).getAlarm(realId)` where `realId = widget.alarmId >= AlarmRepository.snoozeIdOffset ? widget.alarmId - AlarmRepository.snoozeIdOffset : widget.alarmId`.
2. In `_dismissAlarm()`:
   - Check `alarm?.missionEnabled ?? false`.
   - If `true`: launch `MathMissionScreen(difficulty: difficulty, requiredQuestions: 3)`. Only proceed if result is `true`.
   - If `false`: bypass `MathMissionScreen` immediately.
   - Stop ringing via `NativeAlarmService.stopRinging(id: widget.alarmId)`.
   - Reschedule via `repo.rescheduleAfterFire(realId, firedAt: _referenceFiredAt(), action: 'dismissed')`.
3. In `_snoozeAlarm()`: use `realId` for `repo.snooze(realId, ...)`.

#### Step 4: Alarm Card Enhancement (`lib/features/alarms/presentation/widgets/alarm_card.dart`)
1. In details row, if `alarm.missionEnabled`, render `_buildDetailItem(Icons.calculate, 'Toán')` to inform the user of an active wake-up mission.
2. Fix `Switch.activeColor` deprecation.

#### Step 5: Unit Tests (`test/data/alarm_repository_reschedule_test.dart`)
1. Add helper parameter in `insertAlarm` for `bool missionEnabled = false`, `String missionDifficulty = 'medium'`.
2. Add new test group `'updateAlarm — Cập nhật báo thức'`:
   - `cập nhật giờ, phút, repeatDays và nhãn thành công trong DB và reschedule native`
   - `cập nhật báo thức chuyển sang tắt (enabled = false) thì hủy lịch và không lập lịch mới`
   - `cập nhật cấu hình nhiệm vụ missionEnabled và missionDifficulty`
3. Remove unused local variable `id2` at line 414 to resolve the static analysis warning.
