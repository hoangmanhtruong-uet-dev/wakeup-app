import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // Giao diện tĩnh tạm thời (0: PRO, 1: ULTRA). Ở bản thật sẽ fetch danh sách gói (Packages) từ RevenueCat
  int _selectedPackageIndex = 1;
  bool _isLoading = false;

  void _showFeedback(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _handleUpgrade() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      _showFeedback('Đang kết nối App Store/Google Play...');

      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering != null && currentOffering.availablePackages.isNotEmpty) {
        final packageIndex = _selectedPackageIndex < currentOffering.availablePackages.length
            ? _selectedPackageIndex
            : 0;
        final packageToBuy = currentOffering.availablePackages[packageIndex];
        final purchaseResult = await Purchases.purchase(PurchaseParams.package(packageToBuy));

        if (!mounted) return;

        if (purchaseResult.customerInfo.entitlements.active.isNotEmpty) {
          _showFeedback(
            'Nâng cấp thành công! Cảm ơn bạn đã ủng hộ WakeUp+.',
            backgroundColor: Colors.green,
          );
        } else {
          _showFeedback('Giao dịch hoàn tất nhưng gói chưa được kích hoạt.');
        }
      } else {
        _showFeedback('Dịch vụ mua hàng tạm thời không khả dụng hoặc đang ở chế độ thử nghiệm.');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _showFeedback('Giao dịch đã được hủy.');
      } else {
        _showFeedback('Dịch vụ mua hàng tạm thời không khả dụng hoặc đang ở chế độ thử nghiệm.');
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Dịch vụ mua hàng tạm thời không khả dụng hoặc đang ở chế độ thử nghiệm.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      _showFeedback('Đang khôi phục giao dịch...');

      final customerInfo = await Purchases.restorePurchases();

      if (!mounted) return;

      if (customerInfo.entitlements.active.isNotEmpty) {
        _showFeedback(
          'Đã khôi phục thành công các gói đã mua!',
          backgroundColor: Colors.green,
        );
      } else {
        _showFeedback('Không tìm thấy giao dịch nào trước đó.');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      debugPrint('[Paywall] Khôi phục thất bại (PlatformException): $e');
      _showFeedback('Dịch vụ khôi phục tạm thời không khả dụng hoặc chưa có giao dịch.');
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Paywall] Khôi phục thất bại: $e');
      _showFeedback('Không thể kết nối đến máy chủ thanh toán. Vui lòng thử lại sau.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openLegalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showFeedback('Không thể mở liên kết: $url');
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Không thể mở trình duyệt liên kết.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Mở Khóa Giấc Ngủ Hoàn Hảo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đầu tư cho giấc ngủ là khoản đầu tư sinh lời nhất của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Tính năng ưu việt
            _buildFeatureRow(Icons.music_note, 'Thư viện 50+ âm thanh thiên nhiên'),
            _buildFeatureRow(Icons.cloud_sync, 'Đồng bộ Cloud đa thiết bị (Mã hóa E2EE)'),
            _buildFeatureRow(Icons.analytics, 'Phân tích giấc ngủ chuyên sâu (90 ngày)'),
            _buildFeatureRow(Icons.no_cell, 'Trải nghiệm không quảng cáo (100%)'),
            
            const SizedBox(height: 32),

            // Các gói đăng ký (Tích hợp StoreKit/Google Play Billing)
            _buildPackageCard(0, 'WakeUp+ PRO', '\$17.99 / Năm', 'Tiết kiệm 50%'),
            const SizedBox(height: 16),
            _buildPackageCard(1, 'WakeUp+ ULTRA', '\$34.99 / Năm', 'Khuyên dùng'),
            
            const SizedBox(height: 32),

            // Nút thanh toán (Kích hoạt RevenueCat SDK)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                key: const Key('upgrade_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _handleUpgrade,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Nâng Cấp Ngay',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Restore Purchases - Bắt buộc bởi quy định Apple App Store
            TextButton(
              key: const Key('restore_button'),
              onPressed: _isLoading ? null : _handleRestore,
              child: const Text('Khôi phục giao dịch (Restore)', style: TextStyle(color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 16),

            // Legal Links (Apple App Store Guideline 3.1.2 & EULA requirements)
            _buildLegalLinks(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        TextButton(
          key: const Key('privacy_policy_link'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openLegalUrl('https://wakeup.app/privacy'),
          child: const Text(
            'Chính sách quyền riêng tư',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Text(
          '•',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        TextButton(
          key: const Key('terms_of_service_link'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openLegalUrl('https://wakeup.app/terms'),
          child: const Text(
            'Điều khoản sử dụng (EULA)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(int index, String title, String price, String badgeText) {
    final isSelected = _selectedPackageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackageIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.bgCard,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(color: AppTheme.primary, fontSize: 16)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
