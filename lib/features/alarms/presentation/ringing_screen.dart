import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/native_alarm_service.dart';
import '../../../data/repositories/alarm_repository.dart';
import '../../../data/repositories/alarm_repository_provider.dart';
import '../../../core/app_router.dart';
import 'missions/math_mission_screen.dart';

class RingingScreen extends ConsumerStatefulWidget {
  final int alarmId;
  final String label;
  final String soundId;
  final double volume;

  /// Thời gian tự dừng chuông nếu người dùng không tương tác (phút).
  /// Yêu cầu F-07 trong REQUIREMENTS.md.
  final int autoStopMinutes;

  /// Thời điểm báo thức dự kiến vang, dùng làm mốc tính lần kêu kế tiếp.
  /// Nếu `null` thì dùng thời gian hiện tại (đủ chính xác cho báo thức lặp).
  final DateTime? scheduledFiredAt;

  const RingingScreen({
    super.key,
    required this.alarmId,
    required this.label,
    this.soundId = 'alarm_default',
    this.volume = 1.0,
    this.autoStopMinutes = 10,
    this.scheduledFiredAt,
  });

  @override
  ConsumerState<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends ConsumerState<RingingScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  double _slideValue = 0.0;
  Alarm? _cachedAlarm;

  int get _realId => widget.alarmId >= AlarmRepository.snoozeIdOffset
      ? widget.alarmId - AlarmRepository.snoozeIdOffset
      : widget.alarmId;

  @override
  void initState() {
    super.initState();
    _loadAlarm();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    // Bắt đầu phát chuông lặp.
    // - Trên iOS: BẮT BUỘC, vì notification chỉ kêu được ~30s. AlarmAudioPlayer phát tiếp
    //   bằng AVAudioSession category `.playback` (vượt qua công tắc Silent).
    // - Trên Android: no-op, vì AlarmService (Foreground Service) đã tự phát.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NativeAlarmService.startRinging(
        soundId: widget.soundId,
        volume: widget.volume,
        autoStopMinutes: widget.autoStopMinutes,
      );
    });
  }

  Future<void> _loadAlarm() async {
    try {
      final alarm = await ref.read(databaseProvider).getAlarm(_realId);
      if (mounted) {
        setState(() {
          _cachedAlarm = alarm;
        });
      }
    } catch (_) {
      // Alarm might have been deleted or not found
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _snoozeAlarm() async {
    final realId = _realId;

    // 1. Dừng chuông đang kêu + huỷ chuỗi notification còn sót (quan trọng trên iOS)
    await NativeAlarmService.stopRinging(id: widget.alarmId);

    // 2. Ghi lịch sử "snoozed" + lấy lại lịch cho lần kêu định kỳ kế tiếp.
    final repo = ref.read(alarmRepositoryProvider);
    await repo.snooze(realId, firedAt: _referenceFiredAt());

    // 3. Quay về dashboard
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRouter()),
        (route) => false,
      );
    }
  }

  /// Mốc thời gian dùng để tính "lần kêu tiếp theo".
  ///
  /// Vì chuông vang gần như đúng thời điểm đã hẹn, dùng `DateTime.now()` là đủ chính
  /// xác cho mọi trường hợp lặp (ngày / tuần). Ta vẫn cho phép truyền
  /// [scheduledFiredAt] từ phía gọi để chính xác hơn nếu có.
  DateTime _referenceFiredAt() {
    return widget.scheduledFiredAt ?? _currentTime;
  }

  void _dismissAlarm() async {
    final realId = _realId;

    Alarm? alarm = _cachedAlarm;
    if (alarm == null) {
      try {
        alarm = await ref.read(databaseProvider).getAlarm(realId);
      } catch (_) {
        alarm = null;
      }
    }

    final missionEnabled = alarm?.missionEnabled ?? false;

    if (missionEnabled) {
      MathDifficulty difficulty = MathDifficulty.medium;
      if (alarm?.missionDifficulty == 'easy') {
        difficulty = MathDifficulty.easy;
      } else if (alarm?.missionDifficulty == 'hard') {
        difficulty = MathDifficulty.hard;
      }

      if (!mounted) return;
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MathMissionScreen(
            difficulty: difficulty,
            requiredQuestions: 3,
          ),
        ),
      );

      // Nếu không hoàn thành nhiệm vụ, không tắt chuông
      if (success != true) {
        return;
      }
    }

    // Tắt chuông tại native engine
    await NativeAlarmService.stopRinging(id: widget.alarmId);

    // Ghi lịch sử + lập lịch cho lần kêu định kỳ kế tiếp (nếu là báo thức lặp)
    final repo = ref.read(alarmRepositoryProvider);
    await repo.rescheduleAfterFire(
      realId,
      firedAt: _referenceFiredAt(),
      action: 'dismissed',
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRouter()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Icon(Icons.alarm, color: AppTheme.primary, size: 40),
                const SizedBox(height: 16),
                Text(
                  widget.label.isNotEmpty ? widget.label : 'Báo thức',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            Column(
              children: [
                // Nút Snooze to, dễ bấm khi ngái ngủ
                GestureDetector(
                  onTap: _snoozeAlarm,
                  child: Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'BÁO LẠI (SNOOZE)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),

                // Trượt để tắt (Slider to dismiss)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Text(
                            'Trượt để Tắt >>>',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          left: _slideValue,
                          top: 5,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _slideValue += details.delta.dx;
                                if (_slideValue < 0) _slideValue = 0;
                                // Giới hạn chiều rộng thanh trượt (ước lượng khoảng 250px)
                                final maxWidth = MediaQuery.of(context).size.width - 80 - 60;
                                if (_slideValue > maxWidth) {
                                  _slideValue = maxWidth;
                                }
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              final maxWidth = MediaQuery.of(context).size.width - 80 - 60;
                              if (_slideValue >= maxWidth * 0.9) {
                                _dismissAlarm();
                              } else {
                                setState(() {
                                  _slideValue = 0;
                                });
                              }
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.power_settings_new, color: Colors.black, size: 30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
