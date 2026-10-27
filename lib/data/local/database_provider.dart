import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

// Cung cấp một instance duy nhất (singleton) của AppDatabase trong toàn bộ vòng đời của app
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  
  // Đóng kết nối khi Provider bị hủy
  ref.onDispose(() {
    db.close();
  });
  
  return db;
});

// Provider để lấy danh sách Alarm theo thời gian thực (Reactive stream)
final alarmsStreamProvider = StreamProvider<List<Alarm>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllAlarms();
});
