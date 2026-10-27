import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class AnalyticsService {
  static late Mixpanel _mixpanel;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Khởi tạo Mixpanel (Gắn cục bộ ở main.dart)
  static Future<void> init() async {
    const token = String.fromEnvironment('MIXPANEL_TOKEN');
    if (token.isEmpty || token == 'YOUR_MIXPANEL_TOKEN') {
      _isInitialized = false;
      debugPrint('[Analytics] MIXPANEL_TOKEN chưa được cấu hình. Chạy ở chế độ no-op an toàn.');
      return;
    }

    if (_isInitialized) return;
    
    try {
      _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: true);
      _isInitialized = true;
      debugPrint('Mixpanel Analytics đã sẵn sàng.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('Lỗi khởi tạo Mixpanel: $e');
    }
  }

  /// Reset trạng thái (dùng cho testing hoặc đăng xuất)
  static void reset() {
    if (_isInitialized) {
      try {
        _mixpanel.reset();
      } catch (_) {}
    }
    _isInitialized = false;
  }

  /// Ghi nhận 1 sự kiện bất kỳ (Ví dụ: Bấm Tắt Báo Thức, Mua Gói Ultra)
  static void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (!_isInitialized) return;
    _mixpanel.track(eventName, properties: properties);
  }

  /// Định danh người dùng sau khi họ đăng nhập qua Supabase
  static void identifyUser(String userId) {
    if (!_isInitialized) return;
    _mixpanel.identify(userId);
  }

  /// Gán Profile cho người dùng (Ví dụ: Khách hàng VIP)
  static void setUserProperties(Map<String, dynamic> properties) {
    if (!_isInitialized) return;
    for (var entry in properties.entries) {
      _mixpanel.getPeople().set(entry.key, entry.value);
    }
  }
}

