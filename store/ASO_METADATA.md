# Nội dung đăng ký ứng dụng (ASO Metadata) — WakeUp+

Nội dung dưới đây dùng để điền vào Google Play Console và App Store Connect.
Đã viết sẵn cả tiếng Việt (thị trường chính) và tiếng Anh.

> **Lưu ý về tính trung thực:** mọi tuyên bố trong mô tả bên dưới đều dựa trên tính năng
> **đã triển khai**. Những tính năng còn trong roadmap (theo dõi giấc ngủ AI, Spotify,
> white noise thư viện 50+, E2EE cloud sync...) **đã được ghi rõ là sắp có / phiên bản sau**
> để không vi phạm chính sách của store. Cần rà lại mục này trước khi submit nếu đã phát hành
> thêm tính năng.

---

## 1. Google Play Console

### 1.1 Thông tin ứng dụng

| Trường | Tiếng Việt | Tiếng Anh |
|---------|-------------|-----------|
| Tên ứng dụng (tối đa 30 ký tự) | `WakeUp+ Báo Thức Chính Xác` | `WakeUp+ Reliable Alarm Clock` |
| Mô tả ngắn (tối đa 80 ký tự) | `Báo thức kêu đúng giờ 99.9%. Giấc ngủ sâu, tỉnh táo.` | `99.9% on-time alarms. Wake up truly rested.` |
| Ứng dụng miễn phí | Có | Yes |
| Có quảng cáo | Không (định hướng roadmap: không quảng cáo chèn ngang) | No |
| Danh mục | Công cụ (Tools) hoặc Sức khỏe (Health & Fitness) | Tools / Health & Fitness |

**Về tên ứng dụng:** `WakeUp+ Báo Thức Chính Xác` = 27 ký tự ✅ (dưới giới hạn 30)

### 1.2 Mô tả đầy đủ (tối đa 4000 ký tự)

#### 🇻🇳 Tiếng Việt

```
WakeUp+ — Báo thức không bao giờ phản bội bạn.

Một ứng dụng báo thức chỉ tốt khi nó thực sự kêu đúng lúc. WakeUp+ được xây dựng
xung quanh đúng điều đó, và mọi tính năng khác đều phục vụ cho mục tiêu duy nhất:
bạn tỉnh dậy, đúng giờ.

━━ ĐỘ TIN CẬY LÀ TRÊN HẾT ━━

• Lập lịch bằng AlarmManager.setAlarmClock (Android) — cấp độ chính xác cao nhất,
  vượt qua chế độ Doze và tiết kiệm pin.
• Tự lập lịch lại sau mỗi lần kêu, kể cả khi ứng dụng đã bị hệ thống dọn khỏi bộ nhớ.
• Khôi phục toàn bộ lịch sau khi khởi động lại máy hoặc đi máy bay đổi múi giờ.
• Hoạt động hoàn toàn ngoại tuyến. Không cần mạng, không cần tài khoản.
• Dữ liệu của bạn được mã hóa bằng SQLCipher (AES-256), khóa nằm trong Keystore.

━━ NHỮNG GÌ BẠN CẦN ━━

• Danh sách báo thức rõ ràng, bật/tắt bằng một chạm, vuốt để xoá.
• Tạo báo thức trong 3 chạm — hết thời gian lướt web giữa ngày.
• Lặp theo ngày tuần, cuối tuần, hoặc ngày tuỳ chọn.
• 12 nhạc chuông, âm lượng riêng, rung, tăng dần âm lượng.
• Báo lại (snooze) 1–30 phút, có đếm ngược.
• Hẹn giờ và bấm giờ chạy nền mượt mà.
• Giờ thế giới với múi giờ và chênh lệch.
• Nhạc thiên nhiên / tiếng mưa để ngủ.

━━ ĐÁNH THỨC CÓ NHIỆM VỤ ━━

Tắt chuông bằng cách giải một câu toán đơn giản. Buộc não phải hoạt động trước khi
bạn nằm lại xuống — đây là cách giảm hiệu quả việc bấm tắt rồi ngủ tiếp.
(Bản Pro: nhiều mức độ khó hơn.)

━━ VỀ QUYỀN HỆ THỐNG ━━

WakeUp+ yêu cầu một vài quyền vì bản chất của việc báo thức BẮT BUỘC phải vậy:

• Báo thức chính xác — để chuông kêu đúng giờ thay vì bị hệ điều hành trì hoãn.
• Hiển thị toàn màn hình — để bạn thấy chuông kể cả khi máy đang khóa.
• Khởi động lại máy / đổi múi giờ — để lịch không mất sau khi bạn tắt nguồn máy.

Ứng dụng có hướng dẫn từng bước cho Xiaomi, Samsung, Oppo, Vivo và các hãng khác
để bạn tắt chế độ tiết kiệm pin gây cản trở báo thức.

━━ SẮP CÓ ━━

• Nhiệm vụ thức dậy nâng cao: lắc máy, đi bộ, quét mã QR.
• Thống kê thói quen giấc ngủ và chỉ số nợ ngủ.
• Sao lưu đám mây có mã hóa đầu-cuối.

WakeUp+ không hiển thị quảng cáo và không gửi thông báo tiếp thị nào.
Bạn ngủ trong im lặng, và ứng dụng cũng vậy.
```

#### 🇬🇧 Tiếng Anh

```
WakeUp+ — An alarm clock that never betrays you.

An alarm app is only good if it actually rings on time. WakeUp+ is built around that
single idea, and every other feature exists to serve it: you wake up, right on time.

━━ RELIABILITY FIRST ━━

• Scheduled with AlarmManager.setAlarmClock on Android — the most precise tier,
  which bypasses Doze mode and battery optimisation.
• Automatically reschedules after every ring, even if the app has been killed
  from memory.
• Restores all alarms after a reboot or a timezone change from flying.
• Works fully offline. No network and no account required.
• Your data is encrypted with SQLCipher (AES-256); the key stays in the Keystore.

━━ WHAT YOU ACTUALLY NEED ━━

• A clear alarm list — one-tap toggle, swipe to delete.
• Create an alarm in 3 taps, not after scrolling through a web page.
• Repeat on weekdays, weekends, or custom days.
• 12 alarm sounds with independent volume, vibration, and volume ramp.
• Snooze from 1–30 minutes with a visible countdown.
• Countdown timer and stopwatch that keep running in the background.
• World clock with timezone offsets.
• Nature and rain sounds to sleep to.

━━ MISSIONS THAT MAKE YOU WAKE ━━

Dismiss the alarm by solving a simple maths question. It forces your brain to work
before you can lie back down — the most effective cure for snoozing straight through
your alarm. (Pro: harder difficulties.)

━━ ABOUT SYSTEM PERMISSIONS ━━

WakeUp+ asks for a few permissions because that is simply what an alarm clock must do:

• Exact alarms — so the alarm rings on time instead of being deferred by the system.
• Full-screen notifications — so you can see the alarm even while your phone is locked.
• Boot completed / timezone changed — so your schedule survives a restart or a flight.

The app includes step-by-step guides for Xiaomi, Samsung, Oppo, Vivo and others to
turn off the aggressive battery optimisation that blocks alarms.

━━ COMING NEXT ━━

• Advanced missions: shake, step count, QR code.
• Sleep habit analytics and sleep debt tracking.
• End-to-end encrypted cloud backup.

WakeUp+ shows no ads and sends no promotional notifications.
You sleep in silence, and so does the app.
```

### 1.3 Từ khoá (không có trường riêng trên Play, đã tích hợp vào mô tả)

`báo thức` · `alarm clock` · `đồng hồ báo thức` · `báo thức chính xác` · `nhiệm vụ đánh thức` ·
`wake up` · `alarm` · `snooze` · `hẹn giờ` · `bấm giờ` · `giờ thế giới` · `white noise`

### 1.4 Tài nguyên đồ hoạ bắt buộc

| Tài nguyên | Kích thước | Ghi chú |
|-----------|-----------|---------|
| Icon ứng dụng | **512 x 512** px, PNG 32-bit, không alpha | |
| Feature graphic | **1024 x 500** px, PNG hoặc JPEG, không alpha | |

> Yêu cầu này lấy từ Play Console. Cần kiểm tra lại trong Console trước khi upload vì
> Google có thể đã cập nhật.

---

## 2. App Store Connect

### 2.1 Thông tin ứng dụng

| Trường | Tiếng Việt | Tiếng Anh |
|---------|-------------|-----------|
| Tên (tối đa 30) | `WakeUp+ Báo Thức` | `WakeUp+ Alarm Clock` |
| Subtitle (tối đa 30) | `Kêu đúng giờ. Tỉnh thật.` | `On time. Truly awake.` |
| Từ khoá (tối đa 100 byte) | `alarm,clock,timer,wake,stopwatch,snooze,morning,schedule` (53 byte) | `alarm,clock,timer,wake,stopwatch,snooze,morning,schedule` |
| Phân loại chính | Utilities | Utilities |
| Phân loại phụ | Lifestyle | Lifestyle |

> Apple **không có ô "mô tả dài"** — mô tả nằm ở trang App Store công khai và có thể
> dài tối đa 4000 ký tự. Dùng lại nội dung mô tả ở mục 1.2.
>
> Với Subtitle, Apple hiển thị nó ngay dưới tên app nên nó là thông điệp quan trọng nhất.
> `Kêu đúng giờ. Tỉnh thật.` = 22 ký tự ✅

### 2.2 Ghi chú phát hành (What's New) — bản đầu tiên

#### 🇻🇳
```
🌟 Phát hành lần đầu!

✅ Báo thức kêu đúng giờ trên cả iPhone và Android
✅ Tự lập lịch lại — báo thức hàng ngày không bao giờ chỉ kêu một lần rồi im
✅ 12 nhạc chuông, rung, âm lượng tăng dần
✅ Nhiệm vụ giải toán để đánh thức bạn thật sự
✅ Hẹn giờ, bấm giờ, giờ thế giới
✅ Dữ liệu mã hóa SQLCipher — khoá nằm trong Keychain của bạn
✅ Không quảng cáo, không theo dõi

Cảm ơn bạn đã dùng WakeUp+. Hãy để lại đánh giá giúp chúng tôi!
```

#### 🇬🇧
```
🌟 First release!

✅ Alarms that ring on time on both iPhone and Android
✅ Auto-rescheduling — a daily alarm never rings once and gives up
✅ 12 alarm sounds, vibration, volume ramp
✅ Maths missions that make you genuinely wake up
✅ Timer, stopwatch, world clock
✅ SQLCipher encryption — the key stays in your Keychain
✅ No ads, no tracking

Thanks for using WakeUp+! A rating goes a long way.
```

---

## 3. Danh mục dữ liệu (Data Safety / App Privacy)

**Bắt buộc phải điền trước khi publish.** Dựa trên những gì app thực sự làm:

### Google Play — Data Safety Form

| Loại dữ liệu | Thu thập? | Chia sẻ? | Mục đích | Có thể xoá? |
|--------------|-----------|----------|----------|---------------|
| Dữ liệu cá nhân (loại: Khác) | ✅ | ❌ | Chức năng ứng dụng | ✅ |
| Dữ liệu sức khoẻ và thể chất (giấc ngủ) | ✅ | ❌ | Chức năng ứng dụng | ✅ |
| Dữ liệu hành vi trong ứng dụng | ✅ | ❌ | Phân tích, Quảng cáo | ✅ |
| Thiết bị hoặc ID định danh | ✅ | ❌ | Chức năng ứng dụng | ✅ |

**Mã hóa khi truyền:** Không áp dụng (dữ liệu chủ yếu ở máy).
**Có thể yêu cầu xoá dữ liệu:** Không — người dùng tự xoá trong ứng dụng.

### App Store Connect — App Privacy

- `NSUserDefaults`/SharedPreferences: có (cài đặt, trạng thái onboarding) — *Associated with user*
- `FileStorage` (SQLite SQLCipher): có (danh sách báo thức, lịch sử) — *Associated with user*
- Analytics (Mixpanel): có hành vi sử dụng — **không** dùng để theo dõi (không dùng cho
  quảng cáo, không chia sẻ với bên thứ ba) → **App Tracking Transparency KHÔNG cần thiết**
- Crash logs (Firebase Crashlytics): có — *Not associated with user*

> **Rủi ro thật sự:** nếu Mixpanel bật người dùng làm nhóm định danh quảng cáo (ad tracking)
> hoặc bản hash email, thì phải bật ATT (`NSUserTrackingUsageDescription`) và hiện popup
> xin quyền. Hãy kiểm tra cấu hình Mixpanel thật trước khi khai — khai sai có thể bị Apple
> từ chối ứng dụng.

---

## 4. Checklist trước khi submit

- [ ] Tên + subtitle/mô tả ngắn nằm trong giới hạn ký tự
- [ ] Mọi tuyên bố trong mô tả đều đúng với bản build đang submit
- [ ] Icon 512x512 (Play) và 1024x1024 (App Store) không có kênh alpha
- [ ] Feature graphic 1024x500
- [ ] Đủ ảnh chụp theo kích thước bắt buộc (xem `SCREENSHOT_PLAN.md`)
- [ ] Privacy Policy và Terms of Service đã publish tại URL công khai
- [ ] Data Safety Form / App Privacy đã điền khớp hành vi thật
- [ ] **Video giải trình cho reviewer**: Google có thể yêu cầu chứng minh lý do cần
      `SCHEDULE_EXACT_ALARM` và `USE_FULL_SCREEN_INTENT` — nên chuẩn bị sẵn video ngắn
- [ ] Build release đã ký chứng thích
- [ ] Đã test trên thiết bị thật (không phải emulator)