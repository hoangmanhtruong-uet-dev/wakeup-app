import AVFoundation
import AudioToolbox

/// Phát âm thanh báo thức LẶP LẠI khi ứng dụng đang chạy (foreground).
///
/// ## Vai trò
/// Notification của iOS chỉ kêu được ~30 giây. Khi người dùng bấm vào notification,
/// app được mở lên và hiển thị `RingingScreen`. Lúc này chính `AlarmAudioPlayer` giữ
/// vai trò phát chuông liên tục cho tới khi người dùng bấm "Tắt" hoặc "Báo lại".
///
/// ## Vì sao dùng category `.playback`?
/// `.playback` là category DUY NHẤT vẫn phát âm thanh khi công tắc Ring/Silent
/// đang ở chế độ im lặng. Nếu dùng `.ambient` (mặc định của nhiều app), chuông sẽ
/// bị tắt hoàn toàn khi người dùng gạt Silent — đúng điều một ứng dụng báo thức
/// KHÔNG được phép mắc lỗi.
///
/// ## Vì sao cần tự dừng?
/// Nếu không có [start\(soundId:volume:durationSeconds:)] với giới hạn thời gian,
/// chuông sẽ reo vô hạn khi người dùng không thao tác — hao pin và rất khó chịu.
/// Xem yêu cầu F-07 trong docs/REQUIREMENTS.md.
enum AlarmAudioPlayer {

    private static var player: AVAudioPlayer?
    private static var isConfigured = false

    /// Đếm số lần đã bắt đầu phát. Dùng để hủy đúng phiên phát đang chạy:
    /// khi có báo thức mới, phiên cũ đã bị thay thế và những callback `asyncAfter`
    /// của phiên cũ KHÔNG được tắt nhầm chuông mới.
    private static var generation = 0

    private static let fallbackName = "alarm_default"

    /// Bắt đầu phát chuông lặp trong tối đa [durationSeconds] giây.
    /// - Parameters:
    ///   - soundId: tên file âm thanh (không extension).
    ///   - volume: âm lượng 0.0 ... 1.0.
    ///   - durationSeconds: thời gian tự dừng. Truyền 0 hoặc âm để tắt cơ chế tự dừng.
    static func start(soundId: String, volume: Float, durationSeconds: TimeInterval) {
        stop()
        generation += 1
        let myGeneration = generation

        do {
            // `.duckOthers` để giảm nhẹ nhạc đang phát sẵn của người dùng.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            isConfigured = true

            guard let url = resolveSoundURL(soundId: soundId) else {
                // Không có file trong bundle -> phát âm báo mặc định của hệ thống.
                // (Âm này KHÔNG lặp lại và có thể bị tắt ở chế độ Silent.
                //  Đây chỉ là fallback; bản đúng đắn là bổ sung file .wav vào bundle.)
                NSLog("[WakeUp] Không tìm thấy file chuông '\(soundId)' — dùng âm hệ thống")
                AudioServicesPlayAlertSound()
                return
            }

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1 // -1 = lặp vô hạn cho tới khi gọi stop()
            newPlayer.volume = min(max(volume, 0.0), 1.0)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer

            NSLog("[WakeUp] Đang phát chuông: \(url.lastPathComponent) (tối đa \(Int(durationSeconds))s)")

            // Tự dừng sau durationSeconds (F-07).
            if durationSeconds > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) {
                    // Chỉ dừng nếu vẫn là cùng một phiên phát.
                    guard self.generation == myGeneration else { return }
                    NSLog("[WakeUp] Hết thời gian tự dừng — dừng chuông")
                    self.stop()
                }
            }

        } catch {
            NSLog("[WakeUp] Lỗi phát chuông: \(error.localizedDescription)")
        }
    }

    /// Dừng chuông và giải phóng audio session.
    static func stop() {
        generation += 1 // vô hiệu hoá mọi callback tự dừng đang chờ

        if let p = player {
            p.stop()
            p.currentTime = 0
        }
        player = nil

        if isConfigured {
            isConfigured = false
            // `notifyOthersOnDeactivation` để app khác (ví dụ Spotify) lấy lại audio.
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    /// Chuông có đang kêu hay không.
    static var isPlaying: Bool {
        return player?.isPlaying ?? false
    }

    // MARK: - Private

    /// Tìm file âm thanh trong bundle. Thử nhiều extension vì người dùng có thể
    /// dùng .wav / .mp3 / .m4a.
    private static func resolveSoundURL(soundId: String) -> URL? {
        let id = (soundId.isEmpty || soundId == "default") ? fallbackName : soundId
        for ext in ["wav", "mp3", "m4a", "aiff", "caf"] {
            if let url = Bundle.main.url(forResource: id, withExtension: ext) {
                return url
            }
        }
        // File chuông dự phòng: alarm_default.wav
        for ext in ["wav", "m4a", "mp3"] {
            if let url = Bundle.main.url(forResource: fallbackName, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}