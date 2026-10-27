import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SleepSoundscapeScreen extends StatefulWidget {
  const SleepSoundscapeScreen({super.key});

  @override
  State<SleepSoundscapeScreen> createState() => _SleepSoundscapeScreenState();
}

class _SleepSoundscapeScreenState extends State<SleepSoundscapeScreen> {
  // Thực tế ở Giai đoạn 4, mỗi slider này sẽ tương ứng với 1 AudioPlayer của just_audio
  double _rainVolume = 0.0;
  double _fireVolume = 0.0;
  double _whiteNoiseVolume = 0.0;
  double _forestVolume = 0.0;

  bool _isPlaying = false;
  int _timerMinutes = 0; // 0 nghĩa là không hẹn giờ tắt

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      // TODO: Gửi lệnh Play/Pause xuống các player của just_audio
    });
  }

  void _setTimer(int minutes) {
    setState(() {
      _timerMinutes = minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Âm thanh Giấc ngủ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer, color: AppTheme.primary),
            onPressed: () {
              _showTimerDialog();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_timerMinutes > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Hẹn giờ tắt dần sau: $_timerMinutes phút', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),

            Expanded(
              child: ListView(
                children: [
                  _buildSoundSlider('Tiếng Mưa rào', Icons.water_drop, _rainVolume, (val) => setState(() => _rainVolume = val)),
                  _buildSoundSlider('Lò sưởi cháy', Icons.local_fire_department, _fireVolume, (val) => setState(() => _fireVolume = val)),
                  _buildSoundSlider('Tiếng Ồn trắng (White Noise)', Icons.waves, _whiteNoiseVolume, (val) => setState(() => _whiteNoiseVolume = val)),
                  _buildSoundSlider('Rừng ban đêm', Icons.forest, _forestVolume, (val) => setState(() => _forestVolume = val)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Master Play/Pause Button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isPlaying ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: _isPlaying ? AppTheme.primary : Colors.black,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isPlaying ? 'Đang phát' : 'Đã tạm dừng', style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSlider(String title, IconData icon, double value, ValueChanged<double> onChanged) {
    final isActive = value > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isActive ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text('${(value * 100).toInt()}%', style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            activeColor: AppTheme.primary,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hẹn giờ tắt âm thanh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [0, 15, 30, 45, 60, 90, 120].map((mins) {
                  return ChoiceChip(
                    label: Text(mins == 0 ? 'Không hẹn giờ' : '$mins phút'),
                    selected: _timerMinutes == mins,
                    selectedColor: AppTheme.primary,
                    onSelected: (selected) {
                      _setTimer(mins);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
