import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final double? fontSize;

  const StatusBadge({Key? key, required this.label, this.fontSize}) : super(key: key);

  Color _colorFor(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('đủ') || lower.contains('eligible') || lower.contains('passed')) return AppColors.success;
    if (lower.contains('cảnh') || lower.contains('warn') || lower.contains('review')) return AppColors.warning;
    if (lower.contains('fail') || lower.contains('không') || lower.contains('rejected')) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(color: color, fontSize: fontSize ?? 12)));
  }
}
