import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/services/encryption_key_service.dart';

part 'database.g.dart';

// Definition of the Alarms table
class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get hour => integer().customConstraint('CHECK (hour >= 0 AND hour <= 23)')();
  IntColumn get minute => integer().customConstraint('CHECK (minute >= 0 AND minute <= 59)')();
  
  // Bitmask for days: 1=Mon, 2=Tue, 4=Wed, 8=Thu, 16=Fri, 32=Sat, 64=Sun
  IntColumn get repeatDays => integer().withDefault(const Constant(0))(); 
  
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get label => text().withLength(max: 50).nullable()();
  
  TextColumn get soundId => text().withDefault(const Constant('default'))();
  RealColumn get volume => real().withDefault(const Constant(1.0))();
  IntColumn get rampSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get vibrate => boolean().withDefault(const Constant(true))();
  
  IntColumn get snoozeMinutes => integer().withDefault(const Constant(5))();
  IntColumn get snoozeMax => integer().withDefault(const Constant(3))();
  IntColumn get autoStopMinutes => integer().withDefault(const Constant(15))();
  
  // ISO8601 string to skip next occurrence
  TextColumn get skipNextDate => text().nullable()(); 

  // Wake-up Mission configuration
  BoolColumn get missionEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get missionType => text().withDefault(const Constant('math'))();
  TextColumn get missionDifficulty => text().withDefault(const Constant('medium'))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Definition of the AlarmEvents table (History of rings)
class AlarmEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get alarmId => integer().references(Alarms, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get firedAt => dateTime()();
  
  // e.g. "snoozed", "dismissed", "missed"
  TextColumn get action => text()(); 
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Alarms, AlarmEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor dành cho test: dùng database in-memory, không cần mã hóa
  /// và không chạm vào hệ thống file.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(alarms, alarms.missionEnabled);
        await m.addColumn(alarms, alarms.missionType);
        await m.addColumn(alarms, alarms.missionDifficulty);
      }
    },
  );
  
  // --- CRUD cho Alarms ---
  Future<List<Alarm>> getAllAlarms() => select(alarms).get();
  
  Stream<List<Alarm>> watchAllAlarms() => select(alarms).watch();
  
  Future<Alarm> getAlarm(int id) => (select(alarms)..where((a) => a.id.equals(id))).getSingle();
  
  Future<int> insertAlarm(AlarmsCompanion alarm) => into(alarms).insert(alarm);
  
  Future<bool> updateAlarm(Alarm alarm) => update(alarms).replace(alarm);
  
  /// Xóa báo thức (kèm lịch sử đổ chuông liên quan)
  Future<int> deleteAlarm(int id) async {
    return transaction(() async {
      // Xóa lịch sử trước để không vi phạm ràng buộc khoá ngoại alarms(id).
      await (delete(alarmEvents)..where((e) => e.alarmId.equals(id))).go();
      return (delete(alarms)..where((a) => a.id.equals(id))).go();
    });
  }

  // --- CRUD cho AlarmEvents (lịch sử đổ chuông) ---

  /// Ghi 1 dòng lịch sử đổ chuông.
  /// [action] là một trong: 'dismissed' | 'snoozed' | 'missed'.
  Future<int> insertAlarmEvent(AlarmEventsCompanion event) {
    return into(alarmEvents).insert(event);
  }

  /// Lấy lịch sử đổ chuông của một báo thức, mới nhất trước.
  Future<List<AlarmEvent>> getEventsForAlarm(int alarmId, {int limit = 50}) {
    return (select(alarmEvents)
          ..where((e) => e.alarmId.equals(alarmId))
          ..orderBy([(e) => OrderingTerm.desc(e.firedAt)])
          ..limit(limit))
        .get();
  }

  /// Xóa lịch sử cũ hơn [retentionDays] (mặc định 90 ngày theo ARCHITECTURE.md).
  Future<int> pruneOldEvents({int retentionDays = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return (delete(alarmEvents)..where((e) => e.firedAt.isSmallerThanValue(cutoff))).go();
  }

  /// Xóa toàn bộ dữ liệu trong CSDL (phục vụ chức năng Xóa tài khoản / Full Wipe)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(alarmEvents).go();
      await delete(alarms).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wakeup_db.sqlite'));
    
    final encryptionKey = await EncryptionKeyService.getKey();

    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute("PRAGMA key = '$encryptionKey';");

      // Bật kiểm tra khoá ngoại. Mặc định SQLite TẮT, nếu không thì có thể ghi được
      // lịch sử AlarmEvents cho một báo thức đã bị xoá -> dữ liệu mồ côi trong bảng lịch sử.
      db.execute('PRAGMA foreign_keys = ON;');
    });
  });
}
