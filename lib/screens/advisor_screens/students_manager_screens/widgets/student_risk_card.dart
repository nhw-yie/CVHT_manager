import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';
import '../../../../constants/app_colors.dart';
import '../../../../theme/app_theme.dart';

/// Reusable Student Risk Card
///
/// Displays a compact card with student's avatar, risk badge, key metrics and
/// optional full details (risk reasons). Designed to be information-dense but
/// readable in lists and grids.
class StudentRiskCard extends StatelessWidget {
  /// Student data map (see spec in file header)
  final Map<String, dynamic> student;

  /// Tap handler (required)
  final VoidCallback onTap;

  /// When true show expanded details (reasons); otherwise show compact row
  final bool showFullDetails;

  /// Optional override for risk level colors
  final Map<String, Color>? riskColors;

  const StudentRiskCard({Key? key, required this.student, required this.onTap, this.showFullDetails = false, this.riskColors}) : super(key: key);

  // Map risk level to colors and icons
  Color _colorForRisk(String level) {
    final l = level.toLowerCase();
    if (riskColors != null && riskColors!.containsKey(l)) {
      return riskColors![l]!;
    }
    switch (l) {
      case 'critical':
        return const Color(0xFF8B0000);
      case 'high':
        return const Color(0xFFDC143C);
      case 'medium':
        return const Color(0xFFFF6B6B);
      case 'low':
      default:
        return const Color(0xFFFFA500);
    }
  }

  // Helper to parse numeric fields safely
  double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final name = (student['full_name'] ?? student['name'] ?? '').toString();
    final code = (student['user_code'] ?? student['student_code'] ?? student['student_id'] ?? '').toString();
    final risk = (student['risk_level'] ?? 'low').toString().toLowerCase();
    final riskColor = _colorForRisk(risk);
    final borderColor = riskColor.withOpacity(0.12);

    // Metrics
    final cpa = _toDouble(student['cpa_4_scale'] ?? student['cpa'] ?? student['CPA']);
    final absenceRate = _toDouble(student['absence_rate'] ?? student['absenceRate']);
    final trainingPoints = _toDouble(student['training_points'] ?? student['trainingPoints']);

    // Alerts
    final cpaAlert = (cpa != null && cpa < 2.0);
    final absenceAlert = (absenceRate != null && absenceRate > 40.0);
    final trainingAlert = (trainingPoints != null && trainingPoints < 65.0);

    // Reasons
    final reasons = (student['risk_reasons'] is List) ? List<String>.from(student['risk_reasons']) : <String>[];

    return CustomCard(
      elevation: 2,
      borderRadius: AppRadius.base,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.base,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: AppRadius.base),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row: risk badge, name, code
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.report_problem, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(risk.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 12),
              // Name & code
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(code, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              ),
            ]),

            const SizedBox(height: 12),

            // Metrics row: CPA | Absence | Training points
            Row(children: [
              Expanded(child: _metricColumn(Icons.school, 'CPA', cpa != null ? cpa.toStringAsFixed(2) : '-', alert: cpaAlert)),
              Expanded(child: _metricColumn(Icons.event_busy, 'Vắng(%)', absenceRate != null ? absenceRate.toStringAsFixed(1) : '-', alert: absenceAlert)),
              Expanded(child: _metricColumn(Icons.star, 'Điểm RL', trainingPoints != null ? trainingPoints.toStringAsFixed(0) : '-', alert: trainingAlert)),
            ]),

            // Risk reasons (optional expanded view)
            if (showFullDetails && reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (var i = 0; i < (reasons.length > 2 ? 2 : reasons.length); i++) Chip(label: Text(reasons[i])),
                if (reasons.length > 2) Chip(label: Text('+ ${reasons.length - 2} more')),
              ]),
            ],

            // Action row when not expanded
            if (!showFullDetails) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(onPressed: onTap, icon: const Icon(Icons.chevron_right), label: const Text('Xem chi tiết')),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  // Metric column helper widget
  Widget _metricColumn(IconData icon, String label, String value, {bool alert = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: alert ? AppColors.error : Colors.grey.shade700), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))]),
      const SizedBox(height: 6),
      Row(children: [Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: alert ? AppColors.error : Colors.black87)), if (alert) const SizedBox(width: 6), if (alert) const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning)]),
    ]);
  }
}
