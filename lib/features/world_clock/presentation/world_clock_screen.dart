import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class WorldClockScreen extends StatelessWidget {
  const WorldClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Giờ Thế giới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () {
              // TODO: Mở danh sách tìm kiếm múi giờ
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCityCard('Hà Nội', 'Hôm nay, +0H', '14:30', true),
          const SizedBox(height: 16),
          _buildCityCard('New York', 'Hôm qua, -11H', '03:30', false),
          const SizedBox(height: 16),
          _buildCityCard('Tokyo', 'Hôm nay, +2H', '16:30', true),
          const SizedBox(height: 16),
          _buildCityCard('London', 'Hôm nay, -7H', '07:30', true),
        ],
      ),
    );
  }

  Widget _buildCityCard(String city, String diff, String time, bool isDay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                diff,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}
