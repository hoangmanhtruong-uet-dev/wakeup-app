import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Getter an toàn truy cập Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Kiểm tra xem Supabase đã sẵn sàng và có phiên đăng nhập hợp lệ chưa
  static bool get isLoggedIn {
    try {
      return client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// Khởi chạy quy trình Đăng nhập bằng Google qua OAuth
  static Future<bool> signInWithGoogle() async {
    // Chuyển hướng người dùng sang trình duyệt để đăng nhập Google.
    // Khi thành công, Supabase sẽ redirect về 'com.wakeup.app://login-callback' 
    // và app sẽ bắt deep link này để hoàn thiện session.
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.wakeup.app://login-callback',
    );
  }

  /// Khởi chạy quy trình Đăng nhập bằng Apple
  static Future<bool> signInWithApple() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.wakeup.app://login-callback',
    );
  }

  /// Lấy thông tin User hiện tại đang đăng nhập
  static User? getCurrentUser() {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Đăng xuất khỏi thiết bị
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('[WakeUp] Lỗi khi đăng xuất Supabase: $e');
    }
  }

  /// Xóa tài khoản người dùng:
  /// 1. Gọi RPC `delete_user_account` trên Supabase (xóa trong auth.users)
  /// 2. Đăng xuất khỏi SDK Supabase
  static Future<bool> deleteAccount() async {
    try {
      // Gọi RPC phía backend để xóa user hiện tại khỏi auth.users
      await client.rpc('delete_user_account');
      debugPrint('[WakeUp] Đã gửi yêu cầu xoá tài khoản qua RPC thành công');
    } catch (e) {
      // Nếu backend chưa triển khai RPC này (hoặc mạng lỗi),
      // ghi nhận log nhưng vẫn tiếp tục luồng đăng xuất để không chặn Full Wipe cục bộ.
      debugPrint('[WakeUp] Gọi RPC delete_user_account thất bại (hoặc chưa cấu hình RPC trên backend): $e');
    }

    try {
      await signOut();
      return true;
    } catch (e) {
      debugPrint('[WakeUp] Lỗi signOut sau khi xóa tài khoản: $e');
      return false;
    }
  }
}
