import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/local/native_alarm_service.dart';

class TimerStopwatchScreen extends ConsumerStatefulWidget {
  const TimerStopwatchScreen({super.key});

  @override
  ConsumerState<TimerStopwatchScreen> createState() => _TimerStopwatchScreenState();
}

class _TimerStopwatchScreenState extends ConsumerState<TimerStopwatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'BẤM GIỜ'),
            Tab(text: 'HẸN GIỜ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StopwatchView(),
          TimerView(),
        ],
      ),
    );
  }
}

// === STOPWATCH (BẤM GIỜ) ===
class _StopwatchView extends StatefulWidget {
  const _StopwatchView();

  @override
  State<_StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<_StopwatchView> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  void _startStopTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {}); // Cập nhật UI liên tục
      });
    }
    setState(() {});
  }

  void _lapOrReset() {
    setState(() {
      if (_stopwatch.isRunning) {
        // Ghi lại Lap
        _laps.insert(0, _formatDuration(_stopwatch.elapsed));
      } else {
        // Reset
        _stopwatch.reset();
        _laps.clear();
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}.${threeDigits(d.inMilliseconds.remainder(1000)).substring(0, 2)}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatDuration(_stopwatch.elapsed);
    final isRunning = _stopwatch.isRunning;

    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircleButton(
              label: isRunning ? 'Vòng' : 'Đặt lại',
              color: Colors.white.withValues(alpha: 0.1),
              textColor: Colors.white,
              onPressed: _lapOrReset,
            ),
            _buildCircleButton(
              label: isRunning ? 'Dừng' : 'Bắt đầu',
              color: isRunning
                  ? Colors.red.withValues(alpha: 0.2)
                  : AppTheme.primary.withValues(alpha: 0.2),
              textColor: isRunning ? Colors.redAccent : AppTheme.primary,
              onPressed: _startStopTimer,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _laps.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Vòng ${_laps.length - index}', style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  _laps[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// === TIMER (HẸN GIỜ) ===

/// Trạng thái hoạt động của bộ đếm hẹn giờ.
enum TimerMode { setup, running, paused, ringing }

class TimerView extends StatefulWidget {
  const TimerView({
    super.key,
    this.initialDuration = const Duration(minutes: 15),
  });

  final Duration initialDuration;

  @override
  State<TimerView> createState() => TimerViewState();
}

class TimerViewState extends State<TimerView> {
  late TimerMode _mode;
  late Duration _selectedDuration;
  late int _initialTotalSeconds;
  late int _secondsRemaining;

  Timer? _timer;
  Timer? _vibrationTimer;
  bool _isModalShowing = false;
  Key _pickerKey = UniqueKey();

  TimerMode get mode => _mode;
  int get secondsRemaining => _secondsRemaining;
  int get initialTotalSeconds => _initialTotalSeconds;
  Duration get selectedDuration => _selectedDuration;

  @override
  void initState() {
    super.initState();
    _mode = TimerMode.setup;
    _selectedDuration = widget.initialDuration;
    _initialTotalSeconds = widget.initialDuration.inSeconds;
    _secondsRemaining = widget.initialDuration.inSeconds;
  }

  void _addPresetMinutes(int minutes) {
    setState(() {
      final currentSeconds = _selectedDuration.inSeconds;
      final targetSeconds = (currentSeconds + minutes * 60).clamp(0, 23 * 3600 + 59 * 60 + 59);
      _selectedDuration = Duration(seconds: targetSeconds);
      _pickerKey = UniqueKey();
    });
  }

  void _startTimer() {
    if (_selectedDuration.inSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời lượng lớn hơn 0 giây.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _initialTotalSeconds = _selectedDuration.inSeconds;
      _secondsRemaining = _selectedDuration.inSeconds;
      _mode = TimerMode.running;
    });
    _runPeriodicTimer();
  }

  void _runPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_secondsRemaining <= 0) {
          _timer?.cancel();
          _mode = TimerMode.ringing;
        }
      });
      if (_secondsRemaining <= 0) {
        _triggerRinging();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _mode = TimerMode.paused;
    });
  }

  void _resumeTimer() {
    setState(() {
      _mode = TimerMode.running;
    });
    _runPeriodicTimer();
  }

  void _resetToSetup() {
    _timer?.cancel();
    setState(() {
      _mode = TimerMode.setup;
      _secondsRemaining = _initialTotalSeconds;
    });
  }

  void _triggerRinging() {
    NativeAlarmService.startRinging(
      soundId: 'alarm_default',
      volume: 1.0,
      autoStopMinutes: 10,
    );
    HapticFeedback.vibrate();

    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      HapticFeedback.vibrate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mode != TimerMode.ringing || _isModalShowing) return;
      _isModalShowing = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_on, color: AppTheme.primary, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'Hết giờ!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Bộ đếm ${_formatSeconds(_initialTotalSeconds)} đã kết thúc.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _stopRinging,
                    child: const Text(
                      'Dừng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        _isModalShowing = false;
      });
    });
  }

  void _stopRinging() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    NativeAlarmService.stopRinging();

    if (_isModalShowing && mounted) {
      _isModalShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (mounted) {
      setState(() {
        _mode = TimerMode.setup;
        _secondsRemaining = _initialTotalSeconds;
      });
    }
  }

  String _formatSeconds(int totalSecs) {
    final int hours = totalSecs ~/ 3600;
    final int minutes = (totalSecs % 3600) ~/ 60;
    final int seconds = totalSecs % 60;
    final String hStr = hours.toString().padLeft(2, '0');
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');
    if (hours > 0 || _initialTotalSeconds >= 3600) {
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    if (_mode == TimerMode.ringing) {
      NativeAlarmService.stopRinging();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case TimerMode.setup:
        return _buildSetupView();
      case TimerMode.running:
      case TimerMode.paused:
        return _buildActiveView();
      case TimerMode.ringing:
        return _buildRingingView();
    }
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                pickerTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
            child: SizedBox(
              height: 200,
              child: CupertinoTimerPicker(
                key: _pickerKey,
                mode: CupertinoTimerPickerMode.hms,
                initialTimerDuration: _selectedDuration,
                onTimerDurationChanged: (Duration newDuration) {
                  setState(() {
                    _selectedDuration = newDuration;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPresetChip('+1m', 1),
                const SizedBox(width: 8),
                _buildPresetChip('+5m', 5),
                const SizedBox(width: 8),
                _buildPresetChip('+10m', 10),
                const SizedBox(width: 8),
                _buildPresetChip('+15m', 15),
                const SizedBox(width: 8),
                _buildPresetChip('+30m', 30),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildActionButton(
            label: 'Bắt đầu',
            icon: Icons.play_arrow,
            color: AppTheme.primary.withValues(alpha: 0.2),
            textColor: AppTheme.primary,
            onPressed: _startTimer,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int minutes) {
    return ActionChip(
      backgroundColor: AppTheme.bgCard,
      side: const BorderSide(color: Colors.white12),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onPressed: () => _addPresetMinutes(minutes),
    );
  }

  Widget _buildActiveView() {
    final progress = _initialTotalSeconds > 0
        ? (_secondsRemaining / _initialTotalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final timeStr = _formatSeconds(_secondsRemaining);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                color: _mode == TimerMode.paused ? Colors.orangeAccent : AppTheme.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == TimerMode.paused ? 'Đã tạm dừng' : 'Đang đếm ngược',
                  style: TextStyle(
                    fontSize: 14,
                    color: _mode == TimerMode.paused ? Colors.orangeAccent : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              label: 'Đặt lại',
              icon: Icons.replay,
              color: AppTheme.bgCard,
              textColor: Colors.white,
              onPressed: _resetToSetup,
            ),
            _buildActionButton(
              label: _mode == TimerMode.running ? 'Tạm dừng' : 'Tiếp tục',
              icon: _mode == TimerMode.running ? Icons.pause : Icons.play_arrow,
              color: _mode == TimerMode.running
                  ? Colors.orange.withValues(alpha: 0.2)
                  : AppTheme.primary.withValues(alpha: 0.2),
              textColor: _mode == TimerMode.running ? Colors.orangeAccent : AppTheme.primary,
              onPressed: _mode == TimerMode.running ? _pauseTimer : _resumeTimer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRingingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.alarm_on, color: AppTheme.primary, size: 96),
        const SizedBox(height: 24),
        const Text(
          'Hết giờ!',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'Bộ đếm ${_formatSeconds(_initialTotalSeconds)} đã kết thúc',
          style: const TextStyle(fontSize: 18, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 48),
        _buildActionButton(
          label: 'Dừng',
          icon: Icons.stop,
          color: Colors.red.withValues(alpha: 0.2),
          textColor: Colors.redAccent,
          onPressed: _stopRinging,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: textColor, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
