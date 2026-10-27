# ⏰ WakeUp+ — Ultra-Reliable Smart Alarm Clock

[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.1-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13.1-0175C2.svg?logo=dart)](https://dart.dev)
[![Tests Status](https://img.shields.io/badge/Tests-128%2F128%20Passed-brightgreen.svg)]()
[![Code Quality](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange.svg)]()
[![Security](https://img.shields.io/badge/Security-SQLCipher%20AES--256-blueviolet.svg)]()
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

> **WakeUp+** là ứng dụng di động (Mobile App) thông minh đa nền tảng dành cho Android và iOS, đặt **độ tin cậy lên hàng đầu (Reliability First)**. Ứng dụng giải quyết triệt để vấn đề báo thức bị hệ điều hành tắt ngầm (Doze mode, Battery Optimization, Task Killer) và giúp người dùng thực sự tỉnh táo bằng các nhiệm vụ trí tuệ.

---

## 📱 Bản Chất Dự Án

- **Loại ứng dụng**: Mobile Application (Ứng dụng di động).
- **Nền tảng mục tiêu**:
  - **Android**: Hỗ trợ từ Android 8.0 (API 26) đến Android 14+ (API 34/35). Tối ưu hóa đặc biệt cho các giao diện OEM khắc nghiệt (Xiaomi HyperOS/MIUI, Samsung One UI, Oppo ColorOS, Vivo FuntouchOS).
  - **iOS**: iOS 16.0 trở lên.
- **Mục tiêu cốt lõi**: Đạt tỉ lệ báo thức đổ chuông đúng giờ **≥ 99.5%** trong mọi tình huống (khóa màn hình, pin yếu, chế độ Không làm phiền DND, khởi động lại máy, hoặc app bị kill ngầm).

---

## ✨ Tính Năng Nổi Bật

### 1. Động cơ Báo thức Tin cậy Tuyệt đối (Wake-up Engine)
- **Lập lịch mức độ cao nhất**: Sử dụng `AlarmManager.setAlarmClock()` trên Android và `UNUserNotificationCenter` có thuật toán phân bổ ngân sách (`NotificationBudget` $\le 60$) trên iOS.
- **Vượt qua chế độ ngủ sâu (Doze Mode)**: Khởi chạy `Foreground Service` kèm thông báo toàn màn hình (`Full-Screen Intent`), giữ âm lượng riêng với thuộc tính `USAGE_ALARM`.
- **Cơ chế Tự lập lịch 3 lớp (3-tier Reschedule)**:
  1. *Native Auto-trigger*: Tầng Kotlin/Swift tự động lập lịch lần kế tiếp ngay khi chuông vừa kích hoạt (không phụ thuộc vào việc Flutter Engine có đang sống hay không).
  2. *Dart Reschedule*: Tầng Dart ghi nhận lịch sử và tái lập lịch khi người dùng tương tác tắt/hoãn chuông.
  3. *App Resume Re-arm*: Tự động kiểm tra và re-arm toàn bộ báo thức đang bật mỗi khi mở lại app.
- **Sống sót qua Reboot máy**: Đăng ký `BroadcastReceiver` bắt `BOOT_COMPLETED`, `LOCKED_BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIMEZONE_CHANGED` kết hợp `AlarmRegistry` lưu trên native SharedPreferences, không phụ thuộc vào trạng thái mở khóa SQLite.
- **Tự động dừng (Auto-Stop) & Ghi nhận bỏ lỡ (Missed Alarms)**: Tự tắt chuông sau thời gian cấu hình (mặc định 10 phút) để tránh cạn pin nếu người dùng để quên máy, đồng thời đồng bộ lịch sử báo lỡ vào CSDL.

### 2. Nhiệm Vụ Đánh Thức Trí Tuệ (Wake-up Missions)
- **Nhiệm vụ Toán học (Math Puzzle)**: Buộc não bộ hoạt động để kích hoạt trạng thái tỉnh táo trước khi cho phép tắt chuông.
- Hỗ trợ 3 mức độ: Dễ (Cộng/Trừ 1 chữ số), Trung bình (Nhân/Chia 2 chữ số), Khó (Biểu thức kết hợp).
- Bắt buộc trả lời đúng số câu hỏi quy định liên tiếp; nếu hủy bỏ hoặc đóng màn hình dở dang, chuông vẫn tiếp tục reo.

### 3. Đồng Hồ Đếm Giờ & Bấm Giờ (Timer & Stopwatch)
- **Timer đếm ngược linh hoạt**: Vòng quay chọn Giờ / Phút / Giây (`CupertinoTimerPicker`) kèm các preset nhanh (+1m, +5m, +10m, +15m).
- Chạy nền độc lập, đếm ngược chính xác, phát âm thanh cảnh báo và rung haptics khi về 0.
- **Stopwatch bấm giờ**: Độ chính xác 1/100 giây, lưu danh sách vòng chạy (Lap times) với hiển thị so sánh độ chênh lệch.

### 4. Âm Thanh Chuông Chất Lượng Cao
- **12 bộ âm thanh native chuẩn WAV**: Bao gồm `alarm_default`, `radar`, `siren`, `bell`, `birds`, `beep`, `arpeggio`, `buzzer`, `chime`, `wakeup`, `digital`, `sunrise`.
- Tối ưu hóa kích thước: Tích hợp trực tiếp vào tầng native (`res/raw` trên Android và `Sounds/` trên iOS) giúp tiết kiệm 2.6 MB dung lượng gói cài đặt, không nhân đôi tài nguyên trong Dart bundle.
- Đã được chuẩn hóa phổ âm thanh (không clipping, đỉnh −0.7 dBFS, loại bỏ DC offset).

### 5. An Ninh & Quyền Riêng Tư (Security & Offline First)
- **Hoàn toàn Offline**: Không yêu cầu tạo tài khoản hay kết nối mạng để sử dụng các tính năng báo thức cốt lõi.
- **Mã hóa CSDL cấp ngân hàng**: Drift ORM tích hợp **SQLCipher (AES-256)**, khóa mã hóa ngẫu nhiên được bảo vệ an toàn trong Android Keystore / iOS Keychain thông qua `flutter_secure_storage`.
- **Không quảng cáo gây phiền nhiễu**: Không banner, không interstitial, không tracking lén lút.

---

## 🏗️ Kiến Trúc Kỹ Thuật (Architecture & Tech Stack)

```
┌─────────────────────────────────────────────────────────────────┐
│               Flutter Presentation & State Layer                │
│       Riverpod (StateNotifier / Providers) • Dark Theme UI      │
├────────────────────────────────┬────────────────────────────────┤
│       Business & Data Core     │       App Infrastructure       │
│  - AlarmRepository             │  - Safe Crashlytics / Analytics│
│  - Drift SQLite (SQLCipher)    │  - RevenueCat Monetization     │
│  - TimeUtils & NotificationCalc│  - Supabase Auth (Optional)    │
├────────────────────────────────┴────────────────────────────────┤
│              Platform Channel (MethodChannel)                   │
├────────────────────────────────┬────────────────────────────────┤
│      Android Native (Kotlin)   │        iOS Native (Swift)      │
│  - AlarmManager.setAlarmClock  │  - UNUserNotificationCenter    │
│  - Foreground AlarmService     │  - NotificationBudget Planner  │
│  - FullScreen RingingActivity  │  - AVAudioSession Playback     │
│  - Boot & Replaced Receivers   │  - Background Audio Category   │
└────────────────────────────────┴────────────────────────────────┘
```

- **Framework**: Flutter 3.47.1 / Dart 3.13.1
- **State Management**: `flutter_riverpod` (^2.5.1)
- **Local Database**: `drift` (^2.14.0) + `sqlcipher_flutter_libs` (Mã hóa AES-256)
- **Native Interop**: MethodChannel `com.wakeup.app/alarm`
- **Audio & Haptics**: `just_audio`, Android `MediaPlayer` / `RingtoneManager`, iOS `AVAudioSession`
- **Monetization**: `purchases_flutter` (RevenueCat) với cơ chế Safe Fallback/Mock Offline
- **Telemetry**: `firebase_crashlytics`, `mixpanel_flutter` với chế độ graceful degradation nếu thiếu API Key

---

## 📁 Cấu Trúc Thư Mục (Project Structure)

```
app_clock/
├── android/                         # Mã nguồn Native Android (Kotlin & Gradle)
│   ├── app/
│   │   ├── src/main/kotlin/com/wakeup/app/
│   │   │   ├── MainActivity.kt      # Xử lý MethodChannel và App Router
│   │   │   ├── AlarmService.kt      # Foreground Service phát chuông & WakeLock
│   │   │   ├── AlarmReceiver.kt     # Bắt Boot, Timezone, Package Replaced
│   │   │   └── AlarmRegistry.kt     # Lưu trữ lịch độc lập với DB mã hóa
│   │   ├── src/main/res/raw/        # 12 file âm thanh WAV chất lượng cao
│   │   ├── proguard-rules.pro       # Quy tắc R8 giữ an toàn cho Audio & Reflection
│   │   └── build.gradle.kts         # Cấu hình Signing Release, R8, NDK 28.2
├── ios/                             # Mã nguồn Native iOS (Swift & Xcode)
│   ├── Runner/
│   │   ├── AlarmScheduler.swift     # Lập lịch chuỗi thông báo
│   │   ├── AlarmAudioPlayer.swift   # Audio foreground lặp qua AVAudioSession
│   │   ├── AlarmPlugin.swift        # MethodChannel & Notification Delegate
│   │   └── Sounds/                  # 12 file âm thanh WAV đăng ký trong Bundle
├── lib/                             # Mã nguồn chính Flutter (Dart)
│   ├── core/                        # Theme, Router, Tiện ích thời gian, Services
│   │   ├── app_router.dart          # Điều hướng Onboarding -> Login -> Dashboard
│   │   ├── theme.dart               # Hệ thống Dark Theme chuẩn tương phản
│   │   └── services/                # AnalyticsService, FirebaseOptions, EncryptionKey
│   ├── data/                        # Tầng dữ liệu & Kho lưu trữ
│   │   ├── local/                   # Drift Database (Schema v2), NativeAlarmService
│   │   └── repositories/            # AlarmRepository (CRUD, Reschedule, Snooze)
│   ├── features/                    # Các module tính năng (Feature-first)
│   │   ├── alarms/                  # Dashboard, Edit, Ringing, Math Mission
│   │   ├── timer/                   # Timer đếm ngược & Stopwatch bấm giờ
│   │   ├── home/                    # MainNavigationScreen (2 Tab tinh gọn)
│   │   ├── onboarding/              # Giới thiệu & Xin quyền (chống tràn layout)
│   │   ├── monetization/            # PaywallScreen (Gói Pro/Ultra)
│   │   └── auth/                    # Đăng nhập Supabase (Tùy chọn)
│   └── main.dart                    # Điểm khởi chạy app, cấu hình bắt lỗi toàn cục
├── test/                            # Bộ kiểm thử tự động (128 Unit & Widget Tests)
├── store/                           # Tài nguyên ASO, Ảnh chụp màn hình Store, Icon
│   ├── google-play/                 # Screenshots, Icon 512, Feature Graphic 1024x500
│   ├── app-store/                   # Screenshots 6.7", 6.9", iPad 13", AppIcon 1024
│   ├── ASO_METADATA.md              # Nội dung mô tả chuẩn SEO song ngữ (VI / EN)
│   └── SCREENSHOT_PLAN.md           # Kịch bản ảnh chụp cửa hàng ứng dụng
├── legal/                           # Tài liệu Pháp lý phục vụ xét duyệt Store
│   ├── PRIVACY_POLICY.md            # Chính sách quyền riêng tư đối chiếu mã nguồn
│   ├── TERMS_OF_SERVICE.md          # Điều khoản sử dụng dịch vụ
│   └── README.md                    # Hướng dẫn khai báo Data Safety Play Console
├── tools/                           # Scripts Python sinh âm thanh & hỗ trợ build
│   ├── generate_alarm_sounds.py     # Bộ tạo 12 file WAV chuẩn kỹ thuật bằng Python
│   └── register_ios_sounds.py       # Tự động map sound files vào project.pbxproj
├── plan.md                          # Kế hoạch chi tiết và tiến độ thực tế
├── confirm.md                       # Biên bản kiểm chứng kỹ thuật & các lỗi đã sửa
└── pubspec.yaml                     # Danh sách dependencies & cấu hình tài nguyên
```

---

## 🚀 Hướng Dẫn Cài Đặt & Phát Triển Cục Bộ

### 1. Yêu cầu hệ thống
- **Flutter SDK**: `>= 3.2.0 < 4.0.0` (Khuyến nghị Flutter 3.24+ hoặc 3.47+)
- **Dart SDK**: `>= 3.13.0`
- **Java Development Kit (JDK)**: JDK 17
- **Android SDK & NDK**: NDK phiên bản `28.2.13676358`
- **Xcode** (nếu build iOS): Xcode 15+ trên macOS

### 2. Cài đặt dependencies & Sinh mã nguồn
```bash
# Clone repo
git clone <repo-url>
cd app_clock

# Tải dependencies
flutter pub get

# Sinh mã nguồn Drift ORM (Database schema & providers)
dart run build_runner build --delete-conflicting-outputs
```

### 3. Chạy ứng dụng (Debug Mode)
```bash
# Chạy thông thường
flutter run

# Chạy với cờ bỏ qua màn hình đăng nhập (tiện cho việc test UI và chụp màn hình)
flutter run --dart-define=SKIP_LOGIN_FOR_SCREENSHOTS=true
```

---

## 🧪 Kiểm Thử & Đảm Bảo Chất Lượng (Quality Gate)

Dự án tuân thủ tiêu chuẩn chất lượng nghiêm ngặt trước khi release:

### 1. Kiểm tra tĩnh (Static Analysis)
```bash
flutter analyze
```
*Kết quả hiện tại*: **0 errors, 0 warnings, 0 issues** trên toàn bộ `lib/` và `test/`.

### 2. Chạy toàn bộ Unit & Widget Tests
```bash
flutter test
```
*Kết quả hiện tại*: **128/128 tests pass (100%)**, bao gồm:
- Kiểm thử thuật toán `NotificationBudget` cho iOS (đảm bảo không vượt ngưỡng 60 notifications).
- Kiểm thử logic reschedule 3 lớp sau khi chuông reo (hàng ngày, ngày tùy chọn, múi giờ, snooze).
- Kiểm thử bảo mật SQLCipher & fallback khi cơ sở dữ liệu mã hóa chưa sẵn sàng.
- Kiểm thử state machine bộ đếm giờ (Timer) & chống memory leak khi chuyển tab nhanh.
- Widget tests cho giao diện Onboarding chống tràn màn hình (RenderFlex Overflow fix).

---

## 📦 Hướng Dẫn Đóng Gói Bản Release (Android)

### 1. Cấu hình Signing Key
File cấu hình `android/key.properties` đã được định cấu hình tham chiếu tới `android/app/wakeup-release.jks` (Key RSA 4096-bit, PKCS12, thời hạn tới năm 2054).

> ⚠️ **Bảo Mật Quan Trọng**: File `key.properties` và file `*.jks` đã được đưa vào `.gitignore`. Cần sao lưu 2 file này ở ít nhất **2 nơi an toàn độc lập**. Nếu mất khóa ký, bạn sẽ không thể cập nhật ứng dụng trên Google Play.

### 2. Build Android App Bundle (AAB) cho Google Play
```bash
flutter build appbundle --release
```
- Đầu ra: `build/app/outputs/bundle/release/app-release.aab`
- Kích thước: ~64.2 MB.
- Đã bật tối ưu mã nguồn: `isMinifyEnabled = true`, `isShrinkResources = true` (R8 đã được cấu hình ProGuard bảo toàn 12 file chuông `R.raw.*`).

### 3. Build APK Release cài trực tiếp kiểm thử
```bash
flutter build apk --release
```
- Đầu ra: `build/app/outputs/flutter-apk/app-release.apk`
- Kích thước: ~63.5 MB.

### 4. Biến môi trường lúc biên dịch (`--dart-define`)
Khi build cho môi trường Production, truyền các biến môi trường sau:
```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_API_KEY="your_revenuecat_key" \
  --dart-define=MIXPANEL_TOKEN="your_mixpanel_token" \
  --dart-define=FIREBASE_API_KEY="your_firebase_key"
```
*(Nếu không truyền, ứng dụng tự động kích hoạt chế độ an toàn Offline/Mock/No-op, không bao giờ gây crash app).*

---

## 🚦 Đánh Giá Mức Độ Sẵn Sàng Go-Live (Go-Live Readiness)

| Nền tảng | Trạng thái kỹ thuật | Mức độ sẵn sàng | Khuyến nghị hành động |
|:---|:---:|:---:|:---|
| **Android** | **~90% Hoàn thiện** | 🟡 **Gần sẵn sàng (Cần 3–5 ngày)** | Hoàn tất checklist P0 bên dưới trước khi submit Google Play Console |
| **iOS** | **Scaffold xong Swift** | 🔴 **Chưa sẵn sàng** | Cần môi trường macOS/Xcode để compile, test thật và xin Apple Critical Alerts |

### Checklist Bắt Buộc Trước Khi Bấm Nút Phát Hành Android:
- [ ] **Đăng Privacy Policy & Terms of Service lên URL công khai**: Copy nội dung từ `legal/PRIVACY_POLICY.md` và `legal/TERMS_OF_SERVICE.md` lên GitHub Pages hoặc website riêng, sau đó dán link vào mục Privacy Policy của Google Play Console.
- [ ] **Khai báo Google Play Data Safety**: Điền biểu mẫu dữ liệu theo bảng hướng dẫn chi tiết tại `legal/README.md`.
- [ ] **Cấu hình Firebase Crashlytics thật**: Chạy `flutterfire configure` để sinh file `google-services.json` thật, đảm bảo nhận được crash logs khi có người dùng gặp sự cố.
- [ ] **Kiểm thử thực tế trên các hãng máy Android (OEM Matrix)**:
  - Xiaomi/POCO (MIUI / HyperOS): Test tắt tối ưu pin và tự khởi chạy (Autostart).
  - Samsung (One UI): Test trường hợp app rơi vào Deep Sleeping Apps.
  - Oppo / Realme (ColorOS): Test chuông reo khi khóa màn hình qua đêm.
- [ ] **Sao lưu Keystore Release**: Lưu trữ `wakeup-release.jks` và mật khẩu vào nơi an toàn (Google Drive bảo mật, Bitwarden, ổ cứng rời).
- [ ] **Kiểm tra đồ họa Store**: Upload ảnh chụp màn hình trong `store/google-play/phone/`, Icon 512x512 trong `store/google-play/icon/` và Feature Graphic trong `store/google-play/feature-graphic/`.

---

## ⚖️ Pháp Lý & Bản Quyền

- Bản quyền © 2026 WakeUp+ Team. Bảo lưu mọi quyền.
- Tài liệu pháp lý:
  - [Chính sách Quyền riêng tư (Privacy Policy)](file:///legal/PRIVACY_POLICY.md)
  - [Điều khoản Dịch vụ (Terms of Service)](file:///legal/TERMS_OF_SERVICE.md)
  - [Hướng dẫn khai báo Store Compliance](file:///legal/README.md)
