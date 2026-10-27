import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/native_alarm_service.dart';
import '../data/repositories/alarm_repository_provider.dart';
import '../features/alarms/presentation/ringing_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/presentation/main_navigation_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

/// Cờ chỉ dùng khi chụp ảnh cho store.
///
/// `bool.fromEnvironment` được đọc lúc **BIÊN DỊCH**, không mở được lúc chạy, nên
/// người dùng không thể tự bật. Bản release phải build **không** kèm cờ này.
///
/// Cách dùng:
///     flutter run --dart-define=SKIP_LOGIN_FOR_SCREENSHOTS=true
const bool _skipLoginForScreenshots =
    bool.fromEnvironment('SKIP_LOGIN_FOR_SCREENSHOTS');

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  bool _isLoggedIn = false;
  bool _isGuestMode = false;
  bool _isAlarmRinging = false;
  int _ringingAlarmId = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mỗi lần app quay lại foreground, lập lại lịch cho toàn bộ báo thức đang bật.
    //
    // Vì sao cần? Lịch ở tầng OS có thể bị mất ngoài dự kiến (người dùng dọn app,
    // hệ thống buộc dừng tiến trình, hoặc native chưa kịp tự lấy lại sau lần kêu).
    // Lập lại ở đây là lưới an toàn cuối cùng và rẻ (chỉ vài bản ghi SQLite).
    if (state == AppLifecycleState.resumed) {
      _rearmAlarms();
    }
  }

  Future<void> _rearmAlarms() async {
    try {
      final repo = ref.read(alarmRepositoryProvider);

      // Đồng bộ các báo thức bị bỏ lỡ trước, để lịch sử không bị sót.
      final missed = await repo.syncMissedAlarms();
      if (missed > 0) {
        debugPrint('[WakeUp] Đã ghi nhận $missed báo thức bị bỏ lỡ.');
      }

      final count = await repo.rearmEnabledAlarms();
      debugPrint('[WakeUp] Đã lập lại lịch cho $count báo thức.');
    } catch (e) {
      debugPrint('[WakeUp] Lập lại lịch thất bại: $e');
    }
  }

  Future<void> _checkInitialState() async {
    bool hasSeenOnboarding = false;
    bool isLoggedIn = false;
    bool isGuestMode = false;
    bool isRinging = false;
    int ringingId = -1;

    // ⚠️ Hàm này được gọi từ initState mà KHÔNG await. Nếu một Future ở đây ném lỗi
    // hoặc treo vô hạn, app sẽ KẸT VĨNH VIỄN ở màn hình loading — không crash,
    // không log, người dùng chỉ thấy ứng dụng không phản ứng.
    //
    // Đây không phải chuyện giả định: đã quan sát đúng triệu chứng đó ở bản release
    // khi truy cập Supabase thất bại. Vì vậy:
    //   1. Mỗi nhánh có try/catch riêng — lỗi ở nhánh này không được chặn nhánh khác.
    //   2. Có timeout cho từng lời gọi.
    //   3. setState luôn được gọi, kể cả khi thất bại.
    //
    // Các timeout bên dưới đều là lệnh LOCAL (SharedPreferences, MethodChannel)
    // chứ không phải gọi mạng — bình thường chạy trong vài mili giây. Timeout ở đây
    // chỉ để chặn trường hợp xấu: native side treo thì app không bị kẹt vĩnh viễn.
    // Tổng thời gian tệ nhất trước khi thoát màn loading là 5 + 5 + 5 = 15 giây.
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      isGuestMode = prefs.getBool('isGuestMode') ?? false;
    } catch (e) {
      debugPrint('[WakeUp] Đọc SharedPreferences thất bại: $e');
    }

    // Check Supabase Auth.
    // Nếu Supabase chưa khởi tạo được (mất mạng, config sai) thì `Supabase.instance`
    // ném lỗi — tuyệt đối không để lỗi này chặn việc dựng UI.
    try {
      isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    } catch (e) {
      debugPrint('[WakeUp] Supabase chưa sẵn sàng, coi như chưa đăng nhập: $e');
      isLoggedIn = false;
    }

    // Xin quyền gửi thông báo (bắt buộc với iOS — không có quyền thì báo thức không kêu).
    // Trên Android đây là no-op (dùng cơ chế POST_NOTIFICATIONS của permission_handler).
    try {
      await NativeAlarmService.requestNotificationPermission()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[WakeUp] Xin quyền thông báo thất bại: $e');
    }

    // Check Alarm Payload: app có được mở bởi thao tác bấm notification không?
    try {
      final alarmId = await NativeAlarmService.getInitialAlarmPayload()
          .timeout(const Duration(seconds: 5));
      if (alarmId != null && alarmId != -1) {
        isRinging = true;
        ringingId = alarmId;
      }
    } catch (e) {
      debugPrint('No alarm payload: $e');
    }

    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = hasSeenOnboarding;
      _isLoggedIn = isLoggedIn;
      _isGuestMode = isGuestMode;
      _isAlarmRinging = isRinging;
      _ringingAlarmId = ringingId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_isAlarmRinging) {
      return RingingScreen(alarmId: _ringingAlarmId, label: 'Đến giờ rồi!');
    }

    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    if (!_isLoggedIn && !_isGuestMode && !_skipLoginForScreenshots) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}