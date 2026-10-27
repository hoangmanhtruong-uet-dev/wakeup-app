import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _buildHeroIcon(IconData iconData, Color badgeColor) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(iconData, size: 48, color: AppTheme.primary),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bgMain, width: 3),
              ),
              child: const Icon(Icons.flash_on, size: 16, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.cyan, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(4, (index) {
                      bool isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  Text(
                    '0${_currentPage + 1} / 04',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildSlide1(),
                  _buildSlide(
                    icon: Icons.notifications_active,
                    title: 'Cho phép gửi thông báo',
                    subtitle: 'Báo thức cần thông báo để đánh thức bạn ngay cả khi máy khóa.',
                    btnText: 'Cho phép',
                    onPrimaryPressed: () async {
                      await Permission.notification.request();
                      _nextPage();
                    },
                    items: [
                      _buildInfoItem(Icons.shield, 'Đảm bảo không bỏ lỡ', 'Đánh thức chính xác từng giây'),
                      _buildInfoItem(Icons.alarm, 'Snooze thông minh', 'Tương tác trực tiếp ngay trên màn hình'),
                    ],
                  ),
                  _buildSlide(
                    icon: Icons.gps_fixed,
                    title: 'Báo thức chính xác',
                    subtitle: 'Bắt buộc từ Android 12 trở lên để báo thức reo đúng giờ.',
                    btnText: 'Cấp quyền',
                    onPrimaryPressed: () async {
                      await Permission.scheduleExactAlarm.request();
                      _nextPage();
                    },
                    items: [
                      _buildInfoItem(Icons.timer, 'Đổ chuông đúng giây', 'Hệ thống sẽ ưu tiên tiến trình'),
                    ],
                  ),
                  _buildSlide(
                    icon: Icons.battery_charging_full,
                    title: 'Giữ báo thức hoạt động',
                    subtitle: 'Loại trừ tối ưu pin để báo thức luôn an toàn.',
                    btnText: 'Cho phép chạy nền',
                    onPrimaryPressed: () async {
                      await Permission.ignoreBatteryOptimizations.request();
                      _nextPage();
                    },
                    items: [
                      _buildInfoItem(Icons.security, 'Độ tin cậy 99.9%', 'Đảm bảo chuông reo đúng giờ'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Khung chung cho mọi trang onboarding.
  ///
  /// ## Vì sao không dùng `Column` + `Spacer()` như trước?
  /// `Spacer` là con flex, nên chiều cao nó chiếm là phần dư của khung chứ không phải
  /// phần dư của nội dung. Khi màn hình THẤP (xoay ngang, chia đôi màn hình, máy
  /// nhỏ) tổng chiều cao các widget cố định vượt quá khung -> `RenderFlex overflowed`,
  /// người dùng thấy sọc vàng-đen và mất nút bấm.
  ///
  /// Cách sửa: nội dung giữa nằm trong vùng cuộn, nút bấm ghim cố định ở đáy.
  /// Màn hình cao vẫn hiển thị y hệt bố cục cũ (nội dung căn giữa nhờ
  /// `MainAxisAlignment.center` + `minHeight`), màn hình thấp thì cuộn thay vì vỡ.
  Widget _slideScaffold({
    required List<Widget> content,
    required List<Widget> footer,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: content,
                  ),
                ),
              ),
            ),
          ),
          ...footer,
        ],
      ),
    );
  }

  Widget _buildSlide1() {
    return _slideScaffold(
      content: [
        _buildHeroIcon(Icons.alarm, AppTheme.cyan),
        const SizedBox(height: 40),
        const Text('Báo thức luôn kêu đúng giờ',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text(
            'Chỉ mất 1 phút để thiết lập và đảm bảo báo thức không bao giờ bị hệ thống chặn.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildFeatureCard(Icons.psychology, 'AI Chống ngủ', AppTheme.primary),
            const SizedBox(width: 10),
            _buildFeatureCard(Icons.verified, '100% Đúng giờ', AppTheme.cyan),
            const SizedBox(width: 10),
            _buildFeatureCard(Icons.nights_stay, 'Dịu mắt đêm', AppTheme.primary),
          ],
        ),
      ],
      footer: [
        _buildPrimaryButton('Bắt đầu', _nextPage),
        TextButton(
          onPressed: _nextPage,
          child: const Text('Bỏ qua thiết lập', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildSlide({required IconData icon, required String title, required String subtitle, required String btnText, required List<Widget> items, VoidCallback? onPrimaryPressed}) {
    return _slideScaffold(
      content: [
        _buildHeroIcon(icon, AppTheme.primary),
        const SizedBox(height: 40),
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(children: items),
        ),
      ],
      footer: [
        _buildPrimaryButton(btnText, onPrimaryPressed ?? _nextPage),
        TextButton(
          onPressed: _nextPage,
          child: const Text('Để sau', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}
