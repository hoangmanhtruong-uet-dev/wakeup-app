# Handoff Report: Challenger 2 — Milestone 1 (EPIC 2) Empirical Verification

**Agent**: Challenger 2 (`teamwork_preview_challenger_m1_2`)  
**Role**: Empirical Challenger (critic, specialist)  
**Milestone**: Milestone 1 (EPIC 2 — Wake-up Mission Gate & Ringing Screen Logic)  
**Final Verdict**: **APPROVE**

---

## 1. Observation

### 1.1 Source Code Verification in `lib/features/alarms/presentation/ringing_screen.dart`
- **Snooze ID Offset Decoding** (lines 47–49):
  ```dart
  int get _realId => widget.alarmId >= AlarmRepository.snoozeIdOffset
      ? widget.alarmId - AlarmRepository.snoozeIdOffset
      : widget.alarmId;
  ```
  `AlarmRepository.snoozeIdOffset` is defined in `lib/data/repositories/alarm_repository.dart:265` as `static const int snoozeIdOffset = 1000000;`.
- **Database Query with Real ID** (lines 74–85, 126–132):
  - In `_loadAlarm()`: fetches `ref.read(databaseProvider).getAlarm(_realId)`.
  - In `_dismissAlarm()`: if `_cachedAlarm == null`, falls back to `await ref.read(databaseProvider).getAlarm(realId)`.
- **Conditional Mission Gate & Difficulty Mapping** (lines 134–159):
  ```dart
  final missionEnabled = alarm?.missionEnabled ?? false;

  if (missionEnabled) {
    MathDifficulty difficulty = MathDifficulty.medium;
    if (alarm?.missionDifficulty == 'easy') {
      difficulty = MathDifficulty.easy;
    } else if (alarm?.missionDifficulty == 'hard') {
      difficulty = MathDifficulty.hard;
    }

    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MathMissionScreen(
          difficulty: difficulty,
          requiredQuestions: 3,
        ),
      ),
    );

    // Nếu không hoàn thành nhiệm vụ, không tắt chuông
    if (success != true) {
      return;
    }
  }
  ```
- **Stop Native Ringing & Reschedule** (lines 161–170):
  - `await NativeAlarmService.stopRinging(id: widget.alarmId);`
  - `await repo.rescheduleAfterFire(realId, firedAt: _referenceFiredAt(), action: 'dismissed');`
- **Snooze Action** (lines 93–102):
  - `await NativeAlarmService.stopRinging(id: widget.alarmId);`
  - `await repo.snooze(realId, firedAt: _referenceFiredAt());`

### 1.2 Test Execution Results
1. Created empirical test harness `test/features/alarms/presentation/ringing_screen_test.dart` (12 test cases).
2. Executed `flutter test test/features/alarms/presentation/ringing_screen_test.dart`:
   ```
   00:01 +12: All tests passed!
   ```
3. Executed full project test suite `flutter test`:
   ```
   00:02 +77: All tests passed!
   ```
   (77 tests passed, 0 failures, 0 skipped).
4. Executed `flutter analyze lib/features/alarms/presentation/ringing_screen.dart test/features/alarms/presentation/ringing_screen_test.dart`:
   ```
   Analyzing 2 items...
   No issues found! (ran in 1.4s)
   ```

---

## 2. Logic Chain

1. **Non-Mission Alarms (`missionEnabled == false`)**:
   - *Observation*: Line 134 evaluates `alarm?.missionEnabled ?? false`. If `false`, the `if (missionEnabled)` branch is completely skipped.
   - *Empirical Test*: In `testWidgets('Tắt chuông ngay lập tức không yêu cầu MathMissionScreen')`, sliding to dismiss immediately triggers `NativeAlarmService.stopRinging(id: id)` and records a `dismissed` event in `AlarmEvents` without pushing `MathMissionScreen`.
   - *Inference*: Non-mission alarms dismiss immediately with 0 puzzle friction.

2. **Mission Alarms (`missionEnabled == true`)**:
   - *Observation*: Lines 136–159 push `MathMissionScreen(difficulty: difficulty, requiredQuestions: 3)`. If `success != true`, the method returns immediately.
   - *Empirical Test*:
     - In `testWidgets('Bắt buộc mở MathMissionScreen khi missionEnabled == true')`, dragging the slider mounts `MathMissionScreen` with `MathDifficulty.easy` matching SQLite configuration. While on `MathMissionScreen`, `stopRinging` is NOT called and no history event is written.
     - In `testWidgets('Hủy bỏ hoặc thoát MathMissionScreen không tắt chuông')`, popping with `false` returns to `RingingScreen`, preserves ringing, and does NOT reschedule.
     - In `testWidgets('Hoàn thành MathMissionScreen tắt chuông và reschedule thành công')`, popping with `true` invokes `NativeAlarmService.stopRinging(id: id)` and records `dismissed` event.
   - *Inference*: Mission alarms strictly gate alarm dismissal.

3. **Snooze ID Offset Decoding (`alarmId >= 1000000`)**:
   - *Observation*: Lines 47–49 compute `_realId = widget.alarmId - 1000000`.
   - *Empirical Test*:
     - In `testWidgets('Giải mã snooze ID offset (alarmId >= 1000000) cho báo thức không mission')`: for `alarmId = 1000000 + realId`, it looks up `realId` in DB, bypasses mission, calls `stopRinging(id: 1000000 + realId)` (stopping the snoozed notification), and calls `rescheduleAfterFire(realId)`.
     - In `testWidgets('Giải mã snooze ID offset (alarmId >= 1000000) cho báo thức có mission')`: correctly loads `realId`'s mission difficulty (`hard`), requires `MathMissionScreen`, and reschedules `realId`.
     - In `testWidgets('Nút BÁO LẠI (SNOOZE) dừng notification snoozedId và snooze cho realId')`: calls `stopRinging(id: 1000000 + realId)` and `repo.snooze(realId)`.
   - *Inference*: Snooze offset decoding is completely verified for both DB lookup and platform channel dispatch.

4. **Edge Cases**:
   - When an alarm is deleted from DB while ringing (or an invalid ID is passed), `_dismissAlarm()` defaults `missionEnabled` to `false`, stops ringing, and reschedules without crash.
   - Short drags (< 90% slider width) snap back and do not trigger dismissal.

---

## 3. Adversarial Review & Challenge Report

### 3.1 Challenge Summary
**Overall Risk Assessment**: LOW (Functional logic is solid; one non-blocking layout caveat identified for small screens).

### 3.2 Challenges

#### Challenge 1 [Low] — MathMissionScreen Layout Overflow on Compact Viewports
- **Assumption Challenged**: `MathMissionScreen` layout fits all mobile screens.
- **Attack Scenario**: Render `MathMissionScreen` on a viewport with height <= 800 logical pixels (e.g. iPhone SE 375x667, compact Androids, or landscape mode).
- **Observed Behavior**: Flutter throws `RenderFlex overflowed by 50 pixels on the bottom` (at height 800) and `RenderFlex overflowed by 80 pixels` (at height 600) due to fixed heights in the numpad (`4 * 80px + gaps`) and headers inside an unconstrained `Column`.
- **Blast Radius**: Cosmetic layout warning on small/compact screens. Does not crash release builds, but yellow/black overflow banner appears in debug mode.
- **Mitigation Recommendation**: In Milestone 4/5 (polish phase), wrap the body of `MathMissionScreen` with `SingleChildScrollView` or use `Expanded`/flexible key sizing for the numpad.

#### Challenge 2 [Low] — Slider Threshold on Extra-Wide Displays
- **Assumption Challenged**: `maxWidth = MediaQuery.of(context).size.width - 80 - 60` assumes a phone screen width.
- **Attack Scenario**: Running on a tablet or landscape monitor (e.g. width = 1200px).
- **Observed Behavior**: User must slide > 950px horizontally to dismiss.
- **Mitigation**: Constrain the slider container with a `maxWidth: 400` constraint.

### 3.3 Stress Test Results
| Scenario | Expected Behavior | Actual Behavior | Pass/Fail |
|---|---|---|---|
| Ringing mount | Calls `startRinging` with autoStopMinutes | `startCalls.length == 1`, `autoStopMinutes == 10` | **PASS** |
| Non-mission alarm dismiss | Direct dismiss, no MathMissionScreen | `MathMissionScreen` findsNothing, `stopRinging` called | **PASS** |
| Mission alarm dismiss | Requires MathMissionScreen | `MathMissionScreen` findsOneWidget with matching difficulty | **PASS** |
| Cancel/Abort mission | Ringing preserved, dismiss aborted | `stopRinging` empty, `history` empty | **PASS** |
| Complete mission | Native stop & reschedule | `stopRinging(id)` called, `history` recorded | **PASS** |
| Snooze offset non-mission | Decodes realId, dismisses without mission | Notification cancelled with offset ID, DB updated with real ID | **PASS** |
| Snooze offset mission | Decodes realId, requires MathMissionScreen | Opens puzzle with realId's difficulty, reschedules realId | **PASS** |
| Snooze button tap | Stops offset ID, reschedules realId | Sched calls dispatched, history `action: 'snoozed'` | **PASS** |
| Missing DB alarm | Safe fallback without mission | Dismisses safely without crashing | **PASS** |
| Short drag (<90%) | No dismiss | Slider snaps back, 0 calls | **PASS** |
| Numeric boundaries | 0, 1, 999999, 1000000, 1000001, 2000000 | Decodes to 0, 1, 999999, 0, 1, 1000000 | **PASS** |
| Unknown difficulty string | Safe fallback to medium | Returns `MathDifficulty.medium` | **PASS** |

### 3.4 Unchallenged Areas
- Other mission types (shake, QR code): None implemented yet (by specification, math mission is the only MVP mission).

---

## 4. Caveats

1. `MathMissionScreen` uses deprecated `withOpacity(0.2)` on lines 133 and 221; this is slated for cleanup in Milestone 4 (Zero-Lint milestone) and does not affect runtime correctness.
2. Compact device layout overflow in `MathMissionScreen` should be resolved during UI polish.

---

## 5. Conclusion

The implementation of `ringing_screen.dart` satisfies all requirements of Milestone 1 (EPIC 2):
1. Non-mission alarms dismiss immediately without asking math questions.
2. Mission alarms strictly require solving `MathMissionScreen` and abort dismissal if cancelled or incomplete.
3. The snooze offset (`1000000`) is correctly decoded when fetching from SQLite, snoozing, and rescheduling, while preserving the full active notification ID for native cancellation.
4. All 77 tests in the project pass with 0 failures.

Empirical Verdict: **APPROVE**.

---

## 6. Verification Method

To independently reproduce and verify this report:

1. **Verify RingingScreen Test Suite**:
   ```powershell
   flutter test test/features/alarms/presentation/ringing_screen_test.dart
   ```
   *Expected Output*: `All tests passed!` (12 passed).

2. **Verify Full Project Test Suite**:
   ```powershell
   flutter test
   ```
   *Expected Output*: `00:02 +77: All tests passed!`.

3. **Verify Static Analysis on Owned Ringing Files**:
   ```powershell
   flutter analyze lib/features/alarms/presentation/ringing_screen.dart test/features/alarms/presentation/ringing_screen_test.dart
   ```
   *Expected Output*: `No issues found!`.
