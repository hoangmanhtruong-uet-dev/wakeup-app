# Thiết kế kỹ thuật (Technical Design)

Tài liệu này mô tả kiến trúc kỹ thuật của dự án WakeUp+ dựa trên tài liệu kế hoạch.

## 1. Kiến trúc tổng thể
Ứng dụng sử dụng kiến trúc lai (hybrid) để đảm bảo trải nghiệm người dùng mượt mà và tính tin cậy tuyệt đối của hệ thống báo thức:
- **UI & Logic (Cross-platform):** Flutter (Dart). Quản lý trạng thái bằng Riverpod hoặc Bloc.
- **Native Modules (Android/iOS):** Xử lý lập lịch báo thức, phát âm thanh, hiển thị màn hình đổ chuông và các tương tác hệ thống sâu. (Viết bằng Kotlin cho Android và Swift cho iOS thông qua Platform Channels).
- **Lưu trữ cục bộ:** SQLite (Drift) hoặc Isar.

## 2. Mô hình dữ liệu
- **Alarm:** `id`, `hour`, `minute`, `repeatDays` (bitmask), `enabled`, `label`, `soundId`, `volume`, `rampSeconds`, `vibrate`, `snoozeMinutes`, `snoozeMax`, `autoStopMinutes`, `skipNextDate`, `createdAt`, `updatedAt`.
- **AlarmEvent:** Lịch sử đổ chuông (`id`, `alarmId`, `scheduledAt`, `firedAt`, `action`, `snoozeCount`) -> Xóa sau 90 ngày.
- **Timer:** `id`, `durationSeconds`, `label`, `endsAt`, `state`.
- **Settings:** `theme`, `use24h`, `weekStart`, `language`, `defaultSnooze`, `defaultVolume`.
- **DismissTask (v1.1):** `id`, `alarmId`, `type`, `difficulty`, `config`.

## 3. Thuật toán tính thời điểm kích hoạt
Cần có Unit Test bao phủ mọi trường hợp:
1. Lấy thời điểm hiện tại `now` theo múi giờ máy.
2. Không lặp: Nếu giờ đã qua -> chuyển sang ngày mai.
3. Có lặp: Quét 8 ngày tới, tìm ngày đầu tiên hợp lệ trong `repeatDays`.
4. Kiểm tra `skipNextDate` và giờ mùa hè.
5. Chuyển thành epoch (thời gian tuyệt đối) để đăng ký xuống Native OS. Cập nhật lại khi đổi múi giờ/khởi động máy.

## 4. Chi tiết nền tảng Native

### Android
- **Lập lịch:** Sử dụng `AlarmManager.setAlarmClock()` (hoặc `setExactAndAllowWhileIdle()`). Xin quyền báo thức chính xác (từ Android 12+).
- **Khôi phục (Boot):** Đăng ký `BroadcastReceiver` cho các action `BOOT_COMPLETED`, `LOCKED_BOOT_COMPLETED`, `TIMEZONE_CHANGED`, `TIME_SET`.
- **Đổ chuông:** Sử dụng `Foreground Service` kèm notification ưu tiên cao. Dùng `USAGE_ALARM` cho âm thanh, giữ WakeLock ngắn.
- **Khóa màn hình:** Dùng Full-screen intent từ thông báo (chú ý quyền Android 14+).
- **Tối ưu pin:** Xây dựng hướng dẫn loại trừ ứng dụng khỏi danh sách tối ưu pin của các hãng (Xiaomi, Oppo, Samsung, v.v.). Bỏ qua chế độ Do Not Disturb (Khai báo loại ALARM).

### iOS
- **Hạn chế chạy nền:** Không thể chạy tiến trình tùy ý. Sử dụng thông báo cục bộ (Local Notifications) để kích chuông.
- **Chuỗi thông báo:** Đặt liên tiếp các thông báo cách nhau 30s (do giới hạn độ dài âm thanh iOS) để chuông kêu liên tục.
- **AlarmKit:** Cân nhắc sử dụng AlarmKit (iOS 26+) hoặc `Critical Alerts` entitlement.
- **Màn hình mở app:** Khi app đang ở foreground, dùng `AVAudioSession` để phát âm thanh mà không bị ngắt.
