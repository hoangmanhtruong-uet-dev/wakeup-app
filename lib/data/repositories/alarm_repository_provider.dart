import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database_provider.dart';
import 'alarm_repository.dart';

// Provider cung cấp AlarmRepository, tự động tiêm AppDatabase vào.
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AlarmRepository(db);
});
