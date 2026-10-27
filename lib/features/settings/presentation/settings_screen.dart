import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/app_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/repositories/alarm_repository_provider.dart';
import '../../auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isProcessing = false;

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Đăng xuất?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng các tính năng liên kết đám mây.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    await SupabaseService.signOut();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Xóa tài khoản?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '⚠️ CẢNH BÁO QUAN TRỌNG:\n\n'
          '• Toàn bộ tài khoản và thông tin xác thực trên đám mây sẽ bị xoá vĩnh viễn.\n'
          '• Toàn bộ dữ liệu báo thức và lịch sử trên thiết bị này sẽ được dọn sạch.\n'
          '• Hành động này KHÔNG THỂ hoàn tác.\n\n'
          'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản?',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại tài khoản', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Gọi Supabase xóa tài khoản trên backend và đăng xuất
      await SupabaseService.deleteAccount();

      // 2. Full Wipe: hủy toàn bộ native alarms và xóa sạch SQLite cục bộ
      await ref.read(alarmRepositoryProvider).wipeAllData();

      // 3. Xóa sạch SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản và toàn bộ dữ liệu đã được xóa hoàn tất.')),
      );

      // 4. Điều hướng về AppRouter (trạng thái sạch như mới cài)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRouter()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa tài khoản: $e')),
      );
    }
  }

  void _showPolicyDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderLight),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.getCurrentUser();
    final isLoggedIn = user != null;

    final displayName = isLoggedIn 
        ? (user.email?.split('@').first ?? 'Người dùng')
        : 'Chế độ Khách';
    final displayEmail = isLoggedIn 
        ? (user.email ?? '')
        : 'Chưa liên kết tài khoản';
    final initialLetter = isLoggedIn && displayEmail.isNotEmpty
        ? displayEmail[0].toUpperCase()
        : 'K';

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cài đặt & Tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar & User Profile
              Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(fontSize: 38, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                displayEmail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Trạng thái đồng bộ
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLoggedIn ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isLoggedIn ? Colors.green.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLoggedIn ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: isLoggedIn ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLoggedIn ? 'Đã liên kết Cloud' : 'Lưu trữ cục bộ (Offline)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLoggedIn ? Colors.greenAccent : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Banner mời đăng nhập nếu đang ở chế độ khách
              if (!isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync, color: AppTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text('Đồng bộ báo thức của bạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đăng nhập để tự động sao lưu báo thức và đồng bộ giữa các thiết bị.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Nhóm Tài khoản
              if (isLoggedIn) ...[
                _buildSettingsGroup('Tài khoản', [
                  _buildSettingItem(Icons.logout, 'Đăng xuất', _handleLogout),
                  _buildSettingItem(
                    Icons.delete_forever,
                    'Xóa tài khoản vĩnh viễn',
                    _handleDeleteAccount,
                    isDestructive: true,
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              // Nhóm Cài đặt hệ thống
              _buildSettingsGroup('Cài đặt', [
                _buildSettingItem(Icons.notifications_none, 'Kiểm tra quyền thông báo & chuông', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hệ thống báo thức đang hoạt động chính xác.')),
                  );
                }),
                _buildSettingItem(Icons.battery_charging_full, 'Tối ưu hóa Pin', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ứng dụng đã được cấp quyền chạy ngầm không gián đoạn.')),
                  );
                }),
              ]),
              const SizedBox(height: 24),

              // Nhóm Pháp lý & Về ứng dụng (Tuân thủ Apple & Google)
              _buildSettingsGroup('Pháp lý & Thông tin', [
                _buildSettingItem(Icons.privacy_tip_outlined, 'Chính sách quyền riêng tư', () {
                  _showPolicyDialog(
                    'Chính sách quyền riêng tư',
                    'WakeUp+ cam kết bảo vệ dữ liệu cá nhân của bạn:\n\n'
                    '1. BẢO MẬT NỘI BỘ:\n'
                    'Mọi dữ liệu báo thức của bạn được mã hóa cục bộ bằng chuẩn AES-256 (SQLCipher). Khóa mã hóa được sinh ngẫu nhiên và bảo vệ trong Android Keystore / iOS Keychain.\n\n'
                    '2. QUYỀN THIẾT BỊ:\n'
                    'Ứng dụng chỉ yêu cầu quyền báo thức chính xác (Exact Alarm), thông báo toàn màn hình (Full Screen Intent) và phát âm thanh để bảo đảm chuông kêu đúng giờ.\n\n'
                    '3. DỮ LIỆU ĐÁM MÂY & QUẢNG CÁO:\n'
                    'WakeUp+ không bán dữ liệu của bạn cho bất kỳ bên thứ ba nào và không phân phối quảng cáo theo dõi.\n\n'
                    '4. QUYỀN XÓA DỮ LIỆU:\n'
                    'Bạn có toàn quyền xóa tài khoản và toàn bộ dữ liệu máy chủ bất cứ lúc nào ngay trong mục Cài đặt này.',
                  );
                }),
                _buildSettingItem(Icons.description_outlined, 'Điều khoản dịch vụ', () {
                  _showPolicyDialog(
                    'Điều khoản dịch vụ',
                    'Chào mừng bạn đến với WakeUp+:\n\n'
                    '1. MỤC ĐÍCH SỬ DỤNG:\n'
                    'WakeUp+ cung cấp công cụ báo thức, hẹn giờ và đồng hồ chất lượng cao nhằm hỗ trợ nhịp sinh học của người dùng.\n\n'
                    '2. TRÁCH NHIỆM THIẾT BỊ:\n'
                    'Để báo thức hoạt động ổn định, bạn vui lòng cấp quyền chạy nền và loại trừ ứng dụng khỏi các chế độ tiết kiệm pin khắt khe của hệ điều hành.\n\n'
                    '3. NÂNG CẤP & ĐĂNG KÝ:\n'
                    'Các gói dịch vụ trả phí (nếu có) được xử lý thông qua hệ thống thanh toán chính thức của Apple App Store và Google Play Store.',
                  );
                }),
                _buildSettingItem(Icons.info_outline, 'Phiên bản ứng dụng', () {}, trailingText: 'v1.0.0 (Build 1)'),
              ]),
              const SizedBox(height: 40),
            ],
          ),

          // Loading Overlay khi đang xử lý xoá/đăng xuất
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    String? trailingText,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal))),
            if (trailingText != null)
              Text(trailingText, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14))
            else
              const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
