# DISPATCH — Worker M3: Monetization & Legal Compliance (EPIC 4 / R3)

## Mission
Implement Milestone 3: Safe RevenueCat SDK initialization in `main.dart`, handle Upgrade and Restore buttons in `PaywallScreen` with comprehensive exception handling (zero unhandled exceptions / zero crashes), add clickable links to Privacy Policy and EULA in `PaywallScreen` using `url_launcher`, and add widget tests.

## References & Inputs
- Original Request: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md` § R3
- Project Master Plan: `d:/MyProjects/Medium-project/app/app_clock/PROJECT.md`
- Survey Explorer 3 Report: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_3/handoff.md`

## File Ownership
You have exclusive write access to:
- `pubspec.yaml`
- `lib/main.dart`
- `lib/features/monetization/presentation/paywall_screen.dart`
- `test/features/monetization/paywall_screen_test.dart`
Do NOT modify files outside of this boundary.

## Instructions
1. In `pubspec.yaml`:
   - Under `dependencies:`, add `url_launcher: ^6.3.0`.
   - Run `flutter pub get`.
2. In `lib/main.dart`:
   - Import `package:purchases_flutter/purchases_flutter.dart`.
   - Add safe initialization method `_initRevenueCat()`:
     ```dart
     Future<void> _initRevenueCat() async {
       try {
         const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');
         if (apiKey.isEmpty) {
           debugPrint('[RevenueCat] REVENUECAT_API_KEY chưa được cấu hình. Chạy ở chế độ offline/mock an toàn.');
           return;
         }
         await Purchases.configure(PurchasesConfiguration(apiKey));
         debugPrint('[RevenueCat] Khởi tạo thành công.');
       } catch (e) {
         debugPrint('[RevenueCat] Khởi tạo thất bại: $e');
       }
     }
     ```
   - Invoke `await _initRevenueCat().timeout(const Duration(seconds: 5));` in `main()` inside a try-catch so unconfigured RevenueCat never halts app startup.
   - Replace any `print()` with `debugPrint()` and replace `anonKey` with `publishableKey` if touching Supabase config.
3. In `lib/features/monetization/presentation/paywall_screen.dart`:
   - Replace TODO in "Nâng Cấp Ngay" (Upgrade) button with genuine RevenueCat call:
     - Wrap in `try { ... } on PlatformException catch (e) { ... } catch (e) { ... }`.
     - Fetch offerings or purchase package. If unconfigured or offline, show a helpful SnackBar (e.g. "Dịch vụ mua hàng tạm thời không khả dụng hoặc đang ở chế độ thử nghiệm.") instead of crashing.
   - Update "Khôi phục giao dịch (Restore)" button:
     - Call `Purchases.restorePurchases()`.
     - Inspect `customerInfo.entitlements.active`.
     - Provide clear SnackBar feedback to user (e.g. "Đã khôi phục thành công" or "Không tìm thấy giao dịch nào trước đó").
     - Handle `PlatformException` and generic `catch` with graceful SnackBar.
   - Always check `if (!mounted) return;` before calling `ScaffoldMessenger.of(context)`.
   - Add Privacy Policy and Terms of Use (EULA) links at the bottom of the paywall:
     - Use `url_launcher` with `launchUrl(Uri.parse(...), mode: LaunchMode.externalApplication)`.
     - E.g. Privacy Policy URL: `https://wakeup.app/privacy` or GitHub legal path.
     - E.g. EULA URL: `https://wakeup.app/terms` or Apple standard EULA.
     - Wrap launch in try-catch so it never crashes if external browser is missing.
   - Replace deprecated `.withOpacity(...)` with `.withValues(alpha: ...)`.
4. In `test/features/monetization/paywall_screen_test.dart`:
   - Create widget tests verifying:
     - Paywall screen renders all package options, CTA buttons, and Legal links.
     - Tapping Upgrade button when RevenueCat is unconfigured displays safe feedback and DOES NOT crash.
     - Tapping Restore button when RevenueCat is unconfigured displays safe feedback and DOES NOT crash.
     - Privacy Policy and EULA links are present and render correctly.
5. Verification:
   - Run `flutter analyze` on modified files (0 errors, 0 warnings).
   - Run `flutter test` (all 111 existing tests + new paywall tests must pass 100%).

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Completion Deliverable
Write your report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m3/handoff.md` and call send_message when done.


## 2026-10-18T20:20:24Z
You are Worker M3 for WakeUp+ app core feature completion.
Your working directory is: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m3
Read d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md, d:/MyProjects/Medium-project/app/app_clock/PROJECT.md, and d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m3/DISPATCH.md before starting.

Scope: Milestone 3 (Monetization & Legal Compliance - EPIC 4 / R3)
Implement the changes specified in DISPATCH.md across your owned files:
- pubspec.yaml (add url_launcher: ^6.3.0)
- lib/main.dart (safe RevenueCat initialization with --dart-define and try-catch/timeout)
- lib/features/monetization/presentation/paywall_screen.dart (wire Upgrade & Restore buttons with comprehensive exception handling so app never crashes, add clickable Privacy Policy and EULA links via url_launcher, fix .withOpacity deprecations)
- test/features/monetization/paywall_screen_test.dart (test paywall rendering, safe unconfigured Upgrade & Restore handling, and legal links)
