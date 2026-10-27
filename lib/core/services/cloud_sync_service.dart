import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';

class CloudSyncService {
  static final _supabase = Supabase.instance.client;

  /// Đẩy (Push) danh sách báo thức từ SQLite Local lên Supabase Cloud
  static Future<void> pushAlarmsToCloud(List<Alarm> localAlarms) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Chưa đăng nhập, từ chối đồng bộ Cloud.');
      return;
    }

    // Ở bản chính thức, cần áp dụng thuật toán E2EE (End-to-End Encryption) 
    // để mã hóa dữ liệu trước khi đẩy lên. Ở đây demo cấu trúc Payload.
    final List<Map<String, dynamic>> payload = localAlarms.map((alarm) => {
      'local_id': alarm.id,
      'user_id': user.id,
      'hour': alarm.hour,
      'minute': alarm.minute,
      'repeat_days': alarm.repeatDays,
      'is_enabled': alarm.enabled,
      'label': alarm.label ?? '',
      'vibrate': alarm.vibrate,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();

    try {
      // Upsert: Cập nhật nếu đã tồn tại, thêm mới nếu chưa có
      await _supabase.from('alarms').upsert(payload);
      debugPrint('Đồng bộ lên Cloud thành công!');
    } catch (e) {
      debugPrint('Lỗi đồng bộ Cloud: $e');
    }
  }

  /// Kéo (Pull) dữ liệu từ Cloud về máy mới
  static Future<List<dynamic>> pullAlarmsFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('alarms')
          .select()
          .eq('user_id', user.id);
      
      debugPrint('Kéo dữ liệu từ Cloud thành công: ${response.length} báo thức');
      return response as List<dynamic>;
    } catch (e) {
      debugPrint('Lỗi kéo dữ liệu từ Cloud: $e');
      return [];
    }
  }
}
