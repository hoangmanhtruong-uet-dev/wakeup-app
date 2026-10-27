# Chính sách Quyền riêng tư — WakeUp+

**Cập nhật lần cuối:** 18/10/2026
**Phiên bản ứng dụng:** 1.0.0

> Tài liệu này mô tả chính xác ứng dụng đang được phát hành. Mọi khẳng định bên dưới
> đã được đối chiếu với mã nguồn, không phải suông.

---

## 1. Tóm tắt ngắn

| | |
|---|---|
| Dữ liệu bạn nhập | Tên, Email, Mật khẩu |
| Dữ liệu ứng dụng tự tạo | Danh sách báo thức, lịch sử báo thức |
| Nơi lưu | **Trên máy bạn.** Không tải lên máy chủ. |
| Quảng cáo | **Không có.** Không SDK quảng cáo nào. |
| Bán dữ liệu cho bên thứ ba | **Không.** |
| Theo dõi quảng cáo xuyên ứng dụng | **Không.** |

**Dữ liệu báo thức của bạn — giờ, nhãn, ngày lặp, âm thanh, lịch sử bật/tắt — không bao
giờ rời khỏi điện thoại.** Chúng nằm trong cơ sở dữ liệu SQLite được mã hoá, khoá bảo
mã lưu trong Keystore (Android) / Keychain (iOS).

---

## 2. Dữ liệu ứng dụng thu thập

### 2.1. Dữ liệu bạn nhập tay

| Dữ liệu | Vì sao cần | Lưu ở đâu |
|----------|-----------|-----------|
| Họ tên | Hiển thị trong hồ sơ | Máy chủ (Supabase) |
| Địa chỉ email | Đăng nhập, khôi phục tài khoản | Máy chủ (Supabase) |
| Mật khẩu | Xác thực | Chỉ lưu dạng băm trên máy chủ — ứng dụng **không** lưu mật khẩu dạng rõ |

### 2.2. Dữ liệu ứng dụng tạo ra

| Dữ liệu | Vì sao cần | Lưu ở đâu |
|----------|-----------|-----------|
| Cấu hình báo thức (giờ, phút, ngày lặp, nhãn, âm thanh, âm lượng, rung, số lần báo lại) | Chức năng cốt lõi của ứng dụng | **Chỉ trên máy** |
| Lịch sử báo thức (đã bật / đã bỏ qua / đã tắt, số lần báo lại) | Thống kê tỉ lệ báo thức thành công | **Chỉ trên máy** |

> Mã nguồn có sẵn một tính năng đồng bộ lên đám mây (`cloud_sync_service.dart`), nhưng
> tính năng đó **chưa được bật trong phiên bản này** và sẽ không gửi dữ liệu đi đâu cho
> tới khi chúng tôi công bố rõ ràng trước.

### 2.3. Quyền ứng dụng yêu cầu

| Quyền | Mục đích | Có bắt buộc không |
|-------|----------|-----------------|
| `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` | Báo thức kêu **đúng giây** thay vì trễ vài phút | Không — nhưng app sẽ mất đúng tính năng chính |
| `POST_NOTIFICATIONS` | Hiện báo thức | Không |
| `WAKE_LOCK` | Giữ máy thức khi chuông đang reo | Không |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Chuông reo được khi bạn đang dùng ứng dụng khác | Không |
| `USE_FULL_SCREEN_INTENT` | Báo thức hiện lên màn hình khoá như cuộc gọi | Không |
| `RECEIVE_BOOT_COMPLETED` | Lập lại lịch báo thức sau khi khởi động lại máy | Không |
| `VIBRATE` | Rung khi báo thức | Không |

**Ứng dụng không yêu cầu và không truy cập:** vị trí, danh bạ, ảnh, micro, tin nhắn,
lịch sử cuộc gọi, hay ID quảng cáo.

---

## 3. Bên thứ ba

| Dịch vụ | Vai trò | Trạng thái |
|---------|---------|-----------|
| **Supabase** | Máy chủ xác thực và cơ sở dữ liệu tài khoản | **Đang dùng** — dữ liệu tài khoản |
| **Firebase Crashlytics** | Báo cáo lỗi ứng dụng | **Chưa bật** — không thu thập gì |
| **Mixpanel** | Thống kê sử dụng | **Chưa bật** — token chưa cấu hình, không thu thập gì |

Nếu bất kỳ dịch vụ nào ở trên được bật trong tương lai, chúng tôi sẽ **cập nhật trang này
trước khi** nó bắt đầu thu thập dữ liệu.

---

## 4. Bảo mật

- **Mã hoá khi lưu trữ:** cơ sở dữ liệu cục bộ dùng SQLCipher. Khoá mã hoá được sinh ra
  ngẫu nhiên và lưu trong Keystore của Android / Keychain của iOS — ứng dụng không thể
  đọc được dữ liệu nếu thiết bị bị khoá.
- **Mã hoá khi truyền:** mọi kết nối tới máy chủ đều qua HTTPS/TLS.
- **Không lưu mật khẩu** ở dạng rõ trên thiết bị.

> **Trung thực về giới hạn:** Không có ứng dụng nào bảo mật tuyệt đối. Nếu thiết bị của
> bạn bị phần mềm độc hại chiếm quyền, dữ liệu cục bộ có thể bị truy cập. Hãy giữ hệ
> điều hành và ứng dụng của bạn luôn cập nhật.

---

## 5. Quyền của bạn

Bạn có quyền:

- **Xem và sửa** thông tin tài khoản ngay trong ứng dụng.
- **Xoá tài khoản** — xoá trong ứng dụng, hoặc gửi email cho chúng tôi. Việc xoá tài
  khoản sẽ gỡ **toàn bộ** dữ liệu tài khoản trên máy chủ.
- **Xuất dữ liệu** của bạn dưới dạng JSON.
- **Rút lại sự đồng ý** bất cứ lúc nào.

Dữ liệu trên máy bạn bị xoá khi bạn gỡ ứng dụng — ứng dụng **không** tự thu thập dữ
liệu cá nhân của bạn cho bên thứ ba, vì vậy không có gì để thu hồi ngoài việc xoá tài
khoản.

---

## 6. Trẻ em

Ứng dụng dành cho người dùng từ 13 tuổi trở lên. Chúng tôi **không** cố ý thu thập dữ
liệu từ trẻ em dưới 13 tuổi. Nếu phát hiện dữ liệu như vậy, chúng tôi sẽ xoá ngay.

---

## 7. Quyền theo luật bảo vệ dữ liệu

Ứng dụng tuân thủ các nguyên tắc của GDPR (EU), UK GDPR và CCPA/CPRA (California).
Cụ thể:

- **Cơ sở xử lý:** thực hiện hợp đồng với bạn (để ứng dụng hoạt động) và lợi ích hợp
  pháp của chúng tôi (giữ ứng dụng an toàn).
- **Không bán, không chia sẻ** dữ liệu cho mục đích quảng cáo.
- **Không dùng dữ liệu nhạy cảm**, không dùng cho quyết định tự động, không đào tạo mô
  hình AI.
- **Không chuyển dữ liệu ra nước ngoài** (ngoài trừ hạ tầng kỹ thuật của nhà cung cấp).

---

## 8. Thay đổi chính sách

Chúng tôi có thể cập nhật trang này. Mọi thay đổi quan trọng sẽ được thông báo trong ứng
dụng trước khi có hiệu lực. Ngày cập nhật ghi ở đầu trang luôn là bản mới nhất.

---

## 9. Liên hệ

| | |
|---|---|
| Email | `<!-- điền email hỗ trợ của bạn -->` |
| Website | `<!-- điền URL website của bạn -->` |

---

## 10. Điều khoản bắt buộc của Google Play

Play Console yêu cầu URL chính sách quyền riêng tư **công khai, truy cập được không cần
đăng nhập**, và nội dung phải khớp với biểu mẫu Data Safety. Xem `legal/README.md`.