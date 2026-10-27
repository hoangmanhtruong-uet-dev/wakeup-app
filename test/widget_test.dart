// Smoke test cơ bản: app khởi động được và dựng cây widget.
//
// Lưu ý: WakeUpApp gọi AppRouter -> các service native/Supabase, nên test này chỉ
// kiểm tra khả năng dựng khung, không kiểm tra nghiệp vụ.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wakeup_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WakeUpApp()));

    // App phải dựng được widget gốc.
    expect(find.byType(WakeUpApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    // AppRouter._checkInitialState() gọi trong initState với các lệnh local có
    // timeout (SharedPreferences + 2 MethodChannel). Mỗi timeout để lại một Timer;
    // nếu ta hủy widget tree trước khi chúng hết hạn, test sẽ fail với
    // "A Timer is still pending even after the widget tree was disposed".
    //
    // Vì vậy ta cho thời gian đủ để các Future hoàn tất hoặc hết hạn
    // (tổng tệ nhất 5 + 5 + 5 = 15s, pump 20s cho chắc), thay vì bỏ timeout đi.
    // Timeout là cơ chế chống treo màn hình loading — không được xoá để chiều test.
    await tester.pump(const Duration(seconds: 20));

    // Sau khi khởi tạo xong, màn hình loading phải biến mất.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}