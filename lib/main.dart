import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/services/firebase_options.dart';
import 'core/services/analytics_service.dart';
import 'core/theme.dart';
import 'core/app_router.dart';

/// Khởi động Firebase và gắn bộ bắt lỗi toàn cục.
///
/// Trả về true nếu Crashlytics dùng được.
Future<bool> _initCrashReporting() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint('[Crashlytics] FIREBASE_API_KEY chưa được cấu hình. Bỏ qua Crashlytics, sử dụng error handler cục bộ an toàn.');
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    return true;
  } catch (e) {
    debugPrint('Firebase Init Error (Chưa có cấu hình thật): $e');
    return false;
  }
}

/// Khởi tạo RevenueCat an toàn với biến môi trường và timeout.
Future<void> _initRevenueCat() async {
  try {
    const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');
    if (apiKey.isEmpty) {
      debugPrint('[RevenueCat] REVENUECAT_API_KEY chưa được cấu hình. Chạy ở chế độ offline/mock an toàn.');
      return;
    }
    await Purchases.configure(PurchasesConfiguration(apiKey));
    debugPrint('[RevenueCat] Khởi tạo thành công.');
  } catch (e) {
    debugPrint('[RevenueCat] Khởi tạo thất bại: $e');
  }
}

/// Gắn bộ bắt lỗi toàn cục.
///
/// ⚠️ Hàm này PHẢI chạy bất kể Firebase có khởi tạo được hay không.
/// Trước đây việc gán nằm bên trong `try` của Firebase, nên khi Firebase lỗi
/// (đúng tình trạng hiện tại — chưa cấu hình project thật) thì `FlutterError.onError`
/// và `PlatformDispatcher.onError` KHÔNG BAO GIỜ được gán. Hệ quả: mọi lỗi UI và
/// lỗi bất đồng bộ rơi vào hư không, không ai biết app đang hỏng ở đâu.
void _installGlobalErrorHandlers({required bool crashlyticsAvailable}) {
  FlutterError.onError = (errorDetails) {
    FlutterError.presentError(errorDetails);
    if (crashlyticsAvailable) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (crashlyticsAvailable) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('[WakeUp] Lỗi bất đồng bộ (Crashlytics chưa sẵn sàng): $error');
    }
    // Trả false để lỗi vẫn hiện trong logcat thay vì bị nuốt.
    return false;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final crashlyticsAvailable = await _initCrashReporting();
  _installGlobalErrorHandlers(crashlyticsAvailable: crashlyticsAvailable);

  // Khởi tạo RevenueCat an toàn (offline/mock nếu chưa có API key)
  try {
    await _initRevenueCat().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[RevenueCat] Lỗi timeout hoặc khởi tạo RevenueCat: $e');
  }

  // Các bước khởi tạo sau chỉ là "đồ trang trí" — app vẫn phải chạy được nếu
  // chúng thất bại (dùng offline, Firebase chưa cấu hình, mạng yếu...).
  try {
    await AnalyticsService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Analytics init error: $e');
  }

  try {
    // Khởi tạo kết nối Supabase.
    //
    // ⚠️ PHẢI có timeout. `Supabase.initialize()` có thể đụng mạng/đọc phiên lưu trữ;
    // nếu nó treo, `await` này treo vô hạn và `runApp` không bao giờ được gọi —
    // người dùng chỉ thấy splash treo vĩnh viễn: không log, không crash.
    // Đã quan sát đúng triệu chứng này trên bản release.
    await Supabase.initialize(
      url: 'https://oigskpxhxbdpkkhznmko.supabase.co',
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pZ3NrcHhoeGJkcGtraHpubWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzNDI1MDQsImV4cCI6MjEwNzkxODUwNH0.PiLf5sTSRTHfKRLCNUaivm49blHCzDJBwYZgm6tge6o',
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Lỗi khởi tạo Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: WakeUpApp(),
    ),
  );
}

class WakeUpApp extends StatelessWidget {
  const WakeUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeUp+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
    );
  }
}