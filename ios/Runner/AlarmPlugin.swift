import Flutter
import UIKit
import UserNotifications

/// Xử lý MethodChannel phía Dart cho hệ thống báo thức — **bản iOS tương đương của
/// `MainActivity.kt` bên Android**.
///
/// Channel: `com.wakeup.app/alarm`
///
/// Vì sao dùng `FlutterPlugin` thay vì tạo `FlutterMethodChannel` trực tiếp trong
/// `AppDelegate`? Vì template Flutter mới (3.47+) đã chuyển sang vòng đời UIScene,
/// `AppDelegate` không còn giữ `window.rootViewController` để lấy `binaryMessenger`.
/// Cơ chế `registrar(forPlugin:)` là API ổn định, được chính `GeneratedPluginRegistrant`
/// dùng, nên hoạt động chắc chắn trên mọi phiên bản.
public class AlarmPlugin: NSObject, FlutterPlugin {

    /// Báo thức đang được mở từ thông báo, chờ Dart đọc qua `getInitialAlarmPayload`.
    private static var pendingAlarmId: Int?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AlarmPlugin()

        let channel = FlutterMethodChannel(
            name: "com.wakeup.app/alarm",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)

        AlarmScheduler.registerCategories()
        UNUserNotificationCenter.current().delegate = instance

        NSLog("[WakeUp] AlarmPlugin đã đăng ký trên iOS")
    }

    // MARK: - MethodChannel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {

        case "scheduleAlarm":
            guard let id = args["id"] as? Int else {
                return result(FlutterError(code: "INVALID_ARGUMENT",
                                           message: "Thiếu tham số id", details: nil))
            }
            guard let millis = args["timeInMillis"] as? Int else {
                return result(FlutterError(code: "INVALID_ARGUMENT",
                                           message: "Thiếu tham số timeInMillis", details: nil))
            }

            let label = args["label"] as? String ?? "Báo thức"
            let soundId = args["soundId"] as? String

            // Đặc tả lặp lại. iOS không tự lập lịch lại được sau khi chuông vang, nên
            // dùng 3 giá trị này để hẹn TRƯỚC nhiều lần kêu tương lai.
            let hour = args["hour"] as? Int ?? 0
            let minute = args["minute"] as? Int ?? 0
            let repeatDays = args["repeatDays"] as? Int ?? 0

            // Thời gian tự dừng chuông (F-07): quyết định độ dài chuỗi notification.
            let autoStopMinutes = args["autoStopMinutes"] as? Int ?? 10

            // Kế hoạch phân bổ hạn mức 64 notification, do Dart tính sẵn.
            let chainLength = args["chainLength"] as? Int ?? 10
            let futureCount = args["futureCount"] as? Int ?? 0

            let fireAt = Date(timeIntervalSince1970: Double(millis) / 1000.0)
            AlarmScheduler.scheduleAlarm(
                alarmId: id,
                label: label,
                hour: hour,
                minute: minute,
                repeatDays: repeatDays,
                fireAt: fireAt,
                soundId: soundId,
                autoStopMinutes: autoStopMinutes,
                chainLength: chainLength,
                futureCount: futureCount
            )
            result(true)

        case "cancelAlarm":
            guard let id = args["id"] as? Int else {
                return result(FlutterError(code: "INVALID_ARGUMENT",
                                           message: "Thiếu tham số id", details: nil))
            }
            // Huỷ TOÀN BỘ (chuỗi + các lần kêu tương lai) — dùng khi người dùng
            // tắt hoặc xoá báo thức.
            AlarmScheduler.cancelAlarm(alarmId: id)
            result(true)

        case "stopRinging":
            AlarmAudioPlayer.stop()
            if let id = args["id"] as? Int {
                // Chỉ dừng phần chuỗi đang reo, GIỮ các lần kêu tương lai đã hẹn trước.
                // Nếu xóa cả lịch định kỳ thì báo thức sẽ chỉ kêu được đúng một lần.
                AlarmScheduler.cancelChainRemainder(alarmId: id)
            }
            result(true)

        case "startRinging":
            // Chỉ có tác dụng thực sự trên iOS: phát chuông lặp sau khi app đã mở
            // RingingScreen (vì notification bị giới hạn ~30s).
            let soundId = args["soundId"] as? String ?? "alarm_default"
            let volume = Float(args["volume"] as? Double ?? 1.0)

            // Tự dừng sau autoStopMinutes để không reo vô hạn (F-07).
            let autoStopMinutes = args["autoStopMinutes"] as? Int ?? 10
            AlarmAudioPlayer.start(
                soundId: soundId,
                volume: volume,
                durationSeconds: TimeInterval(autoStopMinutes * 60)
            )
            result(true)

        case "getMissedAlarms":
            // iOS KHÔNG báo được báo thức bỏ lỡ.
            //
            // Lý do: phát hiện "chuông đã hết chuỗi mà không ai tương tác" đòi hỏi phải
            // chạy mã sau khi chuỗi notification kết thúc — mà iOS cấm dịch code nền.
            // Vì vậy ở đây luôn trả về danh sách rỗng; phía Dart tự ghi 'missed' khi
            // người dùng chủ động báo lại/thao tác sau khi chuông đã tắt.
            result([])

        case "requestNotificationPermission":
            AlarmScheduler.requestAuthorization { granted in
                result(granted)
            }

        case "getInitialAlarmPayload":
            let payload = AlarmPlugin.pendingAlarmId
            AlarmPlugin.pendingAlarmId = nil
            result(payload)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AlarmPlugin: UNUserNotificationCenterDelegate {

    /// Cho phép hiển thị notification ngay cả khi app đang ở foreground.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    /// Xử lý khi người dùng bấm notification hoặc bấm action Báo lại / Tắt.
    ///
    /// Lưu ý quan trọng: các action này có thể được bấm khi app **đang bị suspend**,
    /// tức là Dart KHÔNG chạy. Vì vậy mọi thao tác phải tự giải quyết tại native —
    /// tuyệt đối không gọi vòng qua MethodChannel trong trường hợp này.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let alarmId = userInfo[AlarmScheduler.payloadAlarmId] as? Int ?? -1
        let label = userInfo[AlarmScheduler.payloadLabel] as? String ?? ""
        let soundId = userInfo[AlarmScheduler.payloadSoundId] as? String

        switch response.actionIdentifier {

        case AlarmScheduler.snoozeActionId:
            guard alarmId != -1 else { completionHandler(); return }

            AlarmAudioPlayer.stop()
            // Dừng phần chuỗi đang reo, nhưng giữ nguyên lịch định kỳ.
            AlarmScheduler.cancelChainRemainder(alarmId: alarmId)

            // Báo lại chỉ là một lần kêu BỔ SUNG — không thay thế lịch định kỳ.
            let snoozeAt = Date().addingTimeInterval(
                TimeInterval(AlarmScheduler.defaultSnoozeMinutes * 60)
            )
            AlarmScheduler.scheduleSnoozeChain(
                alarmId: alarmId,
                label: label,
                soundId: soundId,
                fireAt: snoozeAt
            )

        case AlarmScheduler.dismissActionId, UNNotificationDismissActionIdentifier:
            AlarmAudioPlayer.stop()
            if alarmId != -1 {
                // Dừng chuông nhưng giữ lịch định kỳ để báo thức vẫn kêu ở lần sau.
                AlarmScheduler.cancelChainRemainder(alarmId: alarmId)
            }

        default:
            // Bấm vào thân notification -> mở app tới RingingScreen.
            if alarmId != -1 {
                AlarmPlugin.pendingAlarmId = alarmId
            }
        }

        completionHandler()
    }
}