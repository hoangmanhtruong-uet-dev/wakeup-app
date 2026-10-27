# XÁC NHẬN TIẾN ĐỘ — WakeUp+

Ngày cập nhật: 2026-10-18
Phạm vi: từ lần audit đầu tiên đến sau khi build & chạy thật trên Android.

Tài liệu này ghi lại **những gì đã hoàn thành kèm bằng chứng kiểm chứng được**, và
**những gì tuy đã làm nhưng chưa kiểm chứng được**. Phần chưa kiểm chứng được nêu rõ
vì đó là nơi dễ xảy ra ảo tưởng.

---

## A. BẰNG CHỨNG TỔNG QUAN

| Kiểm tra | Kết quả | Cách xác minh |
|----------|---------|---------------|
| `flutter analyze lib/ test/` | **0 error, 0 warning** (60 info-level) | Chạy thật |
| `flutter test` | **48/48 pass** | Chạy thật |
| `flutter build apk --debug` | ✅ `√ Built app-debug.apk` | Chạy thật |
| `flutter build appbundle --release` | ✅ `√ Built app-release.aab` — 64.2 MB, **đã ký** | Đọc `META-INF/*.RSA` trong AAB |
| `flutter build apk --release` | ✅ `√ Built app-release.apk` — 63.5 MB | Chạy thật |
| App **bản release có R8** chạy trên thiết bị | ✅ mở tới màn hình chính sau ~5 s | Cài `app-release.apk` + mở + chụp màn hình |
| Ảnh chụp store | 6 ảnh PNG 1080×2400 hợp lệ | Đọc header PNG từng file |
| Âm thanh trong bản release | ✅ **12/12** còn nguyên sau R8 | Đọc `resources.arsc` trong APK |
| Bố cục ở chế độ ngang | ✅ không tràn (đã có bug thật, đã sửa) | Xoay ngang + chụp màn hình |
| Swift (iOS) **compile** | ❌ **KHÔNG** | Không có macOS/Xcode |

---

## B. GIAI ĐOẠN 1 — Sửa lỗi cấu trúc & bảo mật ✅

| # | Task | Bằng chứng |
|---|------|-----------|
| 1 | Xoá `MainActivity.kt` trùng lặp (package `com.example.wakeup_app`) | File không còn trong cây source |
| 2 | Gộp 2 class `NativeAlarmService` trùng lặp → còn 1 | `lib/data/local/native_alarm_service.dart` |
| 3 | SQLCipher: bỏ key hardcode `default_wakeup_cipher_key` | Tạo `EncryptionKeyService`, key lấy từ Keystore |
| 4 | Thêm `flutter_secure_storage` | Có trong `pubspec.yaml`, verify key hoạt động khi app chạy |
| 5 | Hoàn thiện `skipNextDate` (trước là TODO) | Có test hồi quy |
| 6 | `calculateSnoozeTime` + triển khai `_snoozeAlarm` | Hoạt động trên thiết bị |
| 7 | 48 unit/integration test | `test/` gồm 4 file |

---

## C. GIAI ĐOẠN 2 — iOS native ⚠️ ĐÃ VIẾT, CHƯA KIỂM CHỨNG

### C1. Phần đã scaffold và viết

| File | Nội dung |
|------|----------|
| `ios/Runner/AlarmScheduler.swift` | Hẹn chuỗi notification + hẹn trước lần kêu tương lai |
| `ios/Runner/AlarmAudioPlayer.swift` | Phát chuông lặp qua `AVAudioSession` category `.playback` |
| `ios/Runner/AlarmPlugin.swift` | MethodChannel handler + `UNUserNotificationCenterDelegate` |
| `ios/Runner/AppDelegate.swift` | Đăng ký plugin qua `registrar(forPlugin:)` |
| `ios/Runner/Info.plist` | `UIBackgroundModes: audio`, tên `WakeUp+` |
| `ios/Runner.xcodeproj/project.pbxproj` | Đăng ký 5 Swift + 12 file WAV vào bundle |

### C2. Phát hiện quan trọng trong quá trình làm

- **iOS project chưa từng được scaffold.** `.metadata` chỉ liệt kê `root` + `android`;
  thiếu `Runner.xcodeproj`, `Info.plist`, `AppDelegate.swift`. Đã chạy
  `flutter create --platforms=ios` để tạo nền tảng.
- **Giới hạn 64 notification của iOS.** Thiết kế cũ dùng ~60 notification *cho mỗi
  báo thức* → chỉ cần 2 báo thức là vượt hạn mức, các notification sau bị iOS từ chối
  **trong im lặng**. Đã xây cơ chế phân bổ ngân sách (`IosNotificationBudget`), có test
  bất biến "tổng ≤ 60" quét 1–20 báo thức × 5 mức autoStop.
- **Sửa lỗi nuốt báo lại.** `scheduleAlarm` xoá toàn bộ notification của báo thức,
  gồm cả chuỗi báo lại → mỗi lần app mở lại là mất lần báo lại đang chờ.

### C3. ❌ CHƯA KIỂM CHỨNG

Toàn bộ Swift **chưa từng được compile**. Máy đang chạy Windows, không có Xcode.
Có thể sai: sai API, sai chữ ký, lỗi cú pháp Swift, thiếu entitlement.

---

## D. GIAI ĐOẠN 3 — Reschedule báo thức ✅

**Bug gốc:** báo thức lặp chỉ kêu đúng một lần rồi im — không tầng nào lập lại lịch sau
khi chuông vang.

### D1. Kiến trúc 3 lớp sau khi sửa

| Lớp | Cơ chế |
|-----|---------|
| Native tự lập lại | `AlarmTriggerReceiver` tính lần kêu tiếp khi chuông vang (Android). iOS hẹn trước N lần kêu tương lai |
| Dart bù lại | `rescheduleAfterFire()` ghi lịch sử + lập lịch |
| Re-arm khi mở app | `rearmEnabledAlarms()` mỗi lần app resume |

Không thể chỉ dựa vào Dart: khi chuông vang, Flutter engine có thể không chạy (Android
đã kill app), và iOS **cấm dịch code nền hoàn toàn**.

### D2. Bug nghiêm trọng phát hiện khi sửa

| # | Bug | Hậu quả | Đã sửa |
|---|-----|----------|---------|
| 1 | `AlarmReceiver` đọc thẳng SQLite | DB đã mã hóa SQLCipher → đọc luôn thất bại → **reboot máy là mất sạch báo thức** | Tạo `AlarmRegistry` (SharedPreferences), không phụ thuộc DB |
| 2 | `exported="false"` trên `AlarmReceiver` | Hệ thống **không gửi được** `BOOT_COMPLETED` dù đã khai báo trong manifest | Đổi thành `true` + thêm `MY_PACKAGE_REPLACED` |
| 3 | `deleteAlarm` không xoá `AlarmEvents` | Vi phạm khoá ngoại | Sửa thành transaction cascade |

### D3. Test hồi quy

15 test trong `test/data/alarm_repository_reschedule_test.dart` chạy DB in-memory thật +
mock MethodChannel, khẳng định:
- Báo thức hàng ngày kêu 07:00 → lập lại đúng 07:00 **hôm sau**
- Chỉ lặp Thứ 5 → đúng **7 ngày** sau
- Tắt trễ 07:45 vẫn ra ngày mai, không lặp lại hôm nay
- Báo thức **một lần** → không lập lại
- Báo thức đã tắt / không tồn tại → không lập lại
- Snooze dùng ID riêng, không đè lên lịch định kỳ

---

## E. GIAI ĐOẠN 4 — Auto-stop & ghi nhận bỏ lỡ ✅

Trước đây chuông **reo vô hạn** nếu người dùng không tương tác.

| Nơi | Cơ chế |
|-----|--------|
| Android | `Handler.postDelayed` trong Foreground Service, deadline lưu vào SharedPreferences để sống sót nếu tiến trình bị hạ |
| iOS — chuỗi notification | `chainLength(autoStopMinutes:)` |
| iOS — audio foreground | `DispatchQueue.asyncAfter` + bộ đếm `generation` để không tắt nhầm chuông mới |

**Ghi nhận bỏ lỡ:** native ghi vào `MissedAlarmStore`, Dart gọi `getMissedAlarms` mỗi lần
app mở. Khi người dùng bấm tắt, deadline được xoá → không ghi nhận nhầm.

### Bug phát hiện bởi test
Test `syncMissedAlarms` thất bại và lộ ra: **SQLite mặc định TẮT kiểm tra khoá ngoại** →
lịch sử ghi cho báo thức đã xoá vẫn "thành công" → dữ liệu mồ côi. Đã bật
`PRAGMA foreign_keys = ON` **và** kiểm tra tồn tại tường minh trong code.

---

## F. ÂM THANH ✅ (12 chuông)

12 file WAV thật, sinh bằng `tools/generate_alarm_sounds.py` (chạy lại được, chỉ dùng
thư viện chuẩn Python): `alarm_default`, `beep`, `radar`, `siren`, `bell`, `birds`,
`arpeggio`, `buzzer`, `chime`, `wakeup`, `digital`, `sunrise`.

Đưa vào **cả 3 nơi** (12/12 mỗi nơi): `assets/sounds/`, `android/.../res/raw/`,
`ios/Runner/Sounds/` + đăng ký vào `project.pbxproj`.

**Phát hiện quan trọng:** trước đây `soundId` được Dart gửi xuống nhưng `MainActivity`
nhận rồi **bỏ qua**, `AlarmService` luôn phát âm mặc định hệ thống. 12 file âm thanh
nếu chỉ đặt vào mà không sửa là dead weight. Đã nối xuyên suốt kèm tôn trọng `volume`
và bật `isLooping`.

Thêm `android/app/proguard-rules.pro` (**trước đó không tồn tại**) — bắt buộc vì
`resources.getIdentifier()` là tra cứu động, không có rule này R8 sẽ **xoá file âm
thanh trong bản release**.

### Kiểm định tín hiệu: 12/12 đạt
Kiểm bằng FFT: không clipping (đỉnh −0.7 dBFS), DC offset ≈ 0, nối loop mượt, đúng số
vòng lặp nguyên, đủ tần số chính, dải sát Nyquist sạch.

**2 lỗi thật trong bộ sinh âm thanh đã được tìm và sửa:**
- `alarm_beep`: DC offset −0.071 (sóng vuông duty cycle lệch) → thêm bộ lọc chặn DC
- `alarm_arpeggio`: `min(int(cyc/0.2), 3)` khiến sau 0.8s chu kỳ phát nốt 4 với hệ số
  bao hình **âm** → méo tiếng
- `alarm_bell`: 8 nhát chồng nhau thành tiếng ù liên tục → rút thời gian suy giảm

**3 lỗi trong chính bộ kiểm tra cũng đã sửa** (logic ghép cặp start/end lệch gây ra
"khoảng lặng −0.737s"; `max-jump` báo động giả cho sóng vuông; ngưỡng phổ đặt sai).

> ⚠️ **Đây là kiểm tra kỹ thuật, KHÔNG phải nghe thử.** AI không nghe được âm thanh.
> Nhịp độ cảm giác của `radar` và `siren` cần người đánh giá.

---

## G. BUILD & CHẠY THẬT ✅

Lần build đầu tiên phát hiện **3 lỗi thật chỉ lộ ra khi build**:

| Lỗi | Nguyên nhân | Đã sửa |
|-----|-------------|---------|
| NDK mismatch | Dự án để NDK 25.1, **15 plugin** yêu cầu 28.2 | `build.gradle.kts` → `28.2.13676358` |
| Double/Float mismatch | `scheduleAlarm` nhận `Double`, `AlarmRegistry` nhận `Float` | Thống nhất `Float` |
| Unresolved reference | `rescheduleNextOccurrence` dùng biến chỉ có trong `onReceive` | Đọc lại từ `Intent` |

**Quan sát đã xác nhận trên thiết bị:**
- SQLCipher mở và đọc được (không còn lỗi `default_wakeup_cipher_key`)
- `AlarmReceiver` bắt `MY_PACKAGE_REPLACED` và đọc registry đúng
- `TimeUtils` tính đúng: "Kế tiếp sau 10h 38p · CN, 13:45"
- Đếm ngược **chạy thật** (10h42p → 10h38p giữa hai lần chụp)
- Múi giờ đúng: New York "Hôm qua −11H", Tokyo "+2H", London "−7H"

---

## H. STORE & TÀI LIỆU ⚠️ MỚI HOÀN THÀNH 1 PHẦN

| Hạng mục | Trạng thái |
|----------|-----------|
| Ảnh chụp | ✅ **7 ảnh thật** (thêm `08_onboarding.png` chụp từ **bản release**), 1080×2400, header PNG đã verify |
| Ảnh còn thiếu | ❌ màn tạo báo thức, màn nhiệm vụ toán |
| Chữ đè lên ảnh | ❌ chưa làm (cần Figma/Canva) |
| ASO metadata | ✅ `store/ASO_METADATA.md` — mô tả song ngữ, Data Safety, checklist |
| Kế hoạch ảnh | ✅ `store/SCREENSHOT_PLAN.md` — kịch bản 8 ảnh + lệnh chụp |
| Privacy Policy / ToS | ❌ **chưa có** |

**Vấn đề lộ ra khi chụp ảnh thật:**
- App chỉ có **dark theme** → ảnh nền tối khó bán trên store
- Luồng `AppRouter` chặn ở `LoginScreen` cần tài khoản Supabase thật → đã thêm cờ
  `SKIP_LOGIN_FOR_SCREENSHOTS` (chỉ đọc lúc **biên dịch**)

**Lỗi tài liệu đã phát hiện và sửa:** lệnh `adb exec-out screencap -p > file.png`
trong PowerShell tạo ra PNG **hỏng** (redirection văn bản chèn CRLF). Phải dùng
`adb pull`. Đã kiểm chứng bằng cách đọc header PNG.

---

## H2. GIAI ĐOẠN 7 — Bản phát hành thật (signing + R8) ✅

Lần đầu tiên build `release` trong dự án này. Đây là nơi **lộ ra 4 lỗi nghiêm trọng
chỉ xuất hiện ở bản phát hành** — không loại nào xuất hiện ở `debug`.

### H2.1 Bốn lỗi đã tìm ra

| # | Lỗi | Nguyên nhân | Sửa bằng cách |
|---|-----|-------------|----------------|
| 1 | R8 dừng build: `Missing classes detected` | Flutter khai báo `FlutterPlayStoreSplitApplication` tham chiếu lớp Play Core, app không dùng deferred components | `-dontwarn com.google.android.play.core.**` |
| 2 | `Keystore file ... not found for signing config 'release'` | `storeFile` trong `key.properties` resolve tương đối với `android/app/`, không phải `android/` | Sửa thành `storeFile=wakeup-release.jks` |
| 3 | **`shrinkResources` XOÁ SẠCH 12 file âm thanh** | `AlarmService` tìm file bằng `resources.getIdentifier("alarm_siren", "raw", …)` — tra cứu bằng **chuỗi**, R8 không thấy nên coi là không dùng | Bỏ reflection, liệt kê tường minh bằng `R.raw.xxx` trong một `when` |
| 4 | **App kẹt vĩnh viễn ở màn hình loading** — không crash, không log | `_checkInitialState()` được gọi từ `initState` mà không `await`; `Supabase.instance` ném lỗi khi chưa khởi tạo → future lỗi bị nuốt → `_isLoading` kẹt `true` vĩnh viễn | `try/catch` riêng từng nhánh + `timeout` + luôn gọi `setState` |

Lỗi #3 và #4 đều là loại **"chạy vẫn thấy bình thường, nhưng người dùng gặp là hỏng"**:
- #3 → chuông rơi về âm mặc định của hệ thống, **không có báo lỗi nào**
- #4 → app không phản ứng, người dùng chỉ biết khởi động lại

### H2.2 Bằng chứng đo được

| Kiểm tra | Trước khi sửa | Sau khi sửa |
|----------|---------------|-------------|
| Tên 12 âm thanh trong `resources.arsc` của APK release | **0/12** | **12/12** ✅ |
| Số file `.wav` thực sự nằm trong APK release | **0** | **12** ✅ |
| Thời gian bản release tới màn hình chính | **>80 s, không bao giờ xong** | **~5 s** ✅ |
| Lỗi runtime sau khi bật R8 (`ClassNotFound`, `NoSuchMethod`, `VerifyError`) | — | **0** ✅ |
| Ký số AAB | — | `META-INF/WAKEUP.RSA` ✅ |

### H2.3 Loại bỏ 2.6 MB thừa

`assets/sounds/` được khai báo trong `pubspec.yaml`, trong khi **không có dòng code Dart
nào đọc tới** (đã grep toàn bộ `lib/`). 12 file bị đóng gói **hai lần**: một lần vào
`assets/flutter_assets/`, một lần vào `res/raw/`. Bỏ khai báo → APK **66.1 MB → 63.5 MB**.

> Vì sao âm thanh không cần nằm trong `assets/`? Android đọc từ `res/raw/`, iOS đọc từ
> `ios/Runner/Sounds/`. `assets/sounds/` chỉ là nơi script sinh file gốc.

### H2.4 Một lỗi chỉ lộ ra khi kiểm thử widget test

`flutter test` fail với `A RenderFlex overflowed by 29 pixels` tại
`onboarding_screen.dart:225`. Đây **là bug thật**, không phải lỗi test: các slide
onboarding dùng `Column` + hai `Spacer()`, nên trên màn hình thấp (xoay ngang, chia đôi
màn hình, máy nhỏ) nội dung tràn ra ngoài và người dùng thấy sọc vàng-đen.

Đã sửa bằng khung `_slideScaffold()`: phần nội dung giữa nằm trong vùng cuộn, nút bấm
ghim cố định ở đáy. **Đã kiểm chứng lại trên máy thật bằng cách xoay ngang** — không còn
sọc, nút vẫn bấm được.

> Test cũ cũng phải sửa theo: cho thời gian đủ để các `timeout` hết hạn thay vì bỏ
> timeout đi. Timeout là cơ chế chống treo — không được xoá để chiều test.

---

## I. DANH SÁCH CHƯA LÀM

| # | Việc | Mức độ |
|---|------|--------|
| 1 | **Build & kiểm thử iOS trên macOS** | 🔴 Chặn go-live iOS |
| 2 | **Privacy Policy + Terms of Service** — file chưa tồn tại | 🔴 Bắt buộc của store |
| 3 | **Firebase chưa cấu hình** — logcat: `Default FirebaseApp failed to initialize` | 🟡 Crashlytics không hoạt động |
| 4 | **Test trên nhiều hãng máy** — MIUI, OneUI, ColorOS | 🔴 Mục tiêu 99.9% |
| 5 | **Sao lưu khoá ký ra ngoài repo** — hiện chỉ có trong `android/app/` | 🔴 Mất khoá = app chết vĩnh viễn |
| 6 | **Theme sáng** — app chỉ hardcode `AppTheme.darkTheme` | 🟡 Ảnh store |
| 7 | **CI/CD** — chưa có GitHub Actions / Codemagic | 🟡 |
| 8 | **`assets/images/` và `assets/fonts/` rỗng** nhưng đã khai báo trong pubspec | 🟡 |
| 9 | **Video giải trình cho reviewer** (chứng minh cần `SCHEDULE_EXACT_ALARM`) | 🟡 Rủi ro bị từ chối |
| 10 | **Monetization** — `PaywallScreen` có sẵn nhưng RevenueCat chưa nối | ⏸ Tạm hoãn, launch miễn phí |
| 11 | **`getMissedAlarms` trả về rỗng trên iOS** — không phát hiện được báo lỡ (iOS cấm code nền) | 🟡 Ảnh hưởng thống kê |
| 12 | **Nghe thử 12 âm thanh** bằng tai (QC hiện chỉ là phân tích phổ) | 🟢 |
| 13 | **Version `1.0.0+1`** — chưa bán bao giờ, số mới ổn | 🟢 |

---

## J. THAY ĐỔI CẦN REVIEW

### J.1 Bí mật — cần bạn hành động ngay

Khoá ký release đã được tạo. **Mật khẩu nằm trong `android/key.properties`** (file này
đã thêm vào `.gitignore`, không lên git).

> ⚠️ **Mất khoá này = app đã phát hành không bao giờ cập nhật được nữa.**
> Google Play gắn ứng dụng với khoá ký đầu tiên. Hãy sao lưu `android/app/wakeup-release.jks`
> và `android/key.properties` ra **ít nhất 2 nơi khác nhau** (không cùng ổ cứng).

Nếu bạn muốn đổi mật khẩu, xoá 2 file trên rồi chạy lại:
```powershell
keytool -genkeypair -v -keystore android/app/wakeup-release.jks -storetype PKCS12 `
  -keyalg RSA -keysize 4096 -validity 10000 -alias wakeup `
  -dname "CN=WakeUp App, OU=Mobile, O=WakeUp, L=Hanoi, C=VN"
```

### J.2 Thay đổi trong source cần review

| # | File | Nội dung |
|---|------|----------|
| 1 | `android/app/proguard-rules.pro` | Mới. Giờ chỉ còn `-dontwarn com.google.android.play.core.**`. **Đã bỏ** rule giữ `R$raw` vì không còn dùng `getIdentifier()` — xem giải thích trong H2.1 #3 |
| 2 | `android/app/build.gradle.kts` | Thêm `signingConfigs.release` đọc từ `key.properties`; bật `isMinifyEnabled` + `isShrinkResources`; `minSdk = 26`; `resourceConfigurations` |
| 3 | `lib/core/app_router.dart` | `try/catch` + `timeout` cho `_checkInitialState`; thêm cờ `SKIP_LOGIN_FOR_SCREENSHOTS` |
| 4 | `lib/main.dart` | Tách `_initCrashReporting()` / `_installGlobalErrorHandlers()`; bổ sung `timeout`. **Bộ bắt lỗi giờ gán được cả khi Firebase lỗi** — trước đây không |
| 5 | `lib/features/onboarding/onboarding_screen.dart` | Thêm `_slideScaffold()` chống tràn bố cục (xem H2.4) |
| 6 | `android/.../AlarmService.kt` | `resolveSoundUri()` → `resolveSoundResourceId()` dùng `R.raw` tĩnh |
| 7 | `pubspec.yaml` | Bỏ khai báo `assets/sounds/` (tiết kiệm 2.6 MB) |
| 8 | `.gitignore` | Thêm `*.jks`, `*.keystore`, `/android/key.properties` |

> ⚠️ `SKIP_LOGIN_FOR_SCREENSHOTS` chỉ đọc lúc **biên dịch** (`bool.fromEnvironment`).
> **Bản release phải build không kèm cờ này.** Công cụ phát hành phải bảo đảm điều đó.