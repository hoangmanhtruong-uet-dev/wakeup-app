import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service quản lý khóa mã hóa CSDL SQLite (SQLCipher).
///
/// Khóa được sinh ngẫu nhiên theo thiết bị và lưu trữ an toàn trong:
/// - Android: Android Keystore
/// - iOS: iOS Keychain
///
/// Truy cập đến khóa này chỉ được thực hiện khi khởi tạo Database.
/// Tuyệt đối không hardcode khóa vào mã nguồn.
class EncryptionKeyService {
  static const String _dbKeyName = 'wakeup_db_encryption_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Lấy khóa mã hóa đã lưu, hoặc sinh khóa mới nếu chưa có.
  static Future<String> getKey() async {
    final existing = await _storage.read(key: _dbKeyName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // Sinh khóa ngẫu nhiên 32 ký tự (dùng cho AES-256)
    final newKey = _generateRandomKey();
    await _storage.write(key: _dbKeyName, value: newKey);
    return newKey;
  }

  static String _generateRandomKey() {
    const chars =
        'AaBbCcDdEeFf0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
