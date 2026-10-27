# Quy tắc làm việc cho AI Agent (Agent Rules)

Tệp này định nghĩa các quy tắc cốt lõi mà AI Agent (Antigravity/Gemini) phải tuân thủ khi viết mã, đề xuất thiết kế, hoặc gỡ lỗi cho dự án báo thức **WakeUp+**.

## 1. Nguyên tắc tối thượng: ĐỘ TIN CẬY
- **Không bao giờ hi sinh độ tin cậy:** Báo thức PHẢI kêu đúng giờ. Mọi đoạn code liên quan đến lập lịch (`AlarmManager` trên Android, `UNUserNotificationCenter` trên iOS) phải được viết cẩn thận, bắt mọi ngoại lệ (Exception), và có cơ chế fallback.
- **Phân tách trách nhiệm rõ ràng:** Flutter chỉ làm UI và tính toán logic. Toàn bộ việc kích hoạt báo thức đúng giờ, hiển thị màn hình chuông khi màn hình tắt, và phát âm thanh phải được xử lý ở Native (Kotlin/Swift). **Tuyệt đối không dùng thư viện Flutter pub.dev thuần túy** cho việc đổ chuông báo thức nếu thư viện đó không đảm bảo chạy nền 100%.

## 2. Quy tắc viết mã Flutter (Dart)
- Sử dụng phiên bản Dart và Flutter mới nhất (có null safety).
- **Quản lý trạng thái:** Ưu tiên sử dụng `Riverpod` (hoặc `Bloc` nếu người dùng yêu cầu). Tách biệt rõ ràng tầng UI, Provider/State, và Repository/Domain.
- **Lưu trữ:** Sử dụng `Drift` (SQLite) hoặc `Isar`. Mọi thao tác I/O phải là bất đồng bộ (async).
- **Platform Channels:** Viết mã rõ ràng, định nghĩa các phương thức truyền nhận (MethodChannel, EventChannel) có kiểm tra kiểu dữ liệu (type check) và xử lý lỗi (try-catch) kỹ lưỡng.

## 3. Quy tắc viết mã Android (Kotlin)
- Mã nguồn nằm trong thư mục `/android/app/src/main/kotlin/`.
- Phải xử lý triệt để các hạn chế chạy nền (Background Execution Limits) và Doze Mode của Android.
- Bắt buộc dùng `AlarmManager.setAlarmClock` hoặc `setExactAndAllowWhileIdle` kết hợp với Foreground Service để báo thức.
- Xử lý quyền (Permissions) chu đáo, đặc biệt là `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, và `USE_FULL_SCREEN_INTENT` (từ Android 14+).

## 4. Quy tắc viết mã iOS (Swift)
- Mã nguồn nằm trong thư mục `/ios/Runner/`.
- Phải tính đến việc ứng dụng bị hệ điều hành đóng băng (suspended). Sử dụng `UNUserNotificationCenter` để lên lịch các Local Notification chứa âm thanh báo thức dài (hoặc lặp 30s).
- Tuân thủ chặt chẽ các giới hạn của Apple về âm thanh chạy nền và Focus Mode.

## 5. Kiểm thử (Testing)
- **Thuật toán tính giờ:** Bắt buộc phải viết Unit Test (Dart) rất dày đặc cho thuật toán tính thời điểm kích hoạt báo thức kế tiếp (xử lý múi giờ, giờ mùa hè, đổi ngày, v.v.).
- Khi thêm/sửa logic lập lịch, luôn yêu cầu/nhắc nhở viết thêm test case.

## 6. Giao tiếp và Đề xuất
- Khi đưa ra phương án giải quyết một vấn đề, luôn nhắc nhở người dùng về nguy cơ ảnh hưởng đến pin hoặc khả năng bị hệ điều hành "giết" (kill) tiến trình.
- Cung cấp các đoạn code có giải thích rõ ràng tại sao lại áp dụng cách đó (đặc biệt là với mã Native).
- **Luôn kiểm tra KIs (Knowledge Items)** hoặc các tệp `.md` trong thư mục gốc (`ARCHITECTURE.md`, `REQUIREMENTS.md`) để bám sát thiết kế trước khi thay đổi kiến trúc.
