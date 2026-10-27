import Foundation
import UserNotifications

/// Lập lịch báo thức trên iOS bằng Local Notification.
///
/// ## Vì sao không thể dùng AlarmManager kiểu Android?
/// iOS KHÔNG cho phép tiến trình ứng dụng chạy tùy ý trong nền. Kể cả khi app đã
/// bị "đóng băng" (suspended), quyền chạy nền cũng bị thu hồi. Vì vậy báo thức BẮT BUỘC
/// phải được kích hoạt bởi `UNUserNotificationCenter` — cơ chế duy nhất mà iOS bảo đảm
/// thực thi đúng giờ.
///
/// ## Vì sao phải HẸN TRƯỚC NHIỀU lần kêu thay vì chờ Dart reschedule?
/// Vì lý do trên, native không thể tự tính "lần kêu tiếp theo" khi chuông vang.
/// Nếu chỉ hẹn một lần thì báo thức sẽ kêu đúng một lần rồi im.
/// Giải pháp: mỗi lần Dart lập lịch, ta hẹn trước **nhiều lần kêu tương lai**.
/// Dart cũng gọi lại lập lịch mỗi khi app mở lên (rearm), nên cửa sổ này luôn được lấp đầy.
///
/// ## Vì sao âm thanh phải chia thành chuỗi?
/// iOS giới hạn âm thanh của một notification ở khoảng 30 giây. Nếu chỉ hẹn một
/// notification thì chuông tự tắt sau 30s dù người dùng chưa tắt báo thức.
enum AlarmScheduler {

    // MARK: - Hằng số

    static let channelId = "wakeup_alarm_channel"
    static let defaultSnoozeMinutes = 5

    /// Khoảng cách giữa hai notification liên tiếp: iOS giới hạn âm thanh của
    /// một notification ở khoảng 30 giây.
    static let chainInterval: TimeInterval = 30

    /// Trần cho chuỗi khi gọi nội bộ (luồng báo lại).
    ///
    /// Lưu ý: độ dài chuỗi cho báo thức chính KHÔNG dùng hằng số này — Dart tính sẵn
    /// qua `IosNotificationBudget` rồi truyền xuống, nhằm chia đều hạn mức 64
    /// giữa các báo thức.
    static let maxChainLength = 40

    /// iOS chỉ cho phép tối đa 64 notification đang chờ cho mỗi app.
    /// Vượt quá thì hệ thống sẽ từ chối notification mới.
    static let iOSPendingNotificationLimit = 64

    /// Tính độ dài chuỗi cho luồng báo lại (chỉ dùng nội bộ, không chia ngân sách).
    static func chainLength(autoStopMinutes: Int) -> Int {
        let needed = Int((Double(autoStopMinutes) * 60.0) / chainInterval)
        return max(1, min(needed, maxChainLength))
    }

    // MARK: - Action identifiers

    static let snoozeActionId = "WAKEUP_SNOOZE_ACTION"
    static let dismissActionId = "WAKEUP_DISMISS_ACTION"

    // MARK: - userInfo keys

    static let payloadAlarmId = "alarmId"
    static let payloadLabel = "label"
    static let payloadSoundId = "soundId"

    // MARK: - Category

    /// Phải gọi 1 lần trước khi schedule bất kỳ notification nào.
    static func registerCategories() {
        let snooze = UNNotificationAction(
            identifier: snoozeActionId,
            title: "Báo lại",
            options: [.authenticationRequired]
        )
        let dismiss = UNNotificationAction(
            identifier: dismissActionId,
            title: "Tắt",
            options: [.authenticationRequired]
        )
        let category = UNNotificationCategory(
            identifier: channelId,
            actions: [snooze, dismiss],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Xin quyền gửi thông báo. Không có quyền thì báo thức sẽ không kêu.
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            // `.timeSensitive` cho phép chuông vượt Focus Mode
            // (cần bật capability Time Sensitive Notifications trong Xcode).
            options: [.alert, .sound, .badge, .timeSensitive]
        ) { granted, error in
            if let error = error {
                NSLog("[WakeUp] Xin quyền thông báo thất bại: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Hủy

    /// Hủy toàn bộ notification thuộc về `alarmId`.
    ///
    /// Cố tình KHÔNG dùng `removeAllPendingNotificationRequests()` — hàm đó sẽ xóa
    /// luôn các báo thức khác đang được lập lịch.
    static func cancelAlarm(alarmId: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let targets = requests
                .filter { ($0.content.userInfo[payloadAlarmId] as? Int) == alarmId }
                .map { $0.identifier }
            guard !targets.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: targets)
            NSLog("[WakeUp] Đã hủy \(targets.count) notification của báo thức \(alarmId)")
        }
    }

    /// Huỷ phần chuỗi còn ĐANG CHỜ reo (chuỗi của báo thức chính), nhưng GIỮ NGUYÊN các
    /// lần kêu tương lai đã hẹn trước (`_next_`).
    ///
    /// Gọi khi người dùng bấm "Tắt" hoặc "Báo lại" — nếu không, chuông sẽ tiếp tục reo
    /// do các notification còn sót trong chuỗi.
    static func cancelChainRemainder(alarmId: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let targets = requests
                .filter { request in
                    guard let id = request.content.userInfo[payloadAlarmId] as? Int,
                          id == alarmId else { return false }
                    return request.identifier.contains("_chain_")
                }
                .map { $0.identifier }
            guard !targets.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: targets)
            NSLog("[WakeUp] Đã dừng chuỗi còn sói của báo thức \(alarmId) (\(targets.count) notification)")
        }
    }

    /// Hẹn một chuỗi "báo lại" ngắn, KHÔNG đụng tới lịch định kỳ.
    ///
    /// Dùng cho action "Báo lại" trên notification: báo lại chỉ là một lần kêu bổ sung,
    /// không phải lịch định kỳ — nên tuyệt đối không gọi [scheduleAlarm] ở đây vì hàm đó
    /// sẽ xóa toàn bộ notification của báo thức rồi hẹn lại.
    static func scheduleSnoozeChain(
        alarmId: Int,
        label: String,
        soundId: String?,
        fireAt: Date
    ) {
        let center = UNUserNotificationCenter.current()

        // Xóa chuỗi báo lại cũ (nếu có) để không dồn chuông.
        center.getPendingNotificationRequests { requests in
            let stale = requests
                .filter { $0.identifier.contains("_snoozechain_") }
                .map { $0.identifier }
            if !stale.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: stale)
            }

            self.scheduleChain(
                center: center,
                alarmId: alarmId,
                label: label,
                soundId: soundId,
                fireAt: fireAt,
                chainPrefix: "snoozechain",
                length: chainLength(autoStopMinutes: defaultSnoozeMinutes * 3)
            )
        }
    }

    // MARK: - Lập lịch

    /// Lập lịch cho một báo thức.
    ///
    /// - Parameters:
    ///   - alarmId: id trong SQLite.
    ///   - hour / minute / repeatDays: đặc tả lặp lại, dùng để tính các lần kêu tương lai.
    ///     `repeatDays == 0` nghĩa là báo thức một lần → chỉ hẹn một chuỗi, không lặp.
    ///   - fireAt: thời điểm kêu gần nhất (đã tính sẵn ở Dart).
    static func scheduleAlarm(
        alarmId: Int,
        label: String,
        hour: Int,
        minute: Int,
        repeatDays: Int,
        fireAt: Date,
        soundId: String? = nil,
        autoStopMinutes: Int = 10,
        chainLength: Int = 10,
        futureCount: Int = 0
    ) {
        let center = UNUserNotificationCenter.current()

        // Xóa lịch cũ của chính báo thức này trước khi hẹn lịch mới.
        //
        // GIỮ LẠI chuỗi "báo lại" (`_snoozechain_`): nếu xóa luôn, mỗi lần app quay
        // lại foreground (rearm) sẽ nuốt mất lần báo lại đang chờ.
        center.getPendingNotificationRequests { requests in
            let stale = requests
                .filter { request in
                    guard let id = request.content.userInfo[payloadAlarmId] as? Int,
                          id == alarmId else { return false }
                    return !request.identifier.contains("_snoozechain_")
                }
                .map { $0.identifier }
            if !stale.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: stale)
            }

            // 1. Chuỗi kêu liên tục cho lần kêu gần nhất.
            // `chainLength` do Dart tính sẵn (IosNotificationBudget) nhằm chia đều
            // hạn mức 64 notification giữa các báo thức.
            scheduleChain(
                center: center,
                alarmId: alarmId,
                label: label,
                soundId: soundId,
                fireAt: fireAt,
                chainPrefix: "chain",
                length: max(0, chainLength)
            )

            // 2. Hẹn trước các lần kêu tiếp theo (chỉ với báo thức lặp).
            if repeatDays != 0 && futureCount > 0 {
                scheduleFutureOccurrences(
                    center: center,
                    alarmId: alarmId,
                    label: label,
                    hour: hour,
                    minute: minute,
                    repeatDays: repeatDays,
                    soundId: soundId,
                    after: fireAt,
                    limit: futureCount
                )
            }
        }
    }

    /// Hẹn chuỗi notification liên tiếp để chuông kêu liên tục từ [fireAt].
    ///
    /// [chainPrefix] phân biệt chuỗi của báo thức chính với chuỗi "báo lại", để khi
    /// người dùng bấm "Báo lại" ta chỉ xóa phần đang reo mà không đụng tới các lần
    /// kêu tương lai đã hẹn trước.
    private static func scheduleChain(
        center: UNUserNotificationCenter,
        alarmId: Int,
        label: String,
        soundId: String?,
        fireAt: Date,
        chainPrefix: String,
        length: Int
    ) {
        let base = fireAt.timeIntervalSinceNow

        for index in 0..<max(1, length) {
            let content = makeContent(
                label: label, soundId: soundId, alarmId: alarmId
            )

            // QUAN TRỌNG: mỗi notification phải lệch nhau đúng chainInterval kể từ
            // thời điểm gốc. Nếu dùng interval cố định cho từng cái, các notification
            // sau sẽ kêu TRƯỚC notification đầu tiên (vì chúng tính từ "bây giờ").
            let offset = base + Double(index) * chainInterval
            let trigger: UNNotificationTrigger = offset <= 0
                ? UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                : UNTimeIntervalNotificationTrigger(timeInterval: offset, repeats: false)

            add(center: center,
                identifier: "\(channelId)_\(alarmId)_\(chainPrefix)_\(index)",
                content: content,
                trigger: trigger)
        }
    }

    /// Hẹn trước N lần kêu tiếp theo của báo thức lặp.
    private static func scheduleFutureOccurrences(
        center: UNUserNotificationCenter,
        alarmId: Int,
        label: String,
        hour: Int,
        minute: Int,
        repeatDays: Int,
        soundId: String?,
        after: Date,
        limit: Int
    ) {
        var cursor = after
        var scheduled = 0

        for index in 1...max(1, limit) {
            guard let next = nextOccurrence(after: cursor, hour: hour, minute: minute, repeatDays: repeatDays)
            else { break }

            let content = makeContent(label: label, soundId: soundId, alarmId: alarmId)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(next.timeIntervalSinceNow, 1),
                repeats: false
            )
            add(center: center,
                identifier: "\(channelId)_\(alarmId)_next_\(index)",
                content: content,
                trigger: trigger)

            cursor = next
            scheduled += 1
        }

        NSLog("[WakeUp] Báo thức \(alarmId): đã hẹn trước \(scheduled) lần kêu tương lai")
    }

    // MARK: - Tính lần kêu tiếp theo

    /// Trả về lần kêu kế tiếp SAU [reference] (ánh xạ 1-1 với `TimeUtils.nextOccurrenceAfter` bên Dart).
    ///
    /// - `repeatDays` là bitmask: 1=T2 ... 64=CN.
    /// - Trả về `nil` nếu báo thức một lần, hoặc không tìm thấy ngày hợp lệ.
    static func nextOccurrence(
        after reference: Date,
        hour: Int,
        minute: Int,
        repeatDays: Int
    ) -> Date? {
        guard repeatDays != 0 else { return nil }

        var cal = Calendar.current
        cal.timeZone = TimeZone.current

        // Ứng viên: đúng giờ phút đã cấu hình, trong ngày của reference.
        var comps = cal.dateComponents([.year, .month, .day], from: reference)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let candidate = cal.date(from: comps) else { return nil }

        // Bắt đầu từ NGÀY HÔM SAU: ngày vừa kêu rồi không được kêu lại.
        for dayOffset in 1...8 {
            guard let probe = cal.date(byAdding: .day, value: dayOffset, to: candidate) else {
                continue
            }
            let weekday = cal.component(.weekday, from: probe) // 1 = Chủ nhật ... 7 = Thứ 7
            if isDayInBitmask(weekday: weekday, bitmask: repeatDays) {
                var c = cal.dateComponents([.year, .month, .day], from: probe)
                c.hour = hour
                c.minute = minute
                c.second = 0
                return cal.date(from: c)
            }
        }
        return nil
    }

    /// Kiểm tra một ngày trong tuần có nằm trong bitmask không.
    ///
    /// Lưu ý phép ánh xạ dễ sai:
    /// - Dart `DateTime.weekday`: 1=T2 ... 7=CN  -> bit index = weekday - 1
    /// - Swift `Calendar.component(.weekday)`: 1=CN ... 7=T7
    ///
    /// Nên bit index = 6 cho Chủ nhật, còn lại là weekday - 2.
    static func isDayInBitmask(weekday: Int, bitmask: Int) -> Bool {
        let bitIndex = (weekday == 1) ? 6 : (weekday - 2)
        return (bitmask & (1 << bitIndex)) != 0
    }

    // MARK: - Private helpers

    private static func makeContent(
        label: String,
        soundId: String?,
        alarmId: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Báo thức" : label
        content.body = "Đến giờ rồi!"
        content.sound = resolveSound(named: soundId)
        content.categoryIdentifier = channelId
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            payloadAlarmId: alarmId,
            payloadLabel: label,
            payloadSoundId: soundId ?? "alarm_default",
        ]
        return content
    }

    private static func add(
        center: UNUserNotificationCenter,
        identifier: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { error in
            if let error = error {
                // Thường gặp khi vượt quá giới hạn 64 notification đang chờ.
                NSLog("[WakeUp] Không hẹn được \(identifier): \(error.localizedDescription)")
            }
        }
    }

    /// Chọn âm thanh cho notification.
    ///
    /// ## Giới hạn quan trọng
    /// iOS chỉ phát được âm thanh notification nếu file nằm trong **app bundle**.
    /// Asset trong `assets/` của Flutter KHÔNG nằm trong iOS bundle, nên
    /// `UNNotificationSound(named:)` trả về nil với hầu hết `soundId` -> rơi về `.default`.
    ///
    /// Muốn dùng nhạc chuông riêng, cần thêm file `.wav`/`.aiff` vào `ios/Runner/`
    /// rồi khai báo trong Xcode > "Copy Bundle Resources".
    private static func resolveSound(named soundId: String?) -> UNNotificationSound {
        let id = (soundId ?? "").trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, id != "default" else { return .default }

        for ext in ["wav", "aiff", "caf"] {
            let name = UNNotificationSoundName("\(id).\(ext)")
            if UNNotificationSound(named: name) != nil {
                return UNNotificationSound(named: name)
            }
        }
        NSLog("[WakeUp] Không tìm thấy file âm thanh '\(id)' trong bundle — dùng âm mặc định")
        return .default
    }
}