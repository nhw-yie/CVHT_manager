// lib/widgets/statistics_widgets.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatisticsCard extends StatelessWidget {
  final String title;
  final List<StatItem> items;
  final Color? color;

  const StatisticsCard({
    Key? key,
    required this.title,
    required this.items,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildStatRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(StatItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 20,
              color: color ?? AppColors.primary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData? icon;

  StatItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

class CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CompactStatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class GradeDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const GradeDistributionChart({
    Key? key,
    required this.distribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bố điểm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return _buildDistributionBar(
                entry.key,
                entry.value,
                percentage,
                _getColorForGrade(entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$count ($percentage%)', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: double.parse(percentage) / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Color _getColorForGrade(String grade) {
    switch (grade.toLowerCase()) {
      case 'xuất sắc':
      case 'excellent':
        return Colors.green;
      case 'giỏi':
      case 'good':
        return Colors.blue;
      case 'khá':
      case 'average':
        return Colors.orange;
      case 'trung bình':
      case 'below_average':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}

class PointsBreakdown extends StatelessWidget {
  final double trainingPoints;
  final double socialPoints;
  final double maxTraining;
  final double maxSocial;

  const PointsBreakdown({
    Key? key,
    required this.trainingPoints,
    required this.socialPoints,
    this.maxTraining = 100,
    this.maxSocial = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điểm rèn luyện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPointBar(
              'Rèn luyện',
              trainingPoints,
              maxTraining,
              Colors.blue,
              Icons.fitness_center,
            ),
            const SizedBox(height: 16),
            _buildPointBar(
              'CTXH',
              socialPoints,
              maxSocial,
              Colors.green,
              Icons.volunteer_activism,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointBar(String label, double value, double max, Color color, IconData icon) {
    final percentage = (value / max * 100).clamp(0, 100);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}/$max',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 10,
        ),
      ],
    );
  }
}