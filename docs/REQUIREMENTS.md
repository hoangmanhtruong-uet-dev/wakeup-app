# Yêu cầu sản phẩm (Product Requirements)

Dựa trên kế hoạch dự án WakeUp+, dưới đây là đặc tả các tính năng cho giai đoạn MVP và tương lai.

## 1. Đặc tả tính năng MVP (Mức độ ưu tiên P0/P1)
- **F-01 (P0) - Danh sách báo thức:** Liệt kê báo thức theo giờ tăng dần. Có công tắc bật/tắt. Vuốt để xóa.
- **F-02 (P0) - Tạo và sửa báo thức:** Chọn giờ, nhãn, ngày lặp, nhạc chuông, âm lượng, rung, báo lại.
- **F-03 (P0) - Quy tắc lặp:** Không lặp, hằng ngày, các ngày trong tuần, cuối tuần. Tính đúng thời điểm kế tiếp kể cả khi đổi giờ mùa hè.
- **F-04 (P0) - Âm thanh và rung:** 10-15 nhạc chuông, âm lượng riêng không phụ thuộc âm lượng nhạc (tăng dần). Âm dự phòng khi lỗi tệp.
- **F-05 (P0) - Báo lại (Snooze):** 1, 5, 10, 15, 20, 30 phút. Có bộ đếm ngược.
- **F-06 (P0) - Màn hình đổ chuông:** Toàn màn hình kể cả khi khóa máy. Hai hành động: Báo lại và Tắt (cách xa nhau, vuốt để tắt).
- **F-07 (P0) - Tự động tắt và bỏ lỡ:** Tự dừng chuông sau 10 phút nếu không tương tác, ghi nhận bỏ lỡ.
- **F-08 (P0) - Hẹn giờ đếm ngược:** Đặt giờ/phút/giây, tiếp tục chạy nền.
- **F-09 (P1) - Bấm giờ:** Ghi vòng (lap), chính xác 1/100 giây.
- **F-10 (P0) - Cài đặt chung:** Giao diện sáng/tối, định dạng 12/24h, trang "Kiểm tra sức khỏe báo thức".
- **F-11 (P0) - Hướng dẫn ban đầu và cấp quyền:** Giải thích và xin quyền (thông báo, báo thức chính xác, bỏ qua tối ưu pin). Có hướng dẫn riêng theo hãng máy (Xiaomi, Samsung...).
- **F-12 (P1) - Trợ năng và bản địa hóa:** Hỗ trợ cỡ chữ, trình đọc màn hình, tiếng Việt/Anh.

## 2. Quy tắc nghiệp vụ quan trọng
- **Múi giờ:** Lưu theo giờ địa phương, không phải thời điểm tuyệt đối. Đổi múi giờ -> kêu theo múi giờ mới.
- **Giờ mùa hè:** Bỏ qua giờ -> kêu ngay sau đó. Lặp lại -> chỉ kêu 1 lần.
- **Trùng giờ:** Gộp nhiều báo thức đổ chuông cùng lúc thành một lần.
- **Báo thức chồng chéo:** Báo thức mới ngắt báo thức cũ đang kêu.

## 3. Tính năng v1.1 và v2 (Tương lai)
- **v1.1:** Tác vụ tắt báo thức (Giải toán, Quét mã QR/mã vạch, Lắc máy, Chụp ảnh, Đi bộ), nhạc cá nhân, widget.
- **v2:** Sao lưu đồng bộ đám mây, báo thức theo lịch, thống kê thói quen, chia sẻ báo thức (Premium).

## 4. Yêu cầu phi chức năng
- **Độ tin cậy:** Tỉ lệ đổ chuông đúng giờ (sai lệch < 5s) đạt từ 99.5% trở lên.
- **Hiệu năng:** Khởi động nguội < 2s; màn hình đổ chuông hiện < 1s.
- **Pin:** Tiêu thụ < 1% pin/ngày khi chạy nền.
- **Dung lượng:** Bản cài đặt < 40MB.
- **Tương thích:** Android 8.0+ (API 26), iOS 16+.
