import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../data/local/native_alarm_service.dart';

enum MathDifficulty { easy, medium, hard }

class MathMissionScreen extends StatefulWidget {
  final MathDifficulty difficulty;
  final int requiredQuestions;

  const MathMissionScreen({
    super.key,
    this.difficulty = MathDifficulty.medium,
    this.requiredQuestions = 3,
  });

  @override
  State<MathMissionScreen> createState() => _MathMissionScreenState();
}

class _MathMissionScreenState extends State<MathMissionScreen> {
  late int _remainingQuestions;
  String _currentQuestion = '';
  int _currentAnswer = 0;
  String _userInput = '';

  @override
  void initState() {
    super.initState();
    _remainingQuestions = widget.requiredQuestions;
    _generateQuestion();
  }

  void _generateQuestion() {
    final rand = Random();
    int a, b, c;

    switch (widget.difficulty) {
      case MathDifficulty.easy:
        // Ex: 12 + 34
        a = rand.nextInt(90) + 10;
        b = rand.nextInt(90) + 10;
        _currentQuestion = '$a + $b';
        _currentAnswer = a + b;
        break;
      case MathDifficulty.medium:
        // Ex: 45 + 23 + 12 or 12 * 5
        if (rand.nextBool()) {
          a = rand.nextInt(90) + 10;
          b = rand.nextInt(90) + 10;
          c = rand.nextInt(50) + 10;
          _currentQuestion = '$a + $b + $c';
          _currentAnswer = a + b + c;
        } else {
          a = rand.nextInt(15) + 2;
          b = rand.nextInt(10) + 2;
          _currentQuestion = '$a × $b';
          _currentAnswer = a * b;
        }
        break;
      case MathDifficulty.hard:
        // Ex: (124 + 345) * 2
        a = rand.nextInt(400) + 100;
        b = rand.nextInt(400) + 100;
        c = rand.nextInt(8) + 2;
        _currentQuestion = '($a + $b) × $c';
        _currentAnswer = (a + b) * c;
        break;
    }
    _userInput = '';
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == 'C') {
        _userInput = '';
      } else if (value == 'DEL') {
        if (_userInput.isNotEmpty) {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        }
      } else {
        // Prevent typing too long
        if (_userInput.length < 5) {
          _userInput += value;
        }
      }
    });

    _checkAnswer();
  }

  void _checkAnswer() {
    if (_userInput.isNotEmpty && int.tryParse(_userInput) == _currentAnswer) {
      setState(() {
        _remainingQuestions--;
        if (_remainingQuestions <= 0) {
          _completeMission();
        } else {
          _generateQuestion();
        }
      });
    }
  }

  void _completeMission() async {
    // Dừng âm thanh báo thức từ Native
    await NativeAlarmService.stopRinging();
    if (mounted) {
      Navigator.pop(context, true); // Trả về true báo hiệu hoàn thành nhiệm vụ
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Khóa phím Back hệ thống để bắt buộc giải đố
      child: Scaffold(
        backgroundColor: AppTheme.bgMain,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                'Giải toán để tắt chuông',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Còn lại: $_remainingQuestions câu',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              
              const Spacer(),

              // Question
              Text(
                _currentQuestion,
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              
              // Answer Field
              Container(
                width: 200,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _userInput.isNotEmpty ? AppTheme.primary : AppTheme.borderLight,
                    width: 2,
                  )
                ),
                child: Text(
                  _userInput.isEmpty ? '?' : _userInput,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _userInput.isEmpty ? AppTheme.textMuted : AppTheme.primary,
                  ),
                ),
              ),

              const Spacer(),

              // Numpad
              _buildNumpad(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'DEL'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                return _buildNumKey(key);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumKey(String value) {
    final isAction = value == 'C' || value == 'DEL';
    
    return GestureDetector(
      onTap: () => _onKeyPressed(value),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isAction ? AppTheme.bgCard : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: isAction && value == 'DEL'
            ? const Icon(Icons.backspace, color: AppTheme.textMuted)
            : Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isAction ? AppTheme.textMuted : Colors.white,
                ),
              ),
      ),
    );
  }
}
