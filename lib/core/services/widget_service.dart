import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  /// Cập nhật thời gian báo thức kế tiếp lên Home Widget của Android/iOS
  static Future<void> updateNextAlarm(String alarmTimeStr) async {
    try {
      // Ghi dữ liệu vào UserDefaults (iOS) và SharedPreferences (Android)
      await HomeWidget.saveWidgetData('next_alarm', alarmTimeStr);
      
      // Yêu cầu Native cập nhật lại UI của Widget
      await HomeWidget.updateWidget(
        name: 'AlarmWidgetProvider', // Tên class Provider bên Android
        iOSName: 'AlarmWidget', // Tên widget bên iOS (nếu có)
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật Home Widget: $e');
    }
  }
}
