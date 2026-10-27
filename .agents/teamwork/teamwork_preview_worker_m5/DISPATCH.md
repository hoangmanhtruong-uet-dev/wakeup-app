# DISPATCH — Worker M5: App Icon & Store Assets Packaging (EPIC 6 / R5)

## Mission
Implement Milestone 5: Configure and execute `flutter_launcher_icons` to replace stock Flutter icons on Android (mipmap-*) and iOS (AppIcon.appiconset) with the official WakeUp+ app icon, and populate all required Store asset directories under `store/`.

## References & Inputs
- Original Request: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md` § R5
- Project Master Plan: `d:/MyProjects/Medium-project/app/app_clock/PROJECT.md`
- Survey Explorer 3 Report: `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_explorer_survey_3/handoff.md`

## File Ownership
You have exclusive write access to:
- `pubspec.yaml`
- `assets/images/app_icon.png`
- `android/app/src/main/res/` (generated mipmap-* icons)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (generated app icons)
- `store/` (store asset directories)
- `tools/` (helper generation scripts)
Do NOT modify files outside of this boundary.

## Instructions
1. In `pubspec.yaml`:
   - Under `dev_dependencies:` add:
     `flutter_launcher_icons: ^0.13.1`
   - Add configuration block:
     ```yaml
     flutter_launcher_icons:
       android: true
       ios: true
       image_path: "assets/images/app_icon.png"
       min_sdk_android: 21
       adaptive_icon_background: "#0E111A"
       adaptive_icon_foreground: "assets/images/app_icon.png"
     ```
   - Run `flutter pub get`.
2. Generate Master App Icon:
   - Create `tools/generate_icon.py` using Python Pillow to generate a premium 1024x1024 PNG `assets/images/app_icon.png`:
     - Deep background `#0E111A`
     - Glowing alarm clock & morning sun motif in WakeUp+ colors: `#FFC18F` (Warm Sun) and `#38EBD6` (Neon Mint).
   - Run the script to produce `assets/images/app_icon.png`.
3. Run `flutter_launcher_icons`:
   - Execute:
     ```powershell
     dart run flutter_launcher_icons
     ```
   - Verify Android mipmaps (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and iOS `AppIcon.appiconset` are updated.
4. Prepare Store Assets (`store/`):
   - Create `tools/generate_store_assets.py` using Python Pillow to generate and place assets in required directories:
     - `store/google-play/icon/ic_launcher-512.png` (512x512, RGB no alpha)
     - `store/google-play/feature-graphic/feature_graphic.png` (1024x500, banner with WakeUp+ logo & tagline)
     - `store/app-store/app-icon/AppIcon-1024.png` (1024x1024, RGB no alpha)
     - Format and copy existing raw screenshots from `store/google-play/phone/` into:
       - `store/google-play/tablet-7in/`
       - `store/google-play/tablet-10in/`
       - `store/app-store/iphone-6.9in/` (1320x2868)
       - `store/app-store/iphone-6.7in/` (1290x2796)
       - `store/app-store/ipad-13in/` (2064x2752)
5. Quality Checks:
   - Run `flutter analyze` (must be `No issues found!`).
   - Run `flutter test` (must pass 100%, all 128 tests).

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Completion Deliverable
Write your report to `d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m5/handoff.md` and call send_message when finished.

## 2026-10-18T20:40:28Z
You are Worker M5 for WakeUp+ app core feature completion.
Your working directory is: d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m5
Read d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/ORIGINAL_REQUEST.md, d:/MyProjects/Medium-project/app/app_clock/PROJECT.md, and d:/MyProjects/Medium-project/app/app_clock/.agents/teamwork/teamwork_preview_worker_m5/DISPATCH.md before starting.

Scope: Milestone 5 (App Icon & Store Assets - EPIC 6 / R5)
Implement the changes specified in DISPATCH.md across your owned files:
- Add flutter_launcher_icons: ^0.13.1 to dev_dependencies and configure in pubspec.yaml
- Generate premium master 1024x1024 app icon at assets/images/app_icon.png with WakeUp+ dark brand palette
- Run `dart run flutter_launcher_icons` to generate official Android mipmap-* and iOS AppIconset icons, replacing default Flutter logos
- Populate store asset directories: Google Play 512x512 icon, 1024x500 feature graphic, App Store 1024x1024 icon, and formatted store screenshots for iPhone and iPad
- Verify `flutter analyze` has 0 issues and `flutter test` passes 100%

