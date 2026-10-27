import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakeup_app/features/monetization/presentation/paywall_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const urlChannel = MethodChannel('plugins.flutter.io/url_launcher');
  const purchasesChannel = MethodChannel('purchases_flutter');

  final List<MethodCall> urlCalls = <MethodCall>[];
  final List<MethodCall> purchasesCalls = <MethodCall>[];

  setUp(() {
    urlCalls.clear();
    purchasesCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlChannel, (MethodCall call) async {
      urlCalls.add(call);
      return true;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(purchasesChannel, (MethodCall call) async {
      purchasesCalls.add(call);
      if (call.method == 'getOfferings') {
        return <String, dynamic>{
          'all': <String, dynamic>{},
          'current': null,
        };
      }
      if (call.method == 'restorePurchases') {
        return <String, dynamic>{
          'entitlements': <String, dynamic>{
            'all': <String, dynamic>{},
            'active': <String, dynamic>{},
          },
          'activeSubscriptions': <String>[],
          'allPurchasedProductIdentifiers': <String>[],
          'nonSubscriptionTransactions': <dynamic>[],
          'firstSeen': '2026-01-01T00:00:00Z',
          'originalAppUserId': 'test_user',
          'requestDate': '2026-01-01T00:00:00Z',
          'originalApplicationVersion': '1.0',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(purchasesChannel, null);
  });

  void setupPhoneDisplay(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0; // 540 x 1200 logical pixels
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createPaywall() {
    return const MaterialApp(
      home: PaywallScreen(),
    );
  }

  group('PaywallScreen — UI Rendering & Layout', () {
    testWidgets('renders all headers, feature rows, package cards, CTA and legal links', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Mở Khóa Giấc Ngủ Hoàn Hảo'), findsOneWidget);
      expect(find.text('Đầu tư cho giấc ngủ là khoản đầu tư sinh lời nhất của bạn.'), findsOneWidget);

      // Feature rows
      expect(find.text('Thư viện 50+ âm thanh thiên nhiên'), findsOneWidget);
      expect(find.text('Đồng bộ Cloud đa thiết bị (Mã hóa E2EE)'), findsOneWidget);
      expect(find.text('Phân tích giấc ngủ chuyên sâu (90 ngày)'), findsOneWidget);
      expect(find.text('Trải nghiệm không quảng cáo (100%)'), findsOneWidget);

      // Packages
      expect(find.text('WakeUp+ PRO'), findsOneWidget);
      expect(find.text(r'$17.99 / Năm'), findsOneWidget);
      expect(find.text('Tiết kiệm 50%'), findsOneWidget);

      expect(find.text('WakeUp+ ULTRA'), findsOneWidget);
      expect(find.text(r'$34.99 / Năm'), findsOneWidget);
      expect(find.text('Khuyên dùng'), findsOneWidget);

      // Buttons & Links
      expect(find.byKey(const Key('upgrade_button')), findsOneWidget);
      expect(find.text('Nâng Cấp Ngay'), findsOneWidget);
      expect(find.byKey(const Key('restore_button')), findsOneWidget);
      expect(find.text('Khôi phục giao dịch (Restore)'), findsOneWidget);
      expect(find.byKey(const Key('privacy_policy_link')), findsOneWidget);
      expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
      expect(find.byKey(const Key('terms_of_service_link')), findsOneWidget);
      expect(find.text('Điều khoản sử dụng (EULA)'), findsOneWidget);
    });

    testWidgets('toggles package selection between PRO and ULTRA', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final proCard = find.text('WakeUp+ PRO');
      await tester.ensureVisible(proCard);
      await tester.tap(proCard);
      await tester.pumpAndSettle();

      final ultraCard = find.text('WakeUp+ ULTRA');
      await tester.ensureVisible(ultraCard);
      await tester.tap(ultraCard);
      await tester.pumpAndSettle();
    });

    testWidgets('close icon button pops screen', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Mở Khóa Giấc Ngủ Hoàn Hảo'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Mở Khóa Giấc Ngủ Hoàn Hảo'), findsNothing);
    });
  });

  group('PaywallScreen — Safe Unconfigured Purchase & Restore Handling', () {
    testWidgets('tapping Upgrade when RevenueCat is unconfigured shows safe feedback without crash', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final upgradeBtn = find.byKey(const Key('upgrade_button'));
      expect(upgradeBtn, findsOneWidget);

      await tester.ensureVisible(upgradeBtn);
      await tester.tap(upgradeBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Dịch vụ mua hàng tạm thời không khả dụng'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Upgrade when PlatformException occurs handles error safely without crash', (tester) async {
      setupPhoneDisplay(tester);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(purchasesChannel, (MethodCall call) async {
        throw PlatformException(
          code: '1',
          message: 'User cancelled',
          details: null,
        );
      });

      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final upgradeBtn = find.byKey(const Key('upgrade_button'));
      await tester.ensureVisible(upgradeBtn);
      await tester.tap(upgradeBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Giao dịch đã được hủy.'), findsOneWidget);
    });

    testWidgets('tapping Restore when RevenueCat is unconfigured shows safe feedback without crash', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final restoreBtn = find.byKey(const Key('restore_button'));
      expect(restoreBtn, findsOneWidget);

      await tester.ensureVisible(restoreBtn);
      await tester.tap(restoreBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('tapping Restore when PlatformException occurs handles error safely without crash', (tester) async {
      setupPhoneDisplay(tester);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(purchasesChannel, (MethodCall call) async {
        throw PlatformException(
          code: 'STORE_PROBLEM',
          message: 'There was a problem with the App Store',
          details: null,
        );
      });

      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final restoreBtn = find.byKey(const Key('restore_button'));
      await tester.ensureVisible(restoreBtn);
      await tester.tap(restoreBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Dịch vụ khôi phục tạm thời không khả dụng'),
        findsOneWidget,
      );
    });
  });

  group('PaywallScreen — Legal Links (Privacy Policy & EULA)', () {
    testWidgets('Privacy Policy and EULA links are rendered and clickable without crash', (tester) async {
      setupPhoneDisplay(tester);
      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final privacyLink = find.byKey(const Key('privacy_policy_link'));
      expect(privacyLink, findsOneWidget);
      await tester.ensureVisible(privacyLink);
      await tester.tap(privacyLink);
      await tester.pumpAndSettle();

      final termsLink = find.byKey(const Key('terms_of_service_link'));
      expect(termsLink, findsOneWidget);
      await tester.ensureVisible(termsLink);
      await tester.tap(termsLink);
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('Legal link handles launch failure gracefully with feedback SnackBar', (tester) async {
      setupPhoneDisplay(tester);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlChannel, (MethodCall call) async {
        return false;
      });

      await tester.pumpWidget(createPaywall());
      await tester.pumpAndSettle();

      final privacyLink = find.byKey(const Key('privacy_policy_link'));
      await tester.ensureVisible(privacyLink);
      await tester.tap(privacyLink);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Không thể mở liên kết'),
        findsOneWidget,
      );
    });
  });
}
