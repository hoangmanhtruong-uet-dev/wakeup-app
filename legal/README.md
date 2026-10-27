# Tài liệu pháp lý — trước khi submit Google Play

## Đã viết

| File | Nội dung |
|------|----------|
| `PRIVACY_POLICY.md` | Chính sách quyền riêng tư (tiếng Việt) |
| `TERMS_OF_SERVICE.md` | Điều khoản sử dụng (tiếng Việt) |

Cả hai được viết dựa trên **mã nguồn thật**, không phải mẫu chung. Xem mục
"Đối chiếu với mã nguồn" bên dưới.

---

## ⚠️ Việc còn phải làm trước khi submit

### 1. Điền thông tin liên hệ 🔴 BẮT BUỘC

Hai chỗ đang để trống, không điền thì tài liệu không dùng được:

- `PRIVACY_POLICY.md` mục 9 → email hỗ trợ
- `TERMS_OF_SERVICE.md` mục 13 → email hỗ trợ + website

Dùng email **không phải** email cá nhân — Play yêu cầu email có thể nhận và trả lời
được sau vài tháng.

### 2. Đăng lên một URL công khai 🔴 BẮT BUỘC

Google Play **không** chấp nhận file trong repo. Cần một URL truy cập được **không cần
đăng nhập**:

1. Tạo repo public (GitHub Pages, Cloudflare Pages, Netlify — miễn phí)
2. Đặt file `.md` ở gốc public
3. Dán URL vào Play Console → **Policy → Privacy policy**

Kiểm tra trước khi submit: mở URL bằng cửa sổ ẩn danh (incognito), phải thấy nội dung.

### 3. Viết bản tiếng Anh 🔴 KHI CÓ NGUỒN SỐ NGƯỜI DÙNG

Hiện mới có tiếng Việt. Nếu listing trên Play Store bằng tiếng Anh thì policy cũng
nên có bản tiếng Anh. Nếu bán riêng cho thị trường Việt thì tiếng Việt là đủ.

### 4. Điền biểu mẫu Data Safety cho khớp 🔴 BẮT BUỘC

Trong Play Console, khai báo Data Safety phải **khớp** với policy. Dựa trên mã nguồn
hiện tại:

| Câu hỏi Data Safety | Trả lời |
|--------------------|---------|
| Ứng dụng có thu thập hoặc chia sẻ dữ liệu người dùng không? | **Có** |
| Dữ liệu được mã hoá khi truyền? | **Có** (HTTPS) |
| Người dùng có thể yêu cầu xoá dữ liệu không? | **Có** |
| Dữ liệu nào? | Tên, email, Mã định danh người dùng, Thông tin ứng dụng, Địa chỉ email, Hoạt động trong ứng dụng |
| Mục đích? | Quản lý ứng dụng, Tương tác ứng dụng |
| Có bán hoặc chia sẻ cho bên thứ ba không? | **Không** |
| Có thu thập theo dõi quảng cáo không? | **Không** |

**Không khai dữ liệu âm thanh / báo thức** trong Data Safety — chúng nằm hoàn toàn
trên máy và không rời thiết bị.

---

## Đối chiếu với mã nguồn

Mỗi khẳng định trong policy đều được kiểm tra trước khi viết:

| Khẳng định trong policy | Cách xác minh |
|------------------------|---------------|
| "Dữ liệu báo thức không rời khỏi máy" | `cloud_sync_service.dart` có **không có call site** — grep toàn bộ `lib/` |
| "Mixpanel chưa thu thập gì" | `Mixpanel.init("YOUR_MIXPANEL_TOKEN")` + `AnalyticsService.` chỉ xuất hiện 1 lần trong `main.dart`, không có `trackEvent` nào được gọi |
| "Crashlytics chưa bật" | logcat thiết bị: `Default FirebaseApp failed to initialize because no default options were found` |
| "Không có quảng cáo" | `pubspec.yaml` không có `google_mobile_ads` hay SDK quảng cáo nào |
| Danh sách 9 quyền | đọc thẳng `android/app/src/main/AndroidManifest.xml` |
| "Không yêu cầu vị trí / danh bạ / ảnh / micro" | manifest không có — đối chiếu với danh sách 9 quyền ở trên |

### 🔴 Phải cập nhật policy nếu các điều sau xảy ra

Đây là những thay đổi sẽ khiến policy thành **không đúng**:

1. **Đưa `CloudSyncService` vào sử dụng** → dữ liệu báo thức sẽ lên máy chủ
2. **Điền token Mixpanel thật** và gọi `trackEvent` → sẽ thu thập dữ liệu sử dụng
3. **Cấu hình Firebase thật** → Crashlytics sẽ thu thập log lỗi và thông tin thiết bị
4. **Thêm quảng cáo hoặc theo dõi**

Sau khi bất kỳ điều nào ở trên được làm, cập nhật cả `PRIVACY_POLICY.md` **và** biểu mẫu
Data Safety trên Play Console.

---

## Lưu ý về tính năng "Gợi ý bảo mật E2EE"

`cloud_sync_service.dart` có ghi chú TODO về mã hoá đầu-cuối. Nếu bật tính năng đồng bộ,
ghi chú đó cần được xử lý trước — và policy phải mô tả cơ chế mã hoá thực tế. Không nên
tuyên bố E2EE nếu chưa có.