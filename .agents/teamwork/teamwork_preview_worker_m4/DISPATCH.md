# DISPATCH — Worker M4: Infrastructure & Codebase-wide Zero-Lint (EPIC 5 / R4)

## Mission
Implement Milestone 4: Safe Firebase Crashlytics & Mixpanel setup with `--dart-define` / no-op fallback (zero hardcoded dummy tokens in active initialization), eliminate all deprecated Flutter APIs and print calls across the entire codebase, and bring `flutter analyze` to exactly 0 warnings / 0 issues (`No issues found!`).

## References & Inputs
- Original Request: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md` § R4
- Project Master Plan: `d:/MyProjects/Medium-project/app/app_clock/PROJECT.md`
- Survey Explorer 3 Report: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_3/handoff.md` (Contains exact file paths and line numbers of all analyze issues)

## File Ownership
You have write access across files requiring lint cleanup and infrastructure hardening:
- `lib/core/services/analytics_service.dart`
- `lib/core/services/firebase_options.dart`
- `lib/main.dart`
- `lib/core/network/api_client.dart`
- `lib/core/services/biometric_auth_service.dart`
- `lib/core/services/cloud_sync_service.dart`
- `lib/core/services/widget_service.dart`
- `lib/core/services/encryption_key_service.dart`
- `lib/core/utils/notification_budget.dart`
- `lib/data/local/native_alarm_service.dart`
- `lib/features/alarms/presentation/alarm_dashboard_screen.dart`
- `lib/features/alarms/presentation/missions/math_mission_screen.dart`
- `lib/features/onboarding/onboarding_screen.dart`
- `lib/features/onboarding/presentation/system_permission_guide_screen.dart`
- `lib/features/sleep/presentation/sleep_soundscape_screen.dart`
- `test/core/services/analytics_service_test.dart` (new test)

## Instructions
1. Mixpanel Infrastructure (`lib/core/services/analytics_service.dart`):
   - Check `String.fromEnvironment('MIXPANEL_TOKEN')`.
   - If empty or `'YOUR_MIXPANEL_TOKEN'`, set `_isInitialized = false; debugPrint('[Analytics] MIXPANEL_TOKEN chưa được cấu hình. Chạy ở chế độ no-op an toàn.'); return;`.
   - In all tracking methods (`trackEvent`, `identifyUser`, etc.), verify `if (!_isInitialized) return;`.
   - Replace all `print(...)` with `debugPrint(...)`.
2. Firebase Crashlytics Infrastructure (`lib/core/services/firebase_options.dart` & `lib/main.dart`):
   - In `firebase_options.dart`: add boolean helper `static bool get isConfigured => const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty;`.
   - In `_initCrashReporting()` in `lib/main.dart`: if `!DefaultFirebaseOptions.isConfigured`, log `debugPrint('[Crashlytics] FIREBASE_API_KEY chưa được cấu hình. Bỏ qua Crashlytics, sử dụng error handler cục bộ an toàn.'); return false;`.
   - Replace all remaining `print(...)` with `debugPrint(...)` in `lib/main.dart`.
3. Codebase-wide Lint & Deprecation Cleanup:
   - Run `flutter analyze` to inspect the full list of remaining issues.
   - Replace all `.withOpacity(...)` calls with `.withValues(alpha: ...)`.
   - Replace all `print(...)` calls with `debugPrint(...)` in `api_client.dart`, `biometric_auth_service.dart`, `cloud_sync_service.dart`, `widget_service.dart`, `native_alarm_service.dart`.
   - Add missing `const` constructors and declarations in `encryption_key_service.dart`, `notification_budget.dart`, and `alarm_dashboard_screen.dart`.
   - Re-run `flutter analyze` until it outputs: `No issues found!`.
4. Unit Testing:
   - Create `test/core/services/analytics_service_test.dart` verifying that `AnalyticsService.init()`, `trackEvent()`, `identifyUser()`, and `reset()` execute cleanly without throwing when unconfigured.
   - Run `flutter test` to ensure 100% of the entire test suite passes (all 120+ tests).

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Completion Deliverable
Write your report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m4/handoff.md` and call send_message when finished.


## 2026-10-18T20:31:38Z
You are Worker M4 for WakeUp+ app core feature completion.
Your working directory is: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m4
Read d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md, d:/MyProjects/Medium-project/app/app_clock/PROJECT.md, and d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m4/DISPATCH.md before starting.

Scope: Milestone 4 (Infrastructure & Zero-Lint - EPIC 5 / R4)
Implement the changes specified in DISPATCH.md across your owned files:
- Mixpanel: configure analytics_service.dart with --dart-define and safe no-op fallback
- Firebase Crashlytics: configure firebase_options.dart and main.dart with --dart-define and safe fallback
- Codebase-wide lint cleanup: fix all remaining withOpacity, print, const issues across all files cataloged in DISPATCH.md and Survey Explorer 3 report
- Run `flutter analyze` until it returns exactly: `No issues found!` (0 errors, 0 warnings, 0 infos)
- Add test in test/core/services/analytics_service_test.dart and verify all tests pass 100% with `flutter test`

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Write your completion report to d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m4/handoff.md and call send_message when finished.
