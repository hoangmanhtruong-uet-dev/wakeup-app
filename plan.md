# KẾ HOẠCH CÒN LẠI ĐẾN GO-LIVE — WakeUp+

Ngày lập: 2026-10-18
Bắt đầu từ trạng thái đã xác nhận trong [`confirm.md`](./confirm.md).

Ước lượng: **3–4 tuần** với 1 người full-time, **5–6 tuần** nếu làm bán thời gian.
Ước lượng này có rủi ro cao vì phần kiểm thử độ tin cậy trên nhiều hãng máy chưa
từng chạy (xem P0-6).

---

## Nguyên tắc xếp ưu tiên

Xếp theo **rủi ro bị chặn store**, không theo độ dễ làm:

- 🔴 **Chặn publish** — không làm thì không submit được
- 🟡 **Ảnh hưởng vận hành** — làm được nhưng sẽ đau
- 🟢 **Chất lượng** — cải thiện trải nghiệm

---

## P0 — Chặn go-live (Bắt buộc)

### P0-1. Ký bản release thật ✅ ĐÃ XONG

**Kết quả:** đã tạo khoá `wakeup-release.jks` (RSA 4096, PKCS12, hạn tới 2054),
cấu hình signing + R8, build thành công cả AAB lẫn APK, và **đã chạy thật bản release
trên thiết bị**.

| Hạng mục | Kết quả |
|----------|---------|
| Keystore | `android/app/wakeup-release.jks` + `android/key.properties` (đã gitignore) |
| `isMinifyEnabled` / `isShrinkResources` | ✅ bật |
| AAB | ✅ 64.2 MB, đã ký (`META-INF/WAKEUP.RSA`) |
| APK | ✅ 63.5 MB (giảm 2.6 MB sau khi bỏ nhân đôi `assets/sounds/`) |
| 12 âm thanh qua R8 | ✅ **12/12 còn nguyên** (trước khi sửa: **0/12**) |
| Bản release chạy trên máy | ✅ tới màn hình chính sau ~5 s, không lỗi runtime |

**4 lỗi chỉ lộ ra ở bản release** — chi tiết ở `confirm.md` mục H2.1:
1. R8 dừng build vì thiếu lớp Play Core → `-dontwarn`
2. `storeFile` resolve sai thư mục → sửa `key.properties`
3. **`shrinkResources` xoá sạch 12 file âm thanh** (vì `getIdentifier()` tra cứu bằng chuỗi)
4. **App kẹt vĩnh viễn ở màn loading** (lỗi bị nuốt trong `initState` không `await`)

**Còn lại của P0-1 — cần bạn làm:**
- [ ] **Sao lưu khoá ký ra ngoài repo, ít nhất 2 nơi.** Mất khoá = app chết vĩnh viễn.

### P0-1b. Build & kiểm thử iOS 🔴 1–2 tuần
**Hiện trạng:** toàn bộ Swift **chưa từng compile**. Đây là khoảng trống lớn nhất.
> Theo quyết định hiện tại: **launch Android trước, iOS để sau.** Phần này chỉ làm khi
> có máy macOS.

Việc cần làm:
- Thuê/dùng máy macOS có Xcode
- `pod install` rồi build; sửa hết lỗi Swift phát sinh
- Bổ sung **Critical Alerts entitlement** nếu muốn chuông vượt qua Silent Mode
  (phải xin từ Apple, mất thời gian → **nên xin sớm**)
- Test thật: chuông kêu khi khóa màn hình, khi app bị suspend, khi máy khởi động lại

### P0-3. Firebase: Crashlytics + Analytics 🔴 2–3 ngày
**Hiện trạng:** logcat trên thiết bị báo
`Default FirebaseApp failed to initialize because no default options were found`.
Crashlytics **không hoạt động** → mất toàn bộ dữ liệu crash, mà PRD yêu cầu độ tin cậy
99.5% nên cần dữ liệu để chứng minh.

Việc cần làm:
- Tạo project Firebase thật
- `flutterfire configure` để sinh lại `firebase_options.dart`
- Thêm `google-services.json` và `GoogleService-Info.plist`
- Kiểm chứng crash test được gửi lên

### P0-4. Privacy Policy + Terms of Service 🟡 ĐÃ VIẾT, CÒN PHẢI ĐĂNG

**Đã xong:** `legal/PRIVACY_POLICY.md`, `legal/TERMS_OF_SERVICE.md`, `legal/README.md`.

Không phải mẫu chung lấy từ mạng — mỗi khẳng định đều đối chiếu với mã nguồn:
- `cloud_sync_service.dart` **không có call site** → dữ liệu báo thức không rời máy
- `AnalyticsService.` chỉ xuất hiện 1 lần trong `main.dart`, token Mixpanel là chuỗi
  giả, không có `trackEvent` nào được gọi → chưa thu thập analytics
- 9 quyền lấy thẳng từ `AndroidManifest.xml`
- `pubspec.yaml` không có SDK quảng cáo nào

**Còn lại — cần bạn làm:**
- [ ] Điền email hỗ trợ + website vào 2 chỗ đang để trống (mục 9 và mục 13)
- [ ] **Đăng 2 file lên URL công khai** (không cần đăng nhập) rồi dán vào Play Console
- [ ] Điền biểu mẫu Data Safety khớp với policy — bảng đối chiếu có sẵn trong
      `legal/README.md`
- [ ] Bản tiếng Anh nếu listing trên Play bằng tiếng Anh

> **Rủi ro đã kiểm tra và loại trừ:** plan cũ cảnh báo phải bật ATT nếu Mixpanel bật định
> danh quảng cáo. **Điều đó không còn đúng** — Mixpanel chưa bật, nên **không cần** ATT
> ở lần phát hành này. Nhưng nếu sau này bật token thật, phải đánh giá lại.

---

### P0-3b. Miễn phí trước, doanh thu sau 🟢 QUYẾT ĐỊNH

Đã chốt: **launch miễn phí 100%**, mở monetization sau. Lợi ích: rút ngắn đường ra store,
giảm rủi ro bị từ chối, tập trung sửa lỗi độ tin cậy trước. `PaywallScreen` đã có sẵn
trong mã nguồn, chưa nối RevenueCat — giữ nguyên như vậy.

### P0-5. Test độ tin cậy trên nhiều hãng máy 🔴 1–2 tuần
**Hiện trạng:** mới chỉ chạy trên 1 emulator. Đây là yêu cầu cốt lõi của PRD và là
**phần có rủi ro cao nhất** vì có thể phát hiện lỗi làm hỏng toàn bộ công việc đã làm.

Ma trận bắt buộc (theo `REQUIREMENTS.md`):
- Xiaomi/POCO — MIUI/HyperOS (nghi vỡ thất bại nhiều nhất)
- Samsung — One UI (Deep Sleeping Apps)
- Oppo/Realme — ColorOS
- Vivo — FuntouchOS
- iPhone — iOS 16, 17, 18

Ca biên phải kiểm tra:
- Khởi động lại máy → báo thức còn không (đã sửa `exported` + registry, **chưa test thật**)
- Máy khóa màn hình → chuông kêu toàn màn hình
- App bị hệ thống dọn → báo thức còn kêu
- Đổi múi giờ (bay nước ngoài) → lịch tính lại đúng
- Đổi giờ hệ thống
- Tắt nguồn / cắm sạc

Ghi lại tỉ lệ chuông đúng giờ theo giây lệch. Đây là số liệu cần cho ASO.

### P0-6. Bản build release chạy thật 🟡 ĐÃ LÀM MỘT PHẦN
Bản release (R8 + không có `SKIP_LOGIN_FOR_SCREENSHOTS`) đã build và chạy thật trên
API 37. Việc này **phát hiện 2 lỗi chỉ có ở bản release** — xem `confirm.md` H2.1:
app kẹt vĩnh viễn ở màn loading, và `shrinkResources` xoá sạch 12 file âm thanh.

Còn lại:
- [ ] Chạy lại **toàn bộ ca kiểm thử P0-5** trên bản release thay vì bản debug
      (đặc biệt: chuông có reo đúng giờ không khi R8 đã tối ưu)
- [ ] Xác nhận lần build phát hành thật **không kèm** `SKIP_LOGIN_FOR_SCREENSHOTS`

---

## P1 — Vận hành & trải nghiệm

### P1-1. Theme sáng 🟡 2–3 ngày
`main.dart` hardcode `AppTheme.darkTheme`. Ảnh nền tối khó nổi bật trong store listing,
và nhiều người dùng ghét nền tối cho app báo thức.
Thêm `ThemeMode.system` hoặc tuỳ chọn trong Cài đặt.

### P1-2. Hoàn thiện ảnh store 🟡 1–2 ngày
Đã có 6/8 ảnh thật. Còn:
- Màn tạo/sửa báo thức, màn nhiệm vụ toán → chụp trên máy thật
- **Thêm chữ đè lên ảnh** theo kịch bản trong `SCREENSHOT_PLAN.md`
- Chụp thêm cho App Store (iPhone 6.9" 1320×2868, iPad 13" 2064×2752)
- Làm **icon 512×512** và **feature graphic 1024×500**
- Nên làm trên nền sáng sau P1-1

### P1-3. Monetization: RevenueCat 🟡 3–5 ngày
`PaywallScreen` đã có giao diện nhưng **chưa nối RevenueCat**, chưa tạo sản phẩm.
Cần:
- Tạo sản phẩm trên Google Play Console + App Store Connect
- Nối `purchases_flutter`
- Xác thực bên server (webhook RevenueCat) — **không được** tin cờ `isPro` cục bộ
- Viết nội dung Paywall đúng quy định Apple (nêu rõ giá, thời hạn, cách huỷ)

> ⚠️ Trì hoãn được: nếu muốn launch nhanh, **giai đoạn đầu phát hành miễn phí 100%**
> rồi thêm IAP ở bản cập nhật sau. Rút ngắn được ~1 tuần.

### P1-4. Dọn tài nguyên rỗng 🟡 30 phút
`assets/images/` và `assets/fonts/` **rỗng** nhưng đã khai báo trong `pubspec.yaml`.
Hoặc thêm nội dung, hoặc bỏ khai báo.

### P1-5. Sửa `getMissedAlarms` trả rỗng trên iOS 🟡 1–2 ngày
Hiện iOS luôn trả danh sách rỗng vì không thể chạy code sau khi chuỗi notification
hết. Hệ quả: **thống kê "bỏ lỡ" sẽ luôn bằng 0 trên iOS**.
Cách khả thi: coi một chuỗi đã hết mà Dart không ghi nhận tương tác nào là bỏ lỡ,
khi app mở lại.

---

## P2 — Chất lượng & bền vững

### P2-1. CI/CD 🟢 2–3 ngày
Chưa có `.github/`. Dùng Codemagic (chuyên cho Flutter) hoặc GitHub Actions:
- build AAB + IPA mỗi lần merge
- chạy test tự động
- R8 shrink kiểm tra file âm thanh còn không

### P2-2. Test Kotlin cho `NextOccurrenceCalculator` 🟢 1–2 ngày
Thuật toán đã mirror Dart và Dart đã test kỹ, nhưng **bản Kotlin chưa từng chạy**.
Cần unit test với tham số cố định để chắc chắn hai bên không lệch nhau.

### P2-3. Test iOS cho logic reschedule 🟢 1–2 ngày
Sau khi có macOS.

### P2-4. Nghe thử 12 âm thanh 🟢 30 phút
Kỹ thuật đã đạt 12/12 nhưng **chưa ai nghe**. Cần đánh giá cảm quan, đặc biệt
nhịp độ của `radar` và `siren`.

### P2-5. Video giải trình cho reviewer 🟢 1 ngày
Google có thể từ chối app báo thức nếu không giải thích rõ vì sao cần
`SCHEDULE_EXACT_ALARM` và `USE_FULL_SCREEN_INTENT`. Chuẩn bị sẵn video 30–60 giây.

### P2-6. Trang "Kiểm tra sức khoẻ báo thức" 🟢 2–3 ngày
`REQUIREMENTS.md` F-10 yêu cầu. Cũng là bằng chứng giúp chứng minh độ tin cậy cho
reviewer.

---

## Việc KHÔNG cần làm trước khi launch

Để tránh tốm thời gian, những việc sau **có thể để sau**:

- Theo dõi giấc ngủ bằng AI, phân tích chu kỳ ngủ
- Spotify / Apple Music
- QR scanner, shake-to-wake, đi bộ
- E2EE cloud sync
- Thống kê nợ ngủ
- Báo lại qua SMS/call dự phòng (Ultra)

Đã ghi rõ trong `store/ASO_METADATA.md` là "sắp có" để không vi phạm chính sách store.

---

## Lộ trình đề xuất

### Tuần 1 — Gỡ chặn kỹ thuật
| Ngày | Việc |
|------|------|
| 1 | P0-1 Signing + R8 + build AAB |
| 2 | P0-3 Firebase |
| 3 | P0-4 Privacy Policy + ToS |
| 4–5 | P0-6 Build release, chạy thử |

### Tuần 2 — Độ tin cậy (phần rủi ro cao nhất)
| Ngày | Việc |
|------|------|
| 1–3 | P0-5 Test Xiaomi, Samsung |
| 4–5 | P0-5 Test Oppo, Vivo |
| 6–7 | Bản iOS build được và test iPhone (P0-2) |

### Tuần 3 — Hoàn thiện & tài liệu
| Ngày | Việc |
|------|------|
| 1–2 | P1-1 Theme sáng |
| 3 | P1-2 Ảnh store + chữ đè |
| 4 | Icon + feature graphic |
| 5–7 | P1-3 Monetization *(hoặc bỏ nếu muốn launch sớm)* |

### Tuần 4 — Submit
| Ngày | Việc |
|------|------|
| 1–2 | Hoàn thiện metadata, chuẩn bị video reviewer |
| 3 | Submit lên Google Play Internal Test |
| 4–5 | TestFlight iOS |
| 6–7 | Sửa theo phản hồi, staged rollout 10% |

---

## Rủi ro cần nói thẳng

| Rủi ro | Mức | Xử lý |
|--------|------|-------|
| Chưa test iOS lần nào | 🔴 Cao | Cần macOS. Nếu không có, **launch Android trước** |
| Độ tin cậy trên MIUI | 🔴 Cao | Nhiều app báo thức hỏng ở đây. Test sớm, đừng để tới cuối |
| Reviewer từ chối vì alarm permission | 🟡 Vừa | Chuẩn bị video giải trình |
| Firebase chưa cấu hình → không có dữ liệu crash | 🟡 Vừa | Làm P0-3 sớm |
| Apple review chận vì khai sai Data Safety | 🟡 Vừa | Đối chiếu kỹ với hành vi thật |
| Ảnh nền tối giảm tỉ lệ tải | 🟢 Thấp | Làm P1-1 |

**Khuyến nghị chiến lược:** nếu thiếu macOS hoặc thiếu thời gian, **phát hành Android
trước** (đã build được, đã chạy thật), rồi làm iOS song song. Đừng để iOS chặn
toàn bộ.

---

## Checklist submit

- [ ] Đã build & ký bản release thật
- [ ] R8 đã bật, file âm thanh còn sau shrink
- [ ] Đã test độ tin cậy ≥ 99.5% trên Xiaomi, Samsung, Oppo, Vivo
- [ ] Privacy Policy + ToS đã publish
- [ ] Data Safety / App Privacy khớp hành vi thật
- [ ] Firebase Crashlytics hoạt động
- [ ] Đủ ảnh chụp đúng kích thước từng store
- [ ] Icon 512×512, feature graphic 1024×500
- [ ] Mô tả không chứa tính năng chưa có
- [ ] Có video giải trình cho reviewer
- [ ] Đã xin Critical Alerts (nếu muốn chuông vượt Silent Mode)
- [ ] Bản release build KHÔNG có `SKIP_LOGIN_FOR_SCREENSHOTS`
- [ ] Đã chạy trên thiết bị thật (không phải emulator)