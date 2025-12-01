import 'package:flutter/material.dart';

/// Placeholder GPA trend chart widget.
class GPATrendChart extends StatelessWidget {
  final List<dynamic> data;
  const GPATrendChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Colors.grey.shade100,
      child: const Center(child: Text('GPA trend chart placeholder')),
    );
  }
}
