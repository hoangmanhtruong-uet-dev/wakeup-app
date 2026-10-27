import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme.dart';
import '../../home/presentation/main_navigation_screen.dart';

class SystemPermissionGuideScreen extends StatefulWidget {
  const SystemPermissionGuideScreen({super.key});

  @override
  State<SystemPermissionGuideScreen> createState() => _SystemPermissionGuideScreenState();
}

class _SystemPermissionGuideScreenState extends State<SystemPermissionGuideScreen> {
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryOptIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _notificationGranted = await Permission.notification.isGranted;
    _exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    _batteryOptIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    setState(() {});
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationGranted = status.isGranted;
    });
  }

  Future<void> _requestExactAlarm() async {
    // Quyền báo thức chính xác (Exact Alarm) bắt buộc cho Android 12+
    final status = await Permission.scheduleExactAlarm.request();
    setState(() {
      _exactAlarmGranted = status.isGranted;
    });
  }

  Future<void> _requestBattery() async {
    // Yêu cầu vô hiệu hóa tối ưu pin (Battery Optimization)
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() {
      _batteryOptIgnored = status.isGranted;
    });
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _notificationGranted && _exactAlarmGranted && _batteryOptIgnored;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Cấp quyền hệ thống', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để WakeUp+ đảm bảo 100% báo thức sẽ kêu đúng giờ, bạn cần cấp các quyền sau. Nếu thiếu, hệ điều hành có thể sẽ tự động "tắt ngầm" báo thức của bạn lúc nửa đêm.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            _buildPermissionCard(
              title: 'Quyền Thông báo',
              description: 'Cần thiết để hiển thị trạng thái báo thức.',
              icon: Icons.notifications_active,
              isGranted: _notificationGranted,
              onRequest: _requestNotification,
            ),
            const SizedBox(height: 16),
            
            _buildPermissionCard(
              title: 'Báo thức Chính xác',
              description: 'Cho phép ứng dụng đánh thức điện thoại đúng từng giây (Android 12+).',
              icon: Icons.alarm_on,
              isGranted: _exactAlarmGranted,
              onRequest: _requestExactAlarm,
            ),
            const SizedBox(height: 16),
            
            _buildPermissionCard(
              title: 'Bỏ qua Tối ưu Pin',
              description: 'Ngăn chặn hệ điều hành tự động "giết" ứng dụng khi màn hình tắt để tiết kiệm pin.',
              icon: Icons.battery_charging_full,
              isGranted: _batteryOptIgnored,
              onRequest: _requestBattery,
            ),

            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allGranted ? AppTheme.primary : AppTheme.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: allGranted ? _finish : null,
                child: Text(
                  allGranted ? 'Hoàn tất & Bắt đầu' : 'Vui lòng cấp đủ quyền',
                  style: TextStyle(
                    color: allGranted ? Colors.black : AppTheme.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent,
          width: 1,
        )
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? AppTheme.primary : Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppTheme.primary, size: 28)
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onRequest,
              child: const Text('Cấp quyền'),
            ),
        ],
      ),
    );
  }
}
