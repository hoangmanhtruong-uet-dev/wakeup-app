import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database.dart';
import '../../providers/alarm_list_provider.dart';
import '../edit_alarm_screen.dart';

class AlarmCard extends ConsumerWidget {
  final Alarm alarm;

  const AlarmCard({super.key, required this.alarm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isEnabled = alarm.enabled;
    final opacity = isEnabled ? 1.0 : 0.5;

    final isAM = alarm.hour < 12;
    final displayHour = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour);
    final displayMinute = alarm.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAlarmScreen(existingAlarm: alarm),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF191E2B),
          borderRadius: BorderRadius.circular(16),
        ),
      child: Opacity(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Time & Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${displayHour.toString().padLeft(2, '0')}:$displayMinute',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAM ? 'AM' : 'PM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? const Color(0xFFFFB16F) : const Color(0xFF8B92A5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alarm.label ?? 'Báo thức',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8B92A5),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (val) {
                    ref.read(alarmControllerProvider).toggleAlarm(alarm, val);
                  },
                  activeThumbColor: const Color(0xFF3E220A),
                  activeTrackColor: const Color(0xFFFFB16F),
                  inactiveThumbColor: const Color(0xFF8B92A5),
                  inactiveTrackColor: const Color(0xFF2B3040),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Days Bitmask
            if (alarm.repeatDays > 0)
              _buildDaysRow()
            else
              const Text(
                'Một lần • Ngày mai', // TODO: Dynamically calculate if it's tomorrow or today
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8B92A5)),
              ),
            
            const SizedBox(height: 16),
            
            // Details Row
            Row(
              children: [
                _buildDetailItem(Icons.music_note, alarm.soundId),
                if (alarm.vibrate) ...[
                  const SizedBox(width: 16),
                  _buildDetailItem(Icons.vibration, 'Rung'),
                ],
                if (alarm.missionEnabled) ...[
                  const SizedBox(width: 16),
                  _buildDetailItem(Icons.calculate, 'Toán'),
                ],
              ],
            )
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDaysRow() {
    final days = [
      {'label': 'T2', 'mask': 1},
      {'label': 'T3', 'mask': 2},
      {'label': 'T4', 'mask': 4},
      {'label': 'T5', 'mask': 8},
      {'label': 'T6', 'mask': 16},
      {'label': 'T7', 'mask': 32, 'isWeekend': true},
      {'label': 'CN', 'mask': 64, 'isWeekend': true},
    ];

    return Row(
      children: days.map((day) {
        final isActive = (alarm.repeatDays & (day['mask'] as int)) != 0;
        final isWeekend = day['isWeekend'] == true;
        
        Color bgColor = const Color(0xFF222736);
        Color textColor = const Color(0xFF8B92A5);

        if (isActive) {
          bgColor = isWeekend ? const Color(0xFF25A18E) : const Color(0xFFFFB16F);
          textColor = Colors.black;
        }

        return Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            day['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8B92A5)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8B92A5),
          ),
        ),
      ],
    );
  }
}
