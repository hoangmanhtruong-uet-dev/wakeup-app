# Kế hoạch ảnh chụp Store — WakeUp+

## ⚠️ Trạng thái: ĐÃ CHỤP 6/8

Thư mục `store/google-play/phone/` đã có **6 ảnh thật**, chụp từ app đang chạy trên
Android emulator (`Medium_Phone_API_37.0`, 1080×2400 @420dpi):

| File | Màn hình | Ghi chú |
|------|----------|---------|
| `01_dashboard.png` | Danh sách báo thức | Dữ liệu thật, đếm ngược chạy thật |
| `02_world_clock.png` | Giờ thế giới | Múi giờ + chênh lệch ngày đúng |
| `03_stopwatch.png` | Bấm giờ / Hẹn giờ | |
| `04_sleep.png` | Âm thanh giấc ngủ | Mixer tiếng mưa / lửa / white noise |
| `05_ringing.png` | **Màn đổ chuông** | Ảnh quan trọng nhất |
| `07_login.png` | Đăng nhập | |

Ảnh gốc chưa chỉnh sửa nằm ở `store/_source-raw/`.

**Còn thiếu:** màn tạo/sửa báo thức và màn nhiệm vụ toán — cần thao tác tap nhiều bước,
emulator hay treo giữa chừng. Có thể chụp tiếp trên máy thật.

### Về việc chữ đè lên
Các ảnh hiện **chưa có** chữ đè lên — cần dùng Figma/Canva/Photoshop thêm theo bảng
kịch bản bên dưới. Không tự động chèn vì chữ sai vị trí sẽ che mất nội dung.

---

## 1. Kích thước bắt buộc

### 1.1 App Store (lấy từ Apple Developer — Screenshot specifications)

| Thiết bị | Kích thước (dọc) | Bắt buộc? |
|----------|------------------|-----------|
| iPhone 6.9" | **1320 x 2868** | ✅ Bắt buộc (bộ chính) |
| iPhone 6.9" (kích cỡ cũ) | 1290 x 2796 / 1284 x 2778 | Tương thích |
| iPhone 6.7" | 1290 x 2796 | Nếu có thiết bị 6.7" |
| iPhone 6.5" | 1242 x 2688 | Tương thích |
| iPhone 6.3"/6.1" | 1206 x 2622 / 1179 x 2556 / 1170 x 2532 | Tương thích |
| iPhone 5.5" | 1242 x 2208 | Tương thích |
| iPad 13" | **2064 x 2752** | ✅ Bắt buộc nếu hỗ trợ iPad |
| iPad 12.9" | 2048 x 2732 | Tương thích |
| iPad 10.9"/10.5" | 1668 x 2388 / 1668 x 2420 | Tương thích |
| App Icon | 1024 x 1024 | ✅ Bắt buộc, **không alpha** |

> Apple hiện yêu cầu **một bộ ảnh iPhone 6.9"**; nếu hỗ trợ iPad thì thêm một bộ 13".
> Chỉ cần bộ kích thước lớn nhất trong mỗi họ thiết bị.
>
> Kiểm tra lại tại
> [developer.apple.com screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
> trước khi upload — Apple có thể đã đổi.

### 1.2 Google Play

| Tài nguyên | Kích thước |
|-----------|-----------|
| Icon | 512 x 512 px, PNG 32-bit, **không alpha** |
| Feature graphic | 1024 x 500 px, PNG/JPEG, không alpha |
| Ảnh điện thoại | 320–3840 px mỗi cạnh; khuyến nghị **1080 x 1920** (9:16) |
| Ảnh tablet 7" | 320–3840 px; khuyến nghị 1920 x 1080 trở lên |
| Ảnh tablet 10" | 320–3840 px |

> Play Console cho phép nạp nhiều kích thước và tự cắt. Nên chụp tỉ lệ gần với chuẩn
> để phần cắt không mất nội dung quan trọng.

---

## 2. Kịch bản ảnh (shot list)

8 ảnh, theo thứ tự người dùng nên quan tâm nhất: độ tin cậy → tính năng → niềm vui.

| # | Màn hình chụp | Dòng chữ đè lên | Vì sao đứng ở vị trí này |
|---|---------------|------------------|--------------------------|
| 1 | Màn hình đổ chuông (toàn màn hình, trên nền tối) | **"Kêu đúng giờ. Không có ngoại lệ."** | Đây là lời hứa cốt lõi của app. Chụp màn hình ring là bằng chứng trực quan mạnh nhất. |
| 2 | Dashboard có "hệ thống bảo vệ đang bật" | **"Tự lập lịch lại — không bao giờ chỉ kêu một lần rồi im"** | Chạm đúng nỗi lo lắng #1 của người dùng báo thức. |
| 3 | Màn hình tạo báo thức (bộ chọn giờ) | **"Tạo báo thức trong 3 chạm"** | Lợi ích rõ ràng, đo được. |
| 4 | Màn hình chọn nhạc chuông | **"12 nhạc chuông, rung, tăng dần âm lượng"** | Nội dung cảm xúc, dễ nhớ. |
| 5 | Màn hình nhiệm vụ toán | **"Tắt chuông phải dùng đầu óc"** | Điểm khác biệt so với app báo thức thông thường. |
| 6 | Hẹn giờ / bấm giờ | **"Hẹn giờ, bấm giờ, giờ thế giới"** | Gộp các tiện ích còn lại vào một ảnh. |
| 7 | Âm thanh giấc ngủ | **"Tiếng mưa để ngủ"** | Nhóm người dùng "ngủ khó". |
| 8 | Màn hình cài đặt (mục quyền) | **"Dữ liệu mã hóa. Không quảng cáo."** | Chặn ngay bên dưới người phân vân về quyền riêng tư. |

### Nguyên tắc khi chụp
- **Dùng dữ liệu thật, đẹp:** 3–4 báo thức với nhãn tiếng Việt có nghĩa
  ("Đi làm", "Dậy con", "Tập gym"), tránh "Alarm 1 / Alarm 2".
- **Điện thoại dùng nền sáng.** Ảnh nền tối (dark mode) khó nổi bật trong listing.
  Nếu app chỉ hỗ trợ dark theme, cần sửa app hoặc chấp nhận ảnh tối.
- **Không chèn mũi tên hay khung hình ghép** — Apple và Google đều đánh giá thấp ảnh
  chỉ toàn khung chữ, không có sản phẩm.
- Chữ đè lên phải **đọc được trên màn hình nhỏ**: nền đậm mờ, chữ trắng, ≥ 40px.
- Giữ tỉ lệ gốc; **không** phóng to quá 3840px.
- Định dạng PNG 24-bit (không alpha) để tương thích cả hai store.

---

## 3. Cách chụp

### 3.1 Android (qua adb)

> ⚠️ **Cảnh báo — đã kiểm chứng:** **KHÔNG dùng** `adb exec-out screencap -p > file.png`
> trong PowerShell. PowerShell chuyển `>` thành redirection **văn bản**, chèn CRLF và
> đổi encoding → file PNG ra **hỏng** dù vẫn có vài trăm KB. Lệnh này im lặng tạo ra
> ảnh không mở được.
>
> Cách đúng: chụp trong máy rồi `adb pull`.

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# 1. Chụp trong máy
& $adb shell screencap -p /sdcard/shot.png

# 2. Kéo về máy tính (giữ nguyên byte nhị phân)
& $adb pull /sdcard/shot.png store\_source-raw\01_ringing.png
```

Nếu dùng **cmd.exe** thì `exec-out` + `>` mới an toàn:

```cmd
adb exec-out screencap -p > shot.png
```

Thêm tiện ích kiểm tra file vừa chụp có phải PNG hợp lệ không:

```powershell
python -c "import struct;d=open(r'store\_source-raw\01_ringing.png','rb').read();assert d[:8]==b'\x89PNG\r\n\x1a\n';print('OK',*struct.unpack('>II',d[16:24]))"
```

Nếu có nhiều thiết bị, dùng `-s <serial>`:
```powershell
adb -s emulator-5554 shell screencap -p /sdcard/shot.png
```

### 3.2 Kích thước thực tế của emulator đã kiểm chứng

Emulator `Medium_Phone_API_37.0` cho ra **1080 x 2400 px @ 420 dpi** (tương đương
411 x 914 dp — cỡ Pixel). Ảnh này nằm trong khoảng Play Console chấp nhận
(320–3840 px mỗi cạnh) và tỉ lệ dọc rất tốt cho store listing.

### 3.2 iOS (trên máy macOS)

```bash
# Liệt kê simulator
xcrun simctl list devices available

# Chụp màn hình simulator
xcrun simctl io booted screenshot store/_source-raw/01_ringing.png
```

`simctl` chụp đúng kích thước thiết bị, nên chọn simulator 6.9" để có sẵn
1320 x 2868.

### 3.3 Thêm chữ đè lên

Nên dùng Figma / Canva / Photoshop. Nếu muốn làm bằng script, ImageMagick:

```powershell
magick store\google-play\phone\01_ringing.png ^
  -gravity North -font SegoeUI-Bold -pointsize 64 -fill White ^
  -undercolor "#000000A0" -annotate +0+120 "Kêu đúng giờ. Không có ngoại lệ." ^
  store\google-play\phone\01_ringing_final.png
```

---

## 4. Ghi chú đặc thù cho reviewer

Google Play có thể **từ chối** app báo thức nếu không giải thích rõ vì sao cần
`SCHEDULE_EXACT_ALARM` và `USE_FULL_SCREEN_INTENT`. Nên chuẩn bị sẵn:

- Một video ngắn (30–60 giây) quay màn hình: cài app → tạo báo thức → khóa máy →
  chuông kêu toàn màn hình.
- Trong mô tả / phần trả lời reviewer, giải thích rằng app là **alarm clock** nên
  các quyền này là chức năng cốt lõi, không phải để theo dõi hay quảng cáo.

Đây là rủi ro thật, không phải thủ tục hình thức — nhiều app báo thức bị từ chối ở bước này.

---

## 5. Rào cản thật khi chụp tự động (đã kiểm chứng)

`AppRouter` chặn người dùng ở `LoginScreen` cho tới khi có Supabase session. Muốn chụp
màn hình chính (`AlarmDashboardScreen`) thì phải đi qua:

```
AppRouter -> OnboardingScreen -> LoginScreen (cần tài khoản Supabase) -> MainNavigationScreen
```

Hai chướng ngại:

1. **Onboarding** — ghi cờ `hasSeenOnboarding = true` trong SharedPreferences là xong.
2. **Đăng nhập** — cần tài khoản Supabase thật. Nếu project bật "Confirm email" thì
   `signUp` cũng không xong. Đây là rào cản lớn nhất khi chụp tự động.

### Cách xử lý được đề xuất

Thêm cờ **chỉ dùng lúc build**, mặc định `false` nên bản release không bị ảnh hưởng:

```dart
// lib/core/app_router.dart
const bool _skipLoginForScreenshots =
    bool.fromEnvironment('SKIP_LOGIN_FOR_SCREENSHOTS');

bool get _isLoggedIn => _skipLoginForScreenshots
    || Supabase.instance.client.auth.currentSession != null;
```

Chạy:

```powershell
flutter run --dart-define=SKIP_LOGIN_FOR_SCREENSHOTS=true
```

`bool.fromEnvironment` chỉ đọc lúc **biên dịch**, không bật được lúc chạy — nên không
có rủi ro bảo mật từ việc người dùng tự mở. Nhưng vẫn nên review kỹ trước khi merge
và nhớ build lại bản release **không** có cờ này.

### Ngoài ra: ảnh nền tối

App hiện chỉ có theme tối (`AppTheme.darkTheme` hardcode trong `main.dart`), trong khi
ảnh store nền sáng dễ nổi bật hơn. Nếu giữ nguyên dark theme thì ảnh sẽ tối và khó
bán. Nên cân nhắc thêm theme sáng trước khi chụp.