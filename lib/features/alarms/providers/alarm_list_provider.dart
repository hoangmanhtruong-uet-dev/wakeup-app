import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../data/local/database.dart';
import '../../../data/repositories/alarm_repository_provider.dart';

// StreamProvider để UI lắng nghe danh sách báo thức tự động cập nhật
final alarmListStreamProvider = StreamProvider<List<Alarm>>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  return repo.watchAlarms();
});

// Provider Controller để xử lý các thao tác tương tác của người dùng
final alarmControllerProvider = Provider<AlarmController>((ref) {
  return AlarmController(ref);
});

class AlarmController {
  final Ref _ref;
  AlarmController(this._ref);

  /// Bật/Tắt báo thức
  Future<void> toggleAlarm(Alarm alarm, bool isEnabled) async {
    final repo = _ref.read(alarmRepositoryProvider);
    await repo.toggleAlarm(alarm, isEnabled);
  }

  /// Xóa báo thức
  Future<void> deleteAlarm(int id) async {
    final repo = _ref.read(alarmRepositoryProvider);
    await repo.deleteAlarm(id);
  }

  /// Bỏ qua báo thức lần tới (Skip next)
  Future<void> skipNext(Alarm alarm, DateTime nextDate) async {
    final repo = _ref.read(alarmRepositoryProvider);
    final updatedAlarm = alarm.copyWith(skipNextDate: drift.Value(nextDate.toIso8601String()));
    await repo.updateAlarm(updatedAlarm);
  }
}
