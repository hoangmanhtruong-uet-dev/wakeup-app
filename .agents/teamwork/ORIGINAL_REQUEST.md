# Original User Request

## 2026-10-18T19:38:16Z

Hoàn thiện toàn bộ các tính năng cốt lõi (EPIC 2), xử lý các màn hình mock/hẹn giờ (EPIC 3 - Phương án A), chuẩn hóa Monetization & Pháp lý (EPIC 4), cấu hình hạ tầng Crashlytics/Analytics & dọn lint (EPIC 5), và đóng gói tài nguyên App Icon/Store Assets (EPIC 6) cho ứng dụng báo thức WakeUp+.

Working directory: d:/MyProjects/Medium-project/app/app_clock
Integrity mode: development

## Verification Resources
- Bộ unit tests tự động: thư mục test/ (hiện có 49 bài test đã pass).
- Công cụ tĩnh phân tích mã nguồn: flutter analyze.
- Trình chạy kiểm thử: flutter test.

## Requirements

### R1. Khắc phục lỗi cập nhật báo thức & Tùy biến Nhiệm vụ thức dậy (EPIC 2)
- Khi người dùng chỉnh sửa một báo thức đã có (giờ, phút, ngày lặp, nhãn) và bấm Lưu, hệ thống phải cập nhật bản ghi trong CSDL SQLite và gọi Native Alarm Engine để đặt lại lịch báo thức trên hệ điều hành.
- Bổ sung trường cấu hình nhiệm vụ thức dậy (missionEnabled, missionType, missionDifficulty) vào bảng Alarms trong CSDL SQLite và giao diện edit_alarm_screen.dart (cung cấp Switch bật/tắt và chọn độ khó).
- Tại màn hình đổ chuông (ringing_screen.dart), kiểm tra cấu hình của báo thức: chỉ yêu cầu giải toán nếu missionEnabled == true; nếu false, cho phép người dùng tắt chuông ngay lập tức.

### R2. Hoàn thiện Bộ đếm Hẹn giờ & Tinh gọn Giao diện MVP (EPIC 3 - Phương án A)
- Màn hình Hẹn giờ (Timer): Thay thế thời gian 15 phút cố định bằng bộ chọn thời lượng linh hoạt (Giờ, Phút, Giây). Khi đếm ngược về 0, phát âm thanh báo + rung và gửi thông báo hệ thống.
- Tinh gọn giao diện v1.0 (Phương án A): Tạm ẩn 2 tab "Giờ thế giới" và "Âm thanh giấc ngủ" khỏi thanh điều hướng chính (MainNavigationScreen) để tránh lỗi Incomplete Features (Apple Guideline 2.1).

### R3. Chuẩn hóa Monetization & Pháp lý (EPIC 4)
- Khởi tạo RevenueCat SDK trong main.dart an toàn (sử dụng khối try-catch để không crash app nếu chưa có API Key thật).
- Xử lý các nút "Nâng cấp ngay" và "Khôi phục giao dịch (Restore)" trong PaywallScreen: gọi SDK thật kèm xử lý ngoại lệ đầy đủ, không để văng lỗi unhandled exception.
- Thêm liên kết mở trình duyệt tới Chính sách quyền riêng tư (Privacy Policy) và Điều khoản sử dụng (EULA) tại chân màn hình PaywallScreen.

### R4. Cấu hình Hạ tầng & Làm sạch mã nguồn (EPIC 5)
- Cấu hình Firebase Crashlytics và Mixpanel an toàn bằng biến môi trường --dart-define hoặc cấu hình dự phòng (no-op khi thiếu token), không để cứng token rác trong code.
- Rà soát và thay thế toàn bộ các API đã deprecated của Flutter trên toàn bộ dự án, đưa flutter analyze về 0 cảnh báo.

### R5. Tạo Tài nguyên Đồ họa & Chuẩn bị Store (EPIC 6)
- Cấu hình và chạy package flutter_launcher_icons để tự động tạo bộ App Icon chính thức của WakeUp+ cho Android (res/mipmap-*) và iOS (AppIcon.appiconset), thay thế icon mặc định của Flutter.
- Chuẩn bị đầy đủ thư mục ảnh chụp màn hình Store cho các kích thước quy định.

## Acceptance Criteria

### Core Logic & User Experience
- [ ] Báo thức cũ sau khi chỉnh sửa lưu thành công vào SQLite và chuông vang đúng giờ mới.
- [ ] Báo thức không bật Mission tắt được chuông ngay tại ringing_screen.dart; chỉ báo thức có bật Mission mới yêu cầu giải toán.
- [ ] Không còn bất kỳ nút bấm hoặc màn hình nào trên UI dẫn tới // TODO hoặc tính năng giả lập không hoạt động.
- [ ] Bộ đếm Timer chọn được thời gian tùy ý và phát âm thanh + rung khi về 0.
- [ ] Các thao tác trên Paywall không bao giờ gây crash app.
- [ ] Ứng dụng cài đặt hiển thị đúng App Icon chính thức thay vì logo mặc định Flutter.

### Code Quality & Testing
- [ ] Toàn bộ unit tests hiện có tiếp tục PASS 100% và có bổ sung unit tests cho hàm updateAlarm.
- [ ] Lệnh flutter analyze trả về No issues found!.
- [ ] Lệnh flutter test chạy thành công toàn bộ test suite.
