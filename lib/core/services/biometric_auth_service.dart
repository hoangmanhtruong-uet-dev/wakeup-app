import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra xem thiết bị có hỗ trợ vân tay/Face ID không
  static Future<bool> isBiometricSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Thực hiện quét sinh trắc học để mở khóa (Ví dụ: Nhật ký Giấc ngủ)
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Vui lòng xác thực bằng Vân tay/Face ID để mở khóa bảo mật.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Không cho phép dùng mã PIN (Đảm bảo bảo mật cao nhất)
        ),
      );
    } catch (e) {
      debugPrint('Lỗi xác thực sinh trắc học: $e');
      return false;
    }
  }
}
