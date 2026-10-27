# Lộ trình Phát triển Toàn diện (Roadmap) - WakeUp+ đến Go-Live

Tài liệu này nâng cấp lộ trình triển khai của **WakeUp+** từ bản MVP cơ bản thành một ứng dụng toàn diện về Báo thức, Chăm sóc Giấc ngủ & Năng suất (Smart Alarm & Sleep Suite). Kế hoạch bổ sung chi tiết: hệ thống màn hình UI, mô hình kinh doanh đăng ký (Pro / Ultra), kiến trúc bảo mật cấp ngân hàng, và hệ sinh thái cloud service khuyến nghị để đảm bảo tỷ lệ chuông kêu chính xác 99.9% trên mọi thiết bị.

---

## 📊 1. Phân Tầng Tính Năng & Gói Đăng Ký (Monetization Strategy)

Mô hình kiếm tiền kết hợp Freemium và Subscription (Gói tháng/năm/trọn đời), tích hợp qua giải pháp StoreKit 2 / Google Play Billing (khuyến nghị dùng **RevenueCat**).

| Phân hệ / Tính năng | Miễn phí (Free) | Pro ($2.49/tháng hoặc $17.99/năm) | Ultra ($4.99/tháng hoặc $34.99/năm) |
| :--- | :---: | :---: | :---: |
| **Báo thức cơ bản, Bấm giờ, Hẹn giờ** | Không giới hạn | Không giới hạn | Không giới hạn |
| **Độ tin cậy chuông (Wake-up Engine)** | Chuẩn Native | Chuẩn Native | Chuẩn Native + Cloud Backup Alarm (gửi SMS/Call dự phòng) |
| **Quảng cáo (Ads)** | Banner & Interstitial nhẹ | **Không quảng cáo (100% Ad-Free)** | **Không quảng cáo (100% Ad-Free)** |
| **Nhiệm vụ đánh thức (Missions)** | Lắc máy, Toán cơ bản | Toán nâng cao, Gõ lại văn bản, Đi bộ 30 bước | Quét mã QR/Barcode (nhà tắm), Chụp ảnh đồ vật (AI Photo Match) |
| **Âm thanh báo thức & Giấc ngủ** | 8 chuông mặc định | Thư viện 50+ âm thanh thiên nhiên, White Noise | Kết nối Spotify / Apple Music, Binaural Beats, AI Morning Brief |
| **Theo dõi giấc ngủ (Sleep Tracking)** | Thủ công (Ghi log giờ ngủ) | Phân tích chu kỳ ngủ (Gia tốc kế/Âm thanh) | AI Smart Alarm (đánh thức ở pha ngủ nông REM/Light Sleep) |
| **Widget & Live Activities** | Widget cơ bản | Widget chuyên sâu, Theme tùy biến | Dynamic Island, Live Activities theo dõi giấc ngủ thời gian thực |
| **Bảo mật & Đồng bộ Cloud** | Lưu trữ cục bộ | Sao lưu Cloud mã hóa | E2EE Cloud Sync đa thiết bị, Khóa sinh trắc học (Face ID/Vân tay) |
| **Báo cáo & Phân tích chuyên sâu** | 7 ngày gần nhất | 90 ngày + Thống kê nợ giấc ngủ (Sleep Debt) | Không giới hạn + Xuất PDF/CSV cho bác sĩ, Chấm điểm dậy đúng giờ |

---

## 🎨 2. Kiến Trúc Giao Diện UI & Màn Hình Cần Xây Dựng

### 2.1. Cụm Màn hình Báo thức & Năng suất (Core)
* **`AlarmDashboardScreen`:** Danh sách báo thức dạng thẻ trực quan (Card UI), toggle bật/tắt mượt mà, hiển thị thời gian còn lại đến lần reo kế tiếp.
* **`AlarmEditModal/Screen`:** Vòng quay chọn giờ (Wheel Time Picker), chọn ngày lặp lại, nhãn dán, chọn nhiệm vụ thức dậy (Mission Picker).
* **`RingingScreen` (Native Full-Screen Overlay):**
  - Màn hình tràn viền đánh thức điện thoại khi khóa.
  - Chế độ hiển thị đồng hồ lớn, nút trượt (Slide to Snooze) và nút mở màn hình giải nhiệm vụ.
  - Tự động đẩy độ sáng màn hình theo chu kỳ thức dậy (Sunrise Simulation).
* **`MissionExecutionScreen`:** Màn hình giải đố tương tác (Math, Step Tracker, QR Scanner, Memory Match) - khóa toàn bộ phím điều hướng hệ thống cho đến khi hoàn thành.
* **`WorldClockScreen`:** Giờ thế giới kèm bản đồ tương tác hiển thị vùng ngày/đêm (Day/Night terminator) và thanh trượt đối chiếu chênh lệch múi giờ.
* **`TimerStopwatchScreen`:** Đồng hồ bấm giờ hiển thị đồ thị vòng (Lap times delta) và đồng hồ đếm ngược đa tiến trình chạy song song.

### 2.2. Cụm Màn hình Giấc ngủ & Thư giãn (Sleep & Wellness)
* **`BedtimeRoutineScreen`:** Thiết lập lịch ngủ lành mạnh, nhắc nhở "Wind-down" trước giờ ngủ 30 phút, đếm ngược chu kỳ giấc ngủ khuyến nghị (90 phút/chu kỳ).
* **`SleepSoundScapeScreen`:** Bảng điều khiển âm thanh White Noise, tiếng mưa, tiếng sóng; bộ mixer cho phép hòa trộn nhiều lớp âm thanh (ví dụ: 40% tiếng mưa + 60% tiếng lò sưởi) kèm hẹn giờ tắt mờ dần (Fade-out).
* **`SleepAnalysisDashboard`:** Biểu đồ xu hướng ngủ, điểm chất lượng giấc ngủ (Sleep Score), đo lường tần suất nhấn "Snooze" hàng tuần.

### 2.3. Cụm Màn hình Tài khoản, Đăng ký & Cài đặt
* **`PaywallScreen` (Pro/Ultra):** Thiết kế tối ưu chuyển đổi (High-converting Paywall) so sánh lợi ích gói Free vs Pro vs Ultra, toggle chuyển đổi Tháng/Năm (gắn nhãn "Tiết kiệm 50%"), tích hợp nút khôi phục giao dịch (Restore Purchases).
* **`SystemPermissionGuideScreen`:** Luồng Onboarding chuyên sâu giải thích trực quan từng quyền: Quyền Báo thức chính xác (`SCHEDULE_EXACT_ALARM`), Quyền Thông báo toàn màn hình (`USE_FULL_SCREEN_INTENT`), và hướng dẫn người dùng tắt chế độ tối ưu hóa pin theo từng hãng máy (MIUI, OneUI, ColorOS).
* **`AppLockScreen`:** Màn hình xác thực vân tay/Face ID khi mở app hoặc khi muốn tắt báo thức quan trọng.

---

## 🔒 3. Hạ Tầng Bảo Mật & Toàn Vẹn Hệ Thống (Security Infrastructure)

Để bảo vệ quyền riêng tư người dùng và ngăn chặn can thiệp trái phép vào hệ thống thanh toán:

```
[Flutter Frontend UI]
       │
       ▼ (Chống Debugger & Tampering)
[FreeRASP / Play Integrity / DeviceCheck]
       │
       ├──► [Lưu trữ Local] ──► SQLCipher (Mã hóa CSDL AES-256) + Keychain / Keystore
       │
       ▼ (Bảo vệ đường truyền: TLS 1.3 + SSL Pinning)
[API Gateway / Cloud Functions]
       │
       ├──► [Xác thực & RBAC] ──► Supabase / Firebase Auth (JWT có thời hạn ngắn)
       └──► [IAP Server-Side Verification] ──► RevenueCat Webhooks (Ký số cryptographic)
```

1. **Mã hóa Dữ liệu Cục bộ (Data at Rest):**
   * Sử dụng **SQLCipher** tích hợp trực tiếp vào Drift SQLite để mã hóa toàn bộ dữ liệu báo thức, nhật ký sinh trắc học và lịch trình cá nhân bằng khóa AES-256.
   * Khóa mã hóa được sinh ngẫu nhiên theo thiết bị và lưu trữ trong **Android Keystore** / **iOS Keychain** thông qua thư viện `flutter_secure_storage`.
2. **Bảo mật Dữ liệu Truyền tải (Data in Transit):**
   * Bắt buộc giao thức **TLS 1.3** cho mọi kết nối mạng.
   * Kích hoạt **SSL/TLS Certificate Pinning** trên tầng HTTP Client (`Dio`) để ngăn chặn hoàn toàn các cuộc tấn công nghe lén (Man-In-The-Middle - MITM) qua proxy như Charles Proxy hay Burp Suite.
3. **Toàn vẹn Ứng dụng & Chống Gian lận (Anti-Tampering & IAP Fraud Prevention):**
   * Sử dụng **freeRASP** hoặc **Google Play Integrity API** / **Apple DeviceCheck & App Attest** để phát hiện thiết bị bị Root/Jailbreak, phát hiện ứng dụng bị chèn mã độc (Repackaging).
   * **Xác thực biên lai mua hàng phía Server (Server-Side Receipt Validation):** Tuyệt đối không lưu quyền Pro/Ultra chỉ bằng cờ `bool isPro = true` ở máy cục bộ. Trạng thái bản quyền được đối soát thời gian thực qua Webhook bảo mật từ RevenueCat gửi về Backend Database.
4. **Quyền riêng tư Dữ liệu Nhạy cảm (Zero-Audio Cloud Leak):**
   * Toàn bộ thuật toán phát hiện tiếng ngáy, tiếng thở hoặc theo dõi chuyển động giấc ngủ phải xử lý hoàn toàn **On-Device (Edge ML via TensorFlow Lite)**. Không gửi bất kỳ bản ghi âm giọng nói nào lên đám mây.
5. **Khóa Sinh trắc học (Biometric Guard):**
   * Tích hợp `local_auth` để yêu cầu xác thực Face ID/Touch ID khi mở nhật ký giấc ngủ riêng tư hoặc khi truy cập cài đặt cấu hình an ninh.

---

## ☁️ 4. Danh Sách Dịch Vụ Khuyến Nghị (Tech Stack & Cloud Ecosystem)

| Phân loại | Dịch vụ đề xuất | Vai trò trong dự án | Lý do lựa chọn |
| :--- | :--- | :--- | :--- |
| **Backend & Database** | **Supabase** (hoặc Firebase) | Quản lý người dùng, sao lưu cấu hình, API Functions | PostgreSQL mạnh mẽ, hỗ trợ Row Level Security (RLS) bảo vệ từng hàng dữ liệu, tích hợp Auth nhanh gọn. |
| **Quản lý Đăng ký (In-App Purchase)** | **RevenueCat** | Xử lý thanh toán Apple App Store & Google Play | Chuẩn mực thanh toán cho ứng dụng di động: đồng bộ trạng thái mua, xử lý gia hạn/hủy gói, hỗ trợ A/B test paywall không cần build lại app. |
| **Giám sát Lỗi (Crash Reporting)** | **Sentry** + **Firebase Crashlytics** | Thu thập log crash, ANR và stacktrace chi tiết | Sentry chuyên sâu cho Flutter (theo dõi hiệu năng giật khung hình), Crashlytics theo dõi sự cố native crash ở tầng OS. |
| **Phân tích Hành vi (Product Analytics)** | **Mixpanel** hoặc **PostHog** | Đo lường tỷ lệ hoàn thành nhiệm vụ, phễu chuyển đổi Pro | Phân tích chi tiết hành vi người dùng mà vẫn đảm bảo tiêu chuẩn bảo mật dữ liệu GDPR/CCPA. |
| **Hạ tầng Notification** | **Firebase Cloud Messaging (FCM)** | Đẩy thông báo nhắc giờ ngủ, cập nhật trạng thái | Độ trễ thấp, tương thích tốt với cả Android và iOS APNs. |
| **Âm thanh Background** | **just_audio** & **audio_service** | Chơi nhạc chuông, phát white noise chạy nền | Quản lý tốt Audio Focus (tự giảm âm lượng khi có cuộc gọi đến, tiếp tục phát khi khóa màn hình). |
| **Tự động hóa CI/CD** | **Codemagic** (hoặc GitHub Actions) | Tự động build, ký chứng chỉ mã nguồn và deploy | Tối ưu hóa riêng cho Flutter: build tự động `.aab` lên Google Play Internal Test và `.ipa` lên Apple TestFlight. |

---

## 🚀 5. Lộ Trình Triển Khai Đến Go-Live (Chi tiết từng Phase)

```
Tuần 1-2: Core Engine & Database
Tuần 3-4: Ringing UI, Quyền Native & Missions
Tuần 5-6: UI Giấc ngủ, White Noise & Múi giờ
Tuần 7-9: Hạ tầng Bảo mật, Backend & Gói Pro/Ultra
Tuần 10-11: Kiểm thử 99.9% Độ Tin cậy Đa Hãng
Tuần 12: Phê duyệt Store, Marketing & Launch
```

---

### Giai đoạn 1: Nền tảng Báo thức Cốt lõi & Kiến trúc Dữ liệu (2 Tuần)
*Mục tiêu: Đảm bảo luồng tạo, chỉnh sửa và lưu trữ báo thức ổn định tuyệt đối trên SQLite.*

* **Tầng UI & State Management:**
  - [ ] Hoàn thiện màn hình `AlarmDashboardScreen` với Riverpod/Bloc.
  - [ ] Xây dựng bộ điều khiển chọn giờ cuộn mượt (Custom Time Roller).
  - [ ] Xây dựng màn hình chọn âm lượng, mức độ rung (Haptic feedback pattern).
* **Tầng Native & Cơ sở Dữ liệu:**
  - [ ] Cấu hình CSDL Drift với **SQLCipher** (Mã hóa toàn bộ bảng `Alarms`, `Schedules`).
  - [ ] Thiết lập `MethodChannel` 2 chiều giữa Flutter và Native Android/iOS.
  - [ ] Viết bộ test suite (100% coverage) cho thuật toán tính toán `calculateNextRingTime` có tính đến Daylight Saving Time (DST) và múi giờ quốc tế.

---

### Giai đoạn 2: Đánh Thức Màn Hình Khóa, Quyền Hệ Thống & Missions (2 Tuần)
*Mục tiêu: Báo thức kích hoạt thành công từ chế độ ngủ sâu (Doze Mode) và giải nhiệm vụ để tắt.*

* **Màn hình Đổ chuông (Ringing Engine):**
  - [ ] **Android:** Cấu hình Native Foreground Service kết hợp `Full-screen Intent`, vượt qua khóa màn hình và chế độ Không làm phiền (DND override).
  - [ ] **iOS:** Tích hợp `Critical Alerts` (nếu có entitlement từ Apple) hoặc kết hợp Push Notification cục bộ âm lượng cao với chế độ nền.
  - [ ] Tự động dừng sau thời gian cấu hình (Auto-dismiss sau 10-15 phút) để tránh cạn kiệt pin.
* **Xây dựng Nhiệm vụ Thức dậy (Missions):**
  - [ ] *Nhiệm vụ Toán học:* 3 cấp độ (Dễ, Trung bình, Khó).
  - [ ] *Nhiệm vụ Lắc máy:* Đếm số lần lắc dựa trên gia tốc kế (Accelerometer).
  - [ ] *Nhiệm vụ Đi bộ:* Đếm bước chân bằng cảm biến Step Detector (Free/Pro).
* **Quản lý Quyền Hệ thống (Permissions Onboarding):**
  - [ ] Xây dựng màn hình tương tác xin quyền từng bước: `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`.
  - [ ] Tạo hướng dẫn từng bước (kèm hình ảnh minh họa theo model máy) để người dùng vô hiệu hóa **Battery Optimization** (Samsung, Xiaomi MIUI/HyperOS, Oppo, Vivo).

---

### Giai đoạn 3: Giờ Thế Giới, Âm Thanh & Chăm Sóc Giấc Ngủ (2 Tuần)
*Mục tiêu: Mở rộng tính năng thành ứng dụng chăm sóc thời gian & giấc ngủ đa tiện ích.*

* **Giờ thế giới & Công cụ Năng suất:**
  - [ ] Hoàn thiện `WorldClockScreen`: Tìm kiếm thành phố theo múi giờ, hiển thị chênh lệch giờ so với giờ địa phương.
  - [ ] Xây dựng `TimerStopwatchScreen`: Hỗ trợ lưu trữ vòng lặp (Laps), chạy nền mượt mà qua Native Service.
* **Hệ thống Âm thanh Giấc ngủ (Sleep Soundscape):**
  - [ ] Tích hợp `just_audio` cho phép phát lặp liền mạch (Seamless looping) các file âm thanh White Noise, Pink Noise, Mưa rơi.
  - [ ] Xây dựng tính năng hẹn giờ tắt dần (Fade-out timer) khi người dùng chìm vào giấc ngủ.
* **Widget & Giao diện Động:**
  - [ ] Xây dựng Home Screen Widgets (Android AppWidget & iOS WidgetKit) hiển thị báo thức tiếp theo.
  - [ ] Thiết kế Dynamic Island / Live Activity cho iOS hiển thị đồng hồ đếm ngược và trạng thái hẹn giờ.

---

### Giai đoạn 4: Hạ tầng Bảo mật, Backend Sync & Tích hợp Doanh thu (3 Tuần)
*Mục tiêu: Hoàn tất tích hợp mua hàng trong app (In-App Purchases) và kích hoạt khiên bảo mật.*

* **Tích hợp Doanh thu (Monetization Engine):**
  - [ ] Tích hợp SDK **RevenueCat** vào Flutter.
  - [ ] Xây dựng màn hình `PaywallScreen` động (hỗ trợ điều chỉnh qua Remote Config).
  - [ ] Triển khai logic mở khóa tính năng: Phân quyền phân tầng Free, Pro, Ultra.
  - [ ] Tích hợp xử lý khôi phục giao dịch (Restore Purchase) theo quy định của Apple App Store Review Guidelines.
* **Hạ tầng Đám mây & Sao lưu (Cloud Sync):**
  - [ ] Kết nối **Supabase Auth**: Cho phép đăng nhập ẩn danh (Anonymous), Sign in with Apple, Google Sign-in.
  - [ ] Đồng bộ cấu hình báo thức lên đám mây với cơ chế mã hóa đầu cuối (E2EE - End-to-End Encryption) cho người dùng gói Ultra.
* **Triển khai Tường lửa Bảo mật:**
  - [ ] Cấu hình **SSL Pinning** trong `Dio` client chặn bắt gói tin.
  - [ ] Tích hợp thư viện bảo vệ ứng dụng: Phát hiện Root/Jailbreak, chặn chạy trên Emulator không an toàn.
  - [ ] Khóa sinh trắc học `local_auth` bảo vệ nhật ký giấc ngủ.

---

### Giai đoạn 5: Kiểm Thử Thiết Bị Thật & Đạt 99.9% Độ Tin Cậy (2 Tuần)
*Mục tiêu: Xóa bỏ 100% rủi ro chuông không kêu, lệch giờ hoặc bị hệ điều hành tắt ngầm.*

* **Kiểm thử trên Ma trận Thiết bị Thật (Real Device Matrix):**
  - [ ] Kiểm thử tự động & thực địa trên các dòng máy có trình quản lý pin nghiêm ngặt:
    - Xiaomi / POCO (MIUI / HyperOS - thử nghiệm văng bộ nhớ sau 12 tiếng).
    - Samsung (One UI - kiểm tra chế độ Deep Sleeping Apps).
    - Huawei / Honor (EMUI - xử lý hạn chế background).
    - Apple iPhone (iOS 17, 18 - kiểm tra Silent Mode switch, chế độ StandBy).
  - [ ] Kiểm thử các ca biên (Edge cases): Khởi động lại thiết bị (Device Reboot), cạn pin cắm sạc lại, thay đổi múi giờ khi đi máy bay, chuyển đổi giờ mùa hè.
* **Hạ tầng Giám sát Độ trễ Chuông (Telemetry & Logging):**
  - [ ] Gửi log ẩn danh đo lường thời gian chênh lệch giữa giờ hẹn vs giờ chuông kêu thực tế (Yêu cầu: $\Delta t < 1.0\text{s}$).
  - [ ] Bắt các lỗi xung đột Audio Focus (ví dụ: đang có cuộc gọi đến thì chuông xử lý như thế nào).

---

### Giai đoạn 6: Thẩm Định Store, ASO & Go-Live (1.5 Tuần)
*Mục tiêu: Vượt qua vòng kiểm duyệt của Apple và Google, sẵn sàng quảng bá.*

* **Hồ sơ Pháp lý & Tuân thủ:**
  - [ ] Soạn thảo Điều khoản Dịch vụ (Terms of Service) và Chính sách Quyền riêng tư (Privacy Policy) nêu rõ tiêu chuẩn thu thập dữ liệu và xử lý âm thanh On-Device.
  - [ ] Điền bảng câu hỏi An toàn Dữ liệu (Data Safety Form trên Google Play & App Privacy Details trên Apple App Store).
  - [ ] Chuẩn bị video giải trình cho Google Reviewer chứng minh lý do ứng dụng bắt buộc phải dùng quyền `SCHEDULE_EXACT_ALARM` và `USE_FULL_SCREEN_INTENT`.
* **Tối ưu Hóa Chuyển Đổi Store (ASO & Media):**
  - [ ] Thiết kế bộ ảnh chụp màn hình (Screenshots) chuẩn kích thước 6.7 inch, 6.5 inch, 5.5 inch và Tablet/iPad.
  - [ ] Soạn thảo bản mô tả hấp dẫn, làm nổi bật thông điệp: *"Báo thức cam kết chuẩn giờ 100% - Thức dậy thông minh cùng nhiệm vụ & giấc ngủ sâu"*.
* **Phát hành & Triển khai Tiếp thị (Launch):**
  - [ ] Triển khai phân phối theo đợt (Staged Rollout: 10% -> 25% -> 50% -> 100%) trên Google Play để theo dõi crash phát sinh.
  - [ ] Kích hoạt bản phát hành chính thức trên iOS App Store.
  - [ ] Khởi chạy chiến dịch theo dõi tỷ lệ chuyển đổi (Conversion Rate) của Paywall và độ trôi phễu Onboarding qua Mixpanel.