import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/alarm_repository_provider.dart';
import 'package:drift/drift.dart' as drift;

class EditAlarmScreen extends ConsumerStatefulWidget {
  final Alarm? existingAlarm;

  const EditAlarmScreen({super.key, this.existingAlarm});

  @override
  ConsumerState<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends ConsumerState<EditAlarmScreen> {
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  bool _isVibrate = true;
  String _label = '';
  late final TextEditingController _labelController;
  bool _missionEnabled = false;
  String _missionType = 'math';
  String _missionDifficulty = 'medium';

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      _selectedTime = TimeOfDay(hour: widget.existingAlarm!.hour, minute: widget.existingAlarm!.minute);
      _selectedDays = _decodeRepeatDays(widget.existingAlarm!.repeatDays);
      _isVibrate = widget.existingAlarm!.vibrate;
      _label = widget.existingAlarm!.label ?? '';
      _missionEnabled = widget.existingAlarm!.missionEnabled;
      _missionType = widget.existingAlarm!.missionType;
      _missionDifficulty = widget.existingAlarm!.missionDifficulty;
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedDays = List.generate(7, (index) => false);
      _missionEnabled = false;
      _missionType = 'math';
      _missionDifficulty = 'medium';
    }
    _labelController = TextEditingController(text: _label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  List<bool> _decodeRepeatDays(int bitmask) {
    List<bool> days = List.generate(7, (index) => false);
    for (int i = 0; i < 7; i++) {
      if ((bitmask & (1 << i)) != 0) {
        days[i] = true;
      }
    }
    return days;
  }

  int _encodeRepeatDays(List<bool> days) {
    int bitmask = 0;
    for (int i = 0; i < 7; i++) {
      if (days[i]) {
        bitmask |= (1 << i);
      }
    }
    return bitmask;
  }

  Future<void> _saveAlarm() async {
    final repeatDays = _encodeRepeatDays(_selectedDays);
    final labelText = _labelController.text.trim();

    if (widget.existingAlarm == null) {
      final alarmData = AlarmsCompanion.insert(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        repeatDays: drift.Value(repeatDays),
        label: labelText.isEmpty ? const drift.Value.absent() : drift.Value(labelText),
        vibrate: drift.Value(_isVibrate),
        missionEnabled: drift.Value(_missionEnabled),
        missionType: drift.Value(_missionType),
        missionDifficulty: drift.Value(_missionDifficulty),
      );
      await ref.read(alarmRepositoryProvider).addAlarm(alarmData);
    } else {
      final updatedAlarm = widget.existingAlarm!.copyWith(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        repeatDays: repeatDays,
        label: drift.Value(labelText.isEmpty ? null : labelText),
        vibrate: _isVibrate,
        missionEnabled: _missionEnabled,
        missionType: _missionType,
        missionDifficulty: _missionDifficulty,
        skipNextDate: const drift.Value(null),
        updatedAt: DateTime.now(),
      );
      await ref.read(alarmRepositoryProvider).updateAlarm(updatedAlarm);
    }
    if (mounted) {
      Navigator.pop(context);
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
        title: Text(
          widget.existingAlarm == null ? 'Thêm báo thức' : 'Sửa báo thức',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primary),
            onPressed: _saveAlarm,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTimePicker(),
          const SizedBox(height: 30),
          _buildDaysSelector(),
          const SizedBox(height: 30),
          _buildSettingsList(),
          const SizedBox(height: 20),
          _buildMissionCard(),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return SizedBox(
      height: 220,
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: AppTheme.primary, 
              fontSize: 48,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: true,
          initialDateTime: DateTime(2023, 1, 1, _selectedTime.hour, _selectedTime.minute),
          onDateTimeChanged: (DateTime newDateTime) {
            setState(() {
              _selectedTime = TimeOfDay.fromDateTime(newDateTime);
            });
          },
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.bgCard,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Nhãn', style: TextStyle(color: Colors.white)),
            trailing: SizedBox(
              width: 150,
              child: TextField(
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppTheme.textMuted),
                decoration: const InputDecoration(
                  hintText: 'Báo thức',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                ),
                controller: _labelController,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            title: const Text('Rung', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: _isVibrate,
              activeThumbColor: AppTheme.primary,
              onChanged: (value) {
                setState(() => _isVibrate = value);
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            title: const Text('Nhạc chuông', style: TextStyle(color: Colors.white)),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mặc định', style: TextStyle(color: AppTheme.textMuted)),
                Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
            onTap: () {
              // TODO: Điều hướng sang màn hình chọn nhạc
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.psychology, color: AppTheme.primary),
            title: const Text(
              'Nhiệm vụ thức dậy',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Bắt buộc giải toán để tắt chuông',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            trailing: Switch(
              value: _missionEnabled,
              activeThumbColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
              onChanged: (value) {
                setState(() => _missionEnabled = value);
              },
            ),
          ),
          if (_missionEnabled) ...[
            const Divider(color: Colors.white10, height: 1),
            const ListTile(
              leading: Icon(Icons.calculate, color: AppTheme.cyan),
              title: Text('Loại nhiệm vụ', style: TextStyle(color: Colors.white)),
              trailing: Text(
                'Giải toán',
                style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: const Icon(Icons.speed, color: AppTheme.cyan),
              title: const Text('Độ khó', style: TextStyle(color: Colors.white)),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _missionDifficulty,
                  dropdownColor: AppTheme.bgCard,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(
                      value: 'easy',
                      child: Text('Dễ (2 chữ số +)'),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Vừa (+ / ×)'),
                    ),
                    DropdownMenuItem(
                      value: 'hard',
                      child: Text('Khó (3 chữ số ×)'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _missionDifficulty = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
