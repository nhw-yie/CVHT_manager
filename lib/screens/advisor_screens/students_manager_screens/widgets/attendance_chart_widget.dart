import 'package:flutter/material.dart';

/// Placeholder attendance chart widget.
class AttendanceChartWidget extends StatelessWidget {
  final List<dynamic> data;
  const AttendanceChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Colors.grey.shade100,
      child: const Center(child: Text('Attendance chart placeholder')),
    );
  }
}
