import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/alarm_list_provider.dart';
import '../../../data/local/database.dart';
import '../../../core/utils/time_utils.dart';
import 'widgets/alarm_card.dart';
import 'edit_alarm_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class AlarmDashboardScreen extends ConsumerWidget {
  const AlarmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmListStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgMain, // --bg-dark
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: alarmsAsync.when(
                data: (alarms) => _buildContent(context, alarms, ref),
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, st) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditAlarmScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.alarm_on, color: AppTheme.primary, size: 24),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAKEUP+',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'Báo Thức',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    'U',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Alarm> alarms, WidgetRef ref) {
    // Tìm báo thức bật gần nhất để show lên NextAlarmCard
    Alarm? nextAlarm;
    DateTime? nextTime;

    for (var alarm in alarms) {
      if (alarm.enabled) {
        final time = TimeUtils.calculateNextAlarmTime(alarm.hour, alarm.minute, alarm.repeatDays, skipNextDate: alarm.skipNextDate);
        if (nextTime == null || time.isBefore(nextTime)) {
          nextTime = time;
          nextAlarm = alarm;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        _buildListHeader(alarms.length),
        if (nextAlarm != null && nextTime != null) ...[
          const SizedBox(height: 16),
          _buildNextAlarmCard(nextAlarm, nextTime),
        ],
        const SizedBox(height: 16),
        _buildProtectionBanner(),
        const SizedBox(height: 16),
        ...alarms.map((alarm) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AlarmCard(alarm: alarm),
        )),
      ],
    );
  }

  Widget _buildListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Danh sách',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count chuông',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNextAlarmCard(Alarm alarm, DateTime nextTime) {
    final difference = nextTime.difference(DateTime.now());
    final hours = difference.inHours;
    final mins = difference.inMinutes % 60;
    
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final dayString = days[nextTime.weekday % 7];
    final timeString = '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2220), Color(0xFF1C191D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kế tiếp sau ${hours}h ${mins}p',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$dayString, $timeString',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${alarm.label ?? 'Báo thức'} • ${alarm.soundId}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2724),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF25A18E).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF25A18E)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hệ thống bảo vệ đang bật',
                  style: TextStyle(color: Color(0xFF25A18E), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Bảo đảm chuông kêu đúng giờ 100%',
                  style: TextStyle(color: Color(0xFF8DAEA8), fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF25A18E).withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 28),
            ),
            child: const Text('Chi tiết', style: TextStyle(color: Color(0xFF25A18E), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

}
