// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, Alarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'CHECK (hour >= 0 AND hour <= 23)');
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
      'minute', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'CHECK (minute >= 0 AND minute <= 59)');
  static const VerificationMeta _repeatDaysMeta =
      const VerificationMeta('repeatDays');
  @override
  late final GeneratedColumn<int> repeatDays = GeneratedColumn<int>(
      'repeat_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _soundIdMeta =
      const VerificationMeta('soundId');
  @override
  late final GeneratedColumn<String> soundId = GeneratedColumn<String>(
      'sound_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('default'));
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
      'volume', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _rampSecondsMeta =
      const VerificationMeta('rampSeconds');
  @override
  late final GeneratedColumn<int> rampSeconds = GeneratedColumn<int>(
      'ramp_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _vibrateMeta =
      const VerificationMeta('vibrate');
  @override
  late final GeneratedColumn<bool> vibrate = GeneratedColumn<bool>(
      'vibrate', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("vibrate" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _snoozeMinutesMeta =
      const VerificationMeta('snoozeMinutes');
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
      'snooze_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _snoozeMaxMeta =
      const VerificationMeta('snoozeMax');
  @override
  late final GeneratedColumn<int> snoozeMax = GeneratedColumn<int>(
      'snooze_max', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _autoStopMinutesMeta =
      const VerificationMeta('autoStopMinutes');
  @override
  late final GeneratedColumn<int> autoStopMinutes = GeneratedColumn<int>(
      'auto_stop_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _skipNextDateMeta =
      const VerificationMeta('skipNextDate');
  @override
  late final GeneratedColumn<String> skipNextDate = GeneratedColumn<String>(
      'skip_next_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _missionEnabledMeta =
      const VerificationMeta('missionEnabled');
  @override
  late final GeneratedColumn<bool> missionEnabled = GeneratedColumn<bool>(
      'mission_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("mission_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _missionTypeMeta =
      const VerificationMeta('missionType');
  @override
  late final GeneratedColumn<String> missionType = GeneratedColumn<String>(
      'mission_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('math'));
  static const VerificationMeta _missionDifficultyMeta =
      const VerificationMeta('missionDifficulty');
  @override
  late final GeneratedColumn<String> missionDifficulty =
      GeneratedColumn<String>('mission_difficulty', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('medium'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        hour,
        minute,
        repeatDays,
        enabled,
        label,
        soundId,
        volume,
        rampSeconds,
        vibrate,
        snoozeMinutes,
        snoozeMax,
        autoStopMinutes,
        skipNextDate,
        missionEnabled,
        missionType,
        missionDifficulty,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(Insertable<Alarm> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(_minuteMeta,
          minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta));
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('repeat_days')) {
      context.handle(
          _repeatDaysMeta,
          repeatDays.isAcceptableOrUnknown(
              data['repeat_days']!, _repeatDaysMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('sound_id')) {
      context.handle(_soundIdMeta,
          soundId.isAcceptableOrUnknown(data['sound_id']!, _soundIdMeta));
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta,
          volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    if (data.containsKey('ramp_seconds')) {
      context.handle(
          _rampSecondsMeta,
          rampSeconds.isAcceptableOrUnknown(
              data['ramp_seconds']!, _rampSecondsMeta));
    }
    if (data.containsKey('vibrate')) {
      context.handle(_vibrateMeta,
          vibrate.isAcceptableOrUnknown(data['vibrate']!, _vibrateMeta));
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
          _snoozeMinutesMeta,
          snoozeMinutes.isAcceptableOrUnknown(
              data['snooze_minutes']!, _snoozeMinutesMeta));
    }
    if (data.containsKey('snooze_max')) {
      context.handle(_snoozeMaxMeta,
          snoozeMax.isAcceptableOrUnknown(data['snooze_max']!, _snoozeMaxMeta));
    }
    if (data.containsKey('auto_stop_minutes')) {
      context.handle(
          _autoStopMinutesMeta,
          autoStopMinutes.isAcceptableOrUnknown(
              data['auto_stop_minutes']!, _autoStopMinutesMeta));
    }
    if (data.containsKey('skip_next_date')) {
      context.handle(
          _skipNextDateMeta,
          skipNextDate.isAcceptableOrUnknown(
              data['skip_next_date']!, _skipNextDateMeta));
    }
    if (data.containsKey('mission_enabled')) {
      context.handle(
          _missionEnabledMeta,
          missionEnabled.isAcceptableOrUnknown(
              data['mission_enabled']!, _missionEnabledMeta));
    }
    if (data.containsKey('mission_type')) {
      context.handle(
          _missionTypeMeta,
          missionType.isAcceptableOrUnknown(
              data['mission_type']!, _missionTypeMeta));
    }
    if (data.containsKey('mission_difficulty')) {
      context.handle(
          _missionDifficultyMeta,
          missionDifficulty.isAcceptableOrUnknown(
              data['mission_difficulty']!, _missionDifficultyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alarm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      minute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute'])!,
      repeatDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repeat_days'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      soundId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sound_id'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
      rampSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ramp_seconds'])!,
      vibrate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}vibrate'])!,
      snoozeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}snooze_minutes'])!,
      snoozeMax: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}snooze_max'])!,
      autoStopMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}auto_stop_minutes'])!,
      skipNextDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}skip_next_date']),
      missionEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}mission_enabled'])!,
      missionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mission_type'])!,
      missionDifficulty: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mission_difficulty'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }
}

class Alarm extends DataClass implements Insertable<Alarm> {
  final int id;
  final int hour;
  final int minute;
  final int repeatDays;
  final bool enabled;
  final String? label;
  final String soundId;
  final double volume;
  final int rampSeconds;
  final bool vibrate;
  final int snoozeMinutes;
  final int snoozeMax;
  final int autoStopMinutes;
  final String? skipNextDate;
  final bool missionEnabled;
  final String missionType;
  final String missionDifficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Alarm(
      {required this.id,
      required this.hour,
      required this.minute,
      required this.repeatDays,
      required this.enabled,
      this.label,
      required this.soundId,
      required this.volume,
      required this.rampSeconds,
      required this.vibrate,
      required this.snoozeMinutes,
      required this.snoozeMax,
      required this.autoStopMinutes,
      this.skipNextDate,
      required this.missionEnabled,
      required this.missionType,
      required this.missionDifficulty,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['repeat_days'] = Variable<int>(repeatDays);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['sound_id'] = Variable<String>(soundId);
    map['volume'] = Variable<double>(volume);
    map['ramp_seconds'] = Variable<int>(rampSeconds);
    map['vibrate'] = Variable<bool>(vibrate);
    map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    map['snooze_max'] = Variable<int>(snoozeMax);
    map['auto_stop_minutes'] = Variable<int>(autoStopMinutes);
    if (!nullToAbsent || skipNextDate != null) {
      map['skip_next_date'] = Variable<String>(skipNextDate);
    }
    map['mission_enabled'] = Variable<bool>(missionEnabled);
    map['mission_type'] = Variable<String>(missionType);
    map['mission_difficulty'] = Variable<String>(missionDifficulty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      hour: Value(hour),
      minute: Value(minute),
      repeatDays: Value(repeatDays),
      enabled: Value(enabled),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      soundId: Value(soundId),
      volume: Value(volume),
      rampSeconds: Value(rampSeconds),
      vibrate: Value(vibrate),
      snoozeMinutes: Value(snoozeMinutes),
      snoozeMax: Value(snoozeMax),
      autoStopMinutes: Value(autoStopMinutes),
      skipNextDate: skipNextDate == null && nullToAbsent
          ? const Value.absent()
          : Value(skipNextDate),
      missionEnabled: Value(missionEnabled),
      missionType: Value(missionType),
      missionDifficulty: Value(missionDifficulty),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Alarm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alarm(
      id: serializer.fromJson<int>(json['id']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      repeatDays: serializer.fromJson<int>(json['repeatDays']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      label: serializer.fromJson<String?>(json['label']),
      soundId: serializer.fromJson<String>(json['soundId']),
      volume: serializer.fromJson<double>(json['volume']),
      rampSeconds: serializer.fromJson<int>(json['rampSeconds']),
      vibrate: serializer.fromJson<bool>(json['vibrate']),
      snoozeMinutes: serializer.fromJson<int>(json['snoozeMinutes']),
      snoozeMax: serializer.fromJson<int>(json['snoozeMax']),
      autoStopMinutes: serializer.fromJson<int>(json['autoStopMinutes']),
      skipNextDate: serializer.fromJson<String?>(json['skipNextDate']),
      missionEnabled: serializer.fromJson<bool>(json['missionEnabled']),
      missionType: serializer.fromJson<String>(json['missionType']),
      missionDifficulty: serializer.fromJson<String>(json['missionDifficulty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'repeatDays': serializer.toJson<int>(repeatDays),
      'enabled': serializer.toJson<bool>(enabled),
      'label': serializer.toJson<String?>(label),
      'soundId': serializer.toJson<String>(soundId),
      'volume': serializer.toJson<double>(volume),
      'rampSeconds': serializer.toJson<int>(rampSeconds),
      'vibrate': serializer.toJson<bool>(vibrate),
      'snoozeMinutes': serializer.toJson<int>(snoozeMinutes),
      'snoozeMax': serializer.toJson<int>(snoozeMax),
      'autoStopMinutes': serializer.toJson<int>(autoStopMinutes),
      'skipNextDate': serializer.toJson<String?>(skipNextDate),
      'missionEnabled': serializer.toJson<bool>(missionEnabled),
      'missionType': serializer.toJson<String>(missionType),
      'missionDifficulty': serializer.toJson<String>(missionDifficulty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Alarm copyWith(
          {int? id,
          int? hour,
          int? minute,
          int? repeatDays,
          bool? enabled,
          Value<String?> label = const Value.absent(),
          String? soundId,
          double? volume,
          int? rampSeconds,
          bool? vibrate,
          int? snoozeMinutes,
          int? snoozeMax,
          int? autoStopMinutes,
          Value<String?> skipNextDate = const Value.absent(),
          bool? missionEnabled,
          String? missionType,
          String? missionDifficulty,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Alarm(
        id: id ?? this.id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        repeatDays: repeatDays ?? this.repeatDays,
        enabled: enabled ?? this.enabled,
        label: label.present ? label.value : this.label,
        soundId: soundId ?? this.soundId,
        volume: volume ?? this.volume,
        rampSeconds: rampSeconds ?? this.rampSeconds,
        vibrate: vibrate ?? this.vibrate,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        snoozeMax: snoozeMax ?? this.snoozeMax,
        autoStopMinutes: autoStopMinutes ?? this.autoStopMinutes,
        skipNextDate:
            skipNextDate.present ? skipNextDate.value : this.skipNextDate,
        missionEnabled: missionEnabled ?? this.missionEnabled,
        missionType: missionType ?? this.missionType,
        missionDifficulty: missionDifficulty ?? this.missionDifficulty,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Alarm copyWithCompanion(AlarmsCompanion data) {
    return Alarm(
      id: data.id.present ? data.id.value : this.id,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      repeatDays:
          data.repeatDays.present ? data.repeatDays.value : this.repeatDays,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      label: data.label.present ? data.label.value : this.label,
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      volume: data.volume.present ? data.volume.value : this.volume,
      rampSeconds:
          data.rampSeconds.present ? data.rampSeconds.value : this.rampSeconds,
      vibrate: data.vibrate.present ? data.vibrate.value : this.vibrate,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      snoozeMax: data.snoozeMax.present ? data.snoozeMax.value : this.snoozeMax,
      autoStopMinutes: data.autoStopMinutes.present
          ? data.autoStopMinutes.value
          : this.autoStopMinutes,
      skipNextDate: data.skipNextDate.present
          ? data.skipNextDate.value
          : this.skipNextDate,
      missionEnabled: data.missionEnabled.present
          ? data.missionEnabled.value
          : this.missionEnabled,
      missionType:
          data.missionType.present ? data.missionType.value : this.missionType,
      missionDifficulty: data.missionDifficulty.present
          ? data.missionDifficulty.value
          : this.missionDifficulty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alarm(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('enabled: $enabled, ')
          ..write('label: $label, ')
          ..write('soundId: $soundId, ')
          ..write('volume: $volume, ')
          ..write('rampSeconds: $rampSeconds, ')
          ..write('vibrate: $vibrate, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('snoozeMax: $snoozeMax, ')
          ..write('autoStopMinutes: $autoStopMinutes, ')
          ..write('skipNextDate: $skipNextDate, ')
          ..write('missionEnabled: $missionEnabled, ')
          ..write('missionType: $missionType, ')
          ..write('missionDifficulty: $missionDifficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      hour,
      minute,
      repeatDays,
      enabled,
      label,
      soundId,
      volume,
      rampSeconds,
      vibrate,
      snoozeMinutes,
      snoozeMax,
      autoStopMinutes,
      skipNextDate,
      missionEnabled,
      missionType,
      missionDifficulty,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alarm &&
          other.id == this.id &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.repeatDays == this.repeatDays &&
          other.enabled == this.enabled &&
          other.label == this.label &&
          other.soundId == this.soundId &&
          other.volume == this.volume &&
          other.rampSeconds == this.rampSeconds &&
          other.vibrate == this.vibrate &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.snoozeMax == this.snoozeMax &&
          other.autoStopMinutes == this.autoStopMinutes &&
          other.skipNextDate == this.skipNextDate &&
          other.missionEnabled == this.missionEnabled &&
          other.missionType == this.missionType &&
          other.missionDifficulty == this.missionDifficulty &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AlarmsCompanion extends UpdateCompanion<Alarm> {
  final Value<int> id;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> repeatDays;
  final Value<bool> enabled;
  final Value<String?> label;
  final Value<String> soundId;
  final Value<double> volume;
  final Value<int> rampSeconds;
  final Value<bool> vibrate;
  final Value<int> snoozeMinutes;
  final Value<int> snoozeMax;
  final Value<int> autoStopMinutes;
  final Value<String?> skipNextDate;
  final Value<bool> missionEnabled;
  final Value<String> missionType;
  final Value<String> missionDifficulty;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.enabled = const Value.absent(),
    this.label = const Value.absent(),
    this.soundId = const Value.absent(),
    this.volume = const Value.absent(),
    this.rampSeconds = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.snoozeMax = const Value.absent(),
    this.autoStopMinutes = const Value.absent(),
    this.skipNextDate = const Value.absent(),
    this.missionEnabled = const Value.absent(),
    this.missionType = const Value.absent(),
    this.missionDifficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AlarmsCompanion.insert({
    this.id = const Value.absent(),
    required int hour,
    required int minute,
    this.repeatDays = const Value.absent(),
    this.enabled = const Value.absent(),
    this.label = const Value.absent(),
    this.soundId = const Value.absent(),
    this.volume = const Value.absent(),
    this.rampSeconds = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.snoozeMax = const Value.absent(),
    this.autoStopMinutes = const Value.absent(),
    this.skipNextDate = const Value.absent(),
    this.missionEnabled = const Value.absent(),
    this.missionType = const Value.absent(),
    this.missionDifficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : hour = Value(hour),
        minute = Value(minute);
  static Insertable<Alarm> custom({
    Expression<int>? id,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? repeatDays,
    Expression<bool>? enabled,
    Expression<String>? label,
    Expression<String>? soundId,
    Expression<double>? volume,
    Expression<int>? rampSeconds,
    Expression<bool>? vibrate,
    Expression<int>? snoozeMinutes,
    Expression<int>? snoozeMax,
    Expression<int>? autoStopMinutes,
    Expression<String>? skipNextDate,
    Expression<bool>? missionEnabled,
    Expression<String>? missionType,
    Expression<String>? missionDifficulty,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (repeatDays != null) 'repeat_days': repeatDays,
      if (enabled != null) 'enabled': enabled,
      if (label != null) 'label': label,
      if (soundId != null) 'sound_id': soundId,
      if (volume != null) 'volume': volume,
      if (rampSeconds != null) 'ramp_seconds': rampSeconds,
      if (vibrate != null) 'vibrate': vibrate,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (snoozeMax != null) 'snooze_max': snoozeMax,
      if (autoStopMinutes != null) 'auto_stop_minutes': autoStopMinutes,
      if (skipNextDate != null) 'skip_next_date': skipNextDate,
      if (missionEnabled != null) 'mission_enabled': missionEnabled,
      if (missionType != null) 'mission_type': missionType,
      if (missionDifficulty != null) 'mission_difficulty': missionDifficulty,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AlarmsCompanion copyWith(
      {Value<int>? id,
      Value<int>? hour,
      Value<int>? minute,
      Value<int>? repeatDays,
      Value<bool>? enabled,
      Value<String?>? label,
      Value<String>? soundId,
      Value<double>? volume,
      Value<int>? rampSeconds,
      Value<bool>? vibrate,
      Value<int>? snoozeMinutes,
      Value<int>? snoozeMax,
      Value<int>? autoStopMinutes,
      Value<String?>? skipNextDate,
      Value<bool>? missionEnabled,
      Value<String>? missionType,
      Value<String>? missionDifficulty,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return AlarmsCompanion(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      soundId: soundId ?? this.soundId,
      volume: volume ?? this.volume,
      rampSeconds: rampSeconds ?? this.rampSeconds,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeMax: snoozeMax ?? this.snoozeMax,
      autoStopMinutes: autoStopMinutes ?? this.autoStopMinutes,
      skipNextDate: skipNextDate ?? this.skipNextDate,
      missionEnabled: missionEnabled ?? this.missionEnabled,
      missionType: missionType ?? this.missionType,
      missionDifficulty: missionDifficulty ?? this.missionDifficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (repeatDays.present) {
      map['repeat_days'] = Variable<int>(repeatDays.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (soundId.present) {
      map['sound_id'] = Variable<String>(soundId.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (rampSeconds.present) {
      map['ramp_seconds'] = Variable<int>(rampSeconds.value);
    }
    if (vibrate.present) {
      map['vibrate'] = Variable<bool>(vibrate.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (snoozeMax.present) {
      map['snooze_max'] = Variable<int>(snoozeMax.value);
    }
    if (autoStopMinutes.present) {
      map['auto_stop_minutes'] = Variable<int>(autoStopMinutes.value);
    }
    if (skipNextDate.present) {
      map['skip_next_date'] = Variable<String>(skipNextDate.value);
    }
    if (missionEnabled.present) {
      map['mission_enabled'] = Variable<bool>(missionEnabled.value);
    }
    if (missionType.present) {
      map['mission_type'] = Variable<String>(missionType.value);
    }
    if (missionDifficulty.present) {
      map['mission_difficulty'] = Variable<String>(missionDifficulty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('enabled: $enabled, ')
          ..write('label: $label, ')
          ..write('soundId: $soundId, ')
          ..write('volume: $volume, ')
          ..write('rampSeconds: $rampSeconds, ')
          ..write('vibrate: $vibrate, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('snoozeMax: $snoozeMax, ')
          ..write('autoStopMinutes: $autoStopMinutes, ')
          ..write('skipNextDate: $skipNextDate, ')
          ..write('missionEnabled: $missionEnabled, ')
          ..write('missionType: $missionType, ')
          ..write('missionDifficulty: $missionDifficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AlarmEventsTable extends AlarmEvents
    with TableInfo<$AlarmEventsTable, AlarmEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _alarmIdMeta =
      const VerificationMeta('alarmId');
  @override
  late final GeneratedColumn<int> alarmId = GeneratedColumn<int>(
      'alarm_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES alarms (id)'));
  static const VerificationMeta _scheduledAtMeta =
      const VerificationMeta('scheduledAt');
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
      'scheduled_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _firedAtMeta =
      const VerificationMeta('firedAt');
  @override
  late final GeneratedColumn<DateTime> firedAt = GeneratedColumn<DateTime>(
      'fired_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _snoozeCountMeta =
      const VerificationMeta('snoozeCount');
  @override
  late final GeneratedColumn<int> snoozeCount = GeneratedColumn<int>(
      'snooze_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, alarmId, scheduledAt, firedAt, action, snoozeCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarm_events';
  @override
  VerificationContext validateIntegrity(Insertable<AlarmEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alarm_id')) {
      context.handle(_alarmIdMeta,
          alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta));
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
          _scheduledAtMeta,
          scheduledAt.isAcceptableOrUnknown(
              data['scheduled_at']!, _scheduledAtMeta));
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('fired_at')) {
      context.handle(_firedAtMeta,
          firedAt.isAcceptableOrUnknown(data['fired_at']!, _firedAtMeta));
    } else if (isInserting) {
      context.missing(_firedAtMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('snooze_count')) {
      context.handle(
          _snoozeCountMeta,
          snoozeCount.isAcceptableOrUnknown(
              data['snooze_count']!, _snoozeCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      alarmId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}alarm_id'])!,
      scheduledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}scheduled_at'])!,
      firedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fired_at'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      snoozeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}snooze_count'])!,
    );
  }

  @override
  $AlarmEventsTable createAlias(String alias) {
    return $AlarmEventsTable(attachedDatabase, alias);
  }
}

class AlarmEvent extends DataClass implements Insertable<AlarmEvent> {
  final int id;
  final int alarmId;
  final DateTime scheduledAt;
  final DateTime firedAt;
  final String action;
  final int snoozeCount;
  const AlarmEvent(
      {required this.id,
      required this.alarmId,
      required this.scheduledAt,
      required this.firedAt,
      required this.action,
      required this.snoozeCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alarm_id'] = Variable<int>(alarmId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['fired_at'] = Variable<DateTime>(firedAt);
    map['action'] = Variable<String>(action);
    map['snooze_count'] = Variable<int>(snoozeCount);
    return map;
  }

  AlarmEventsCompanion toCompanion(bool nullToAbsent) {
    return AlarmEventsCompanion(
      id: Value(id),
      alarmId: Value(alarmId),
      scheduledAt: Value(scheduledAt),
      firedAt: Value(firedAt),
      action: Value(action),
      snoozeCount: Value(snoozeCount),
    );
  }

  factory AlarmEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmEvent(
      id: serializer.fromJson<int>(json['id']),
      alarmId: serializer.fromJson<int>(json['alarmId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      firedAt: serializer.fromJson<DateTime>(json['firedAt']),
      action: serializer.fromJson<String>(json['action']),
      snoozeCount: serializer.fromJson<int>(json['snoozeCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alarmId': serializer.toJson<int>(alarmId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'firedAt': serializer.toJson<DateTime>(firedAt),
      'action': serializer.toJson<String>(action),
      'snoozeCount': serializer.toJson<int>(snoozeCount),
    };
  }

  AlarmEvent copyWith(
          {int? id,
          int? alarmId,
          DateTime? scheduledAt,
          DateTime? firedAt,
          String? action,
          int? snoozeCount}) =>
      AlarmEvent(
        id: id ?? this.id,
        alarmId: alarmId ?? this.alarmId,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        firedAt: firedAt ?? this.firedAt,
        action: action ?? this.action,
        snoozeCount: snoozeCount ?? this.snoozeCount,
      );
  AlarmEvent copyWithCompanion(AlarmEventsCompanion data) {
    return AlarmEvent(
      id: data.id.present ? data.id.value : this.id,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      scheduledAt:
          data.scheduledAt.present ? data.scheduledAt.value : this.scheduledAt,
      firedAt: data.firedAt.present ? data.firedAt.value : this.firedAt,
      action: data.action.present ? data.action.value : this.action,
      snoozeCount:
          data.snoozeCount.present ? data.snoozeCount.value : this.snoozeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmEvent(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('firedAt: $firedAt, ')
          ..write('action: $action, ')
          ..write('snoozeCount: $snoozeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, alarmId, scheduledAt, firedAt, action, snoozeCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmEvent &&
          other.id == this.id &&
          other.alarmId == this.alarmId &&
          other.scheduledAt == this.scheduledAt &&
          other.firedAt == this.firedAt &&
          other.action == this.action &&
          other.snoozeCount == this.snoozeCount);
}

class AlarmEventsCompanion extends UpdateCompanion<AlarmEvent> {
  final Value<int> id;
  final Value<int> alarmId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime> firedAt;
  final Value<String> action;
  final Value<int> snoozeCount;
  const AlarmEventsCompanion({
    this.id = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.action = const Value.absent(),
    this.snoozeCount = const Value.absent(),
  });
  AlarmEventsCompanion.insert({
    this.id = const Value.absent(),
    required int alarmId,
    required DateTime scheduledAt,
    required DateTime firedAt,
    required String action,
    this.snoozeCount = const Value.absent(),
  })  : alarmId = Value(alarmId),
        scheduledAt = Value(scheduledAt),
        firedAt = Value(firedAt),
        action = Value(action);
  static Insertable<AlarmEvent> custom({
    Expression<int>? id,
    Expression<int>? alarmId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? firedAt,
    Expression<String>? action,
    Expression<int>? snoozeCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alarmId != null) 'alarm_id': alarmId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (firedAt != null) 'fired_at': firedAt,
      if (action != null) 'action': action,
      if (snoozeCount != null) 'snooze_count': snoozeCount,
    });
  }

  AlarmEventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? alarmId,
      Value<DateTime>? scheduledAt,
      Value<DateTime>? firedAt,
      Value<String>? action,
      Value<int>? snoozeCount}) {
    return AlarmEventsCompanion(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      firedAt: firedAt ?? this.firedAt,
      action: action ?? this.action,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<int>(alarmId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (firedAt.present) {
      map['fired_at'] = Variable<DateTime>(firedAt.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (snoozeCount.present) {
      map['snooze_count'] = Variable<int>(snoozeCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmEventsCompanion(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('firedAt: $firedAt, ')
          ..write('action: $action, ')
          ..write('snoozeCount: $snoozeCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $AlarmEventsTable alarmEvents = $AlarmEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [alarms, alarmEvents];
}

typedef $$AlarmsTableCreateCompanionBuilder = AlarmsCompanion Function({
  Value<int> id,
  required int hour,
  required int minute,
  Value<int> repeatDays,
  Value<bool> enabled,
  Value<String?> label,
  Value<String> soundId,
  Value<double> volume,
  Value<int> rampSeconds,
  Value<bool> vibrate,
  Value<int> snoozeMinutes,
  Value<int> snoozeMax,
  Value<int> autoStopMinutes,
  Value<String?> skipNextDate,
  Value<bool> missionEnabled,
  Value<String> missionType,
  Value<String> missionDifficulty,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$AlarmsTableUpdateCompanionBuilder = AlarmsCompanion Function({
  Value<int> id,
  Value<int> hour,
  Value<int> minute,
  Value<int> repeatDays,
  Value<bool> enabled,
  Value<String?> label,
  Value<String> soundId,
  Value<double> volume,
  Value<int> rampSeconds,
  Value<bool> vibrate,
  Value<int> snoozeMinutes,
  Value<int> snoozeMax,
  Value<int> autoStopMinutes,
  Value<String?> skipNextDate,
  Value<bool> missionEnabled,
  Value<String> missionType,
  Value<String> missionDifficulty,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$AlarmsTableReferences
    extends BaseReferences<_$AppDatabase, $AlarmsTable, Alarm> {
  $$AlarmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AlarmEventsTable, List<AlarmEvent>>
      _alarmEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.alarmEvents,
              aliasName: 'alarms__id__alarm_events__alarm_id');

  $$AlarmEventsTableProcessedTableManager get alarmEventsRefs {
    final manager = $$AlarmEventsTableTableManager($_db, $_db.alarmEvents)
        .filter((f) => f.alarmId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_alarmEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repeatDays => $composableBuilder(
      column: $table.repeatDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get soundId => $composableBuilder(
      column: $table.soundId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rampSeconds => $composableBuilder(
      column: $table.rampSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get vibrate => $composableBuilder(
      column: $table.vibrate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
      column: $table.snoozeMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snoozeMax => $composableBuilder(
      column: $table.snoozeMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get autoStopMinutes => $composableBuilder(
      column: $table.autoStopMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get skipNextDate => $composableBuilder(
      column: $table.skipNextDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get missionEnabled => $composableBuilder(
      column: $table.missionEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get missionType => $composableBuilder(
      column: $table.missionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get missionDifficulty => $composableBuilder(
      column: $table.missionDifficulty,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> alarmEventsRefs(
      Expression<bool> Function($$AlarmEventsTableFilterComposer f) f) {
    final $$AlarmEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.alarmEvents,
        getReferencedColumn: (t) => t.alarmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlarmEventsTableFilterComposer(
              $db: $db,
              $table: $db.alarmEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repeatDays => $composableBuilder(
      column: $table.repeatDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get soundId => $composableBuilder(
      column: $table.soundId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rampSeconds => $composableBuilder(
      column: $table.rampSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get vibrate => $composableBuilder(
      column: $table.vibrate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
      column: $table.snoozeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snoozeMax => $composableBuilder(
      column: $table.snoozeMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get autoStopMinutes => $composableBuilder(
      column: $table.autoStopMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get skipNextDate => $composableBuilder(
      column: $table.skipNextDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get missionEnabled => $composableBuilder(
      column: $table.missionEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get missionType => $composableBuilder(
      column: $table.missionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get missionDifficulty => $composableBuilder(
      column: $table.missionDifficulty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get repeatDays => $composableBuilder(
      column: $table.repeatDays, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get soundId =>
      $composableBuilder(column: $table.soundId, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<int> get rampSeconds => $composableBuilder(
      column: $table.rampSeconds, builder: (column) => column);

  GeneratedColumn<bool> get vibrate =>
      $composableBuilder(column: $table.vibrate, builder: (column) => column);

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
      column: $table.snoozeMinutes, builder: (column) => column);

  GeneratedColumn<int> get snoozeMax =>
      $composableBuilder(column: $table.snoozeMax, builder: (column) => column);

  GeneratedColumn<int> get autoStopMinutes => $composableBuilder(
      column: $table.autoStopMinutes, builder: (column) => column);

  GeneratedColumn<String> get skipNextDate => $composableBuilder(
      column: $table.skipNextDate, builder: (column) => column);

  GeneratedColumn<bool> get missionEnabled => $composableBuilder(
      column: $table.missionEnabled, builder: (column) => column);

  GeneratedColumn<String> get missionType => $composableBuilder(
      column: $table.missionType, builder: (column) => column);

  GeneratedColumn<String> get missionDifficulty => $composableBuilder(
      column: $table.missionDifficulty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> alarmEventsRefs<T extends Object>(
      Expression<T> Function($$AlarmEventsTableAnnotationComposer a) f) {
    final $$AlarmEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.alarmEvents,
        getReferencedColumn: (t) => t.alarmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlarmEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.alarmEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlarmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlarmsTable,
    Alarm,
    $$AlarmsTableFilterComposer,
    $$AlarmsTableOrderingComposer,
    $$AlarmsTableAnnotationComposer,
    $$AlarmsTableCreateCompanionBuilder,
    $$AlarmsTableUpdateCompanionBuilder,
    (Alarm, $$AlarmsTableReferences),
    Alarm,
    PrefetchHooks Function({bool alarmEventsRefs})> {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<int> minute = const Value.absent(),
            Value<int> repeatDays = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String> soundId = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> rampSeconds = const Value.absent(),
            Value<bool> vibrate = const Value.absent(),
            Value<int> snoozeMinutes = const Value.absent(),
            Value<int> snoozeMax = const Value.absent(),
            Value<int> autoStopMinutes = const Value.absent(),
            Value<String?> skipNextDate = const Value.absent(),
            Value<bool> missionEnabled = const Value.absent(),
            Value<String> missionType = const Value.absent(),
            Value<String> missionDifficulty = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AlarmsCompanion(
            id: id,
            hour: hour,
            minute: minute,
            repeatDays: repeatDays,
            enabled: enabled,
            label: label,
            soundId: soundId,
            volume: volume,
            rampSeconds: rampSeconds,
            vibrate: vibrate,
            snoozeMinutes: snoozeMinutes,
            snoozeMax: snoozeMax,
            autoStopMinutes: autoStopMinutes,
            skipNextDate: skipNextDate,
            missionEnabled: missionEnabled,
            missionType: missionType,
            missionDifficulty: missionDifficulty,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int hour,
            required int minute,
            Value<int> repeatDays = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String> soundId = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> rampSeconds = const Value.absent(),
            Value<bool> vibrate = const Value.absent(),
            Value<int> snoozeMinutes = const Value.absent(),
            Value<int> snoozeMax = const Value.absent(),
            Value<int> autoStopMinutes = const Value.absent(),
            Value<String?> skipNextDate = const Value.absent(),
            Value<bool> missionEnabled = const Value.absent(),
            Value<String> missionType = const Value.absent(),
            Value<String> missionDifficulty = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AlarmsCompanion.insert(
            id: id,
            hour: hour,
            minute: minute,
            repeatDays: repeatDays,
            enabled: enabled,
            label: label,
            soundId: soundId,
            volume: volume,
            rampSeconds: rampSeconds,
            vibrate: vibrate,
            snoozeMinutes: snoozeMinutes,
            snoozeMax: snoozeMax,
            autoStopMinutes: autoStopMinutes,
            skipNextDate: skipNextDate,
            missionEnabled: missionEnabled,
            missionType: missionType,
            missionDifficulty: missionDifficulty,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AlarmsTable, Alarm>(table),
                    $$AlarmsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({alarmEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (alarmEventsRefs) db.alarmEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (alarmEventsRefs)
                    await $_getPrefetchedData<Alarm, $AlarmsTable, AlarmEvent>(
                        currentTable: table,
                        referencedTable:
                            $$AlarmsTableReferences._alarmEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlarmsTableReferences(db, table, p0)
                                .alarmEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.alarmId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AlarmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlarmsTable,
    Alarm,
    $$AlarmsTableFilterComposer,
    $$AlarmsTableOrderingComposer,
    $$AlarmsTableAnnotationComposer,
    $$AlarmsTableCreateCompanionBuilder,
    $$AlarmsTableUpdateCompanionBuilder,
    (Alarm, $$AlarmsTableReferences),
    Alarm,
    PrefetchHooks Function({bool alarmEventsRefs})>;
typedef $$AlarmEventsTableCreateCompanionBuilder = AlarmEventsCompanion
    Function({
  Value<int> id,
  required int alarmId,
  required DateTime scheduledAt,
  required DateTime firedAt,
  required String action,
  Value<int> snoozeCount,
});
typedef $$AlarmEventsTableUpdateCompanionBuilder = AlarmEventsCompanion
    Function({
  Value<int> id,
  Value<int> alarmId,
  Value<DateTime> scheduledAt,
  Value<DateTime> firedAt,
  Value<String> action,
  Value<int> snoozeCount,
});

final class $$AlarmEventsTableReferences
    extends BaseReferences<_$AppDatabase, $AlarmEventsTable, AlarmEvent> {
  $$AlarmEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlarmsTable _alarmIdTable(_$AppDatabase db) =>
      db.alarms.createAlias('alarm_events__alarm_id__alarms__id');

  $$AlarmsTableProcessedTableManager get alarmId {
    final $_column = $_itemColumn<int>('alarm_id')!;

    final manager = $$AlarmsTableTableManager($_db, $_db.alarms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alarmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AlarmEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmEventsTable> {
  $$AlarmEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firedAt => $composableBuilder(
      column: $table.firedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snoozeCount => $composableBuilder(
      column: $table.snoozeCount, builder: (column) => ColumnFilters(column));

  $$AlarmsTableFilterComposer get alarmId {
    final $$AlarmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.alarmId,
        referencedTable: $db.alarms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlarmsTableFilterComposer(
              $db: $db,
              $table: $db.alarms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlarmEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmEventsTable> {
  $$AlarmEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firedAt => $composableBuilder(
      column: $table.firedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snoozeCount => $composableBuilder(
      column: $table.snoozeCount, builder: (column) => ColumnOrderings(column));

  $$AlarmsTableOrderingComposer get alarmId {
    final $$AlarmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.alarmId,
        referencedTable: $db.alarms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlarmsTableOrderingComposer(
              $db: $db,
              $table: $db.alarms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlarmEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmEventsTable> {
  $$AlarmEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get firedAt =>
      $composableBuilder(column: $table.firedAt, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get snoozeCount => $composableBuilder(
      column: $table.snoozeCount, builder: (column) => column);

  $$AlarmsTableAnnotationComposer get alarmId {
    final $$AlarmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.alarmId,
        referencedTable: $db.alarms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlarmsTableAnnotationComposer(
              $db: $db,
              $table: $db.alarms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AlarmEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlarmEventsTable,
    AlarmEvent,
    $$AlarmEventsTableFilterComposer,
    $$AlarmEventsTableOrderingComposer,
    $$AlarmEventsTableAnnotationComposer,
    $$AlarmEventsTableCreateCompanionBuilder,
    $$AlarmEventsTableUpdateCompanionBuilder,
    (AlarmEvent, $$AlarmEventsTableReferences),
    AlarmEvent,
    PrefetchHooks Function({bool alarmId})> {
  $$AlarmEventsTableTableManager(_$AppDatabase db, $AlarmEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> alarmId = const Value.absent(),
            Value<DateTime> scheduledAt = const Value.absent(),
            Value<DateTime> firedAt = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<int> snoozeCount = const Value.absent(),
          }) =>
              AlarmEventsCompanion(
            id: id,
            alarmId: alarmId,
            scheduledAt: scheduledAt,
            firedAt: firedAt,
            action: action,
            snoozeCount: snoozeCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int alarmId,
            required DateTime scheduledAt,
            required DateTime firedAt,
            required String action,
            Value<int> snoozeCount = const Value.absent(),
          }) =>
              AlarmEventsCompanion.insert(
            id: id,
            alarmId: alarmId,
            scheduledAt: scheduledAt,
            firedAt: firedAt,
            action: action,
            snoozeCount: snoozeCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AlarmEventsTable, AlarmEvent>(table),
                    $$AlarmEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({alarmId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (alarmId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.alarmId,
                    referencedTable:
                        $$AlarmEventsTableReferences._alarmIdTable(db),
                    referencedColumn:
                        $$AlarmEventsTableReferences._alarmIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AlarmEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlarmEventsTable,
    AlarmEvent,
    $$AlarmEventsTableFilterComposer,
    $$AlarmEventsTableOrderingComposer,
    $$AlarmEventsTableAnnotationComposer,
    $$AlarmEventsTableCreateCompanionBuilder,
    $$AlarmEventsTableUpdateCompanionBuilder,
    (AlarmEvent, $$AlarmEventsTableReferences),
    AlarmEvent,
    PrefetchHooks Function({bool alarmId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
  $$AlarmEventsTableTableManager get alarmEvents =>
      $$AlarmEventsTableTableManager(_db, _db.alarmEvents);
}
