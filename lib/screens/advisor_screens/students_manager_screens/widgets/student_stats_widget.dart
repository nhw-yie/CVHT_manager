import 'package:flutter/material.dart';

/// Small stat card used on the overview tab.
class StudentStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? sub;

  const StudentStatCard({Key? key, required this.title, required this.value, this.sub}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), if (sub != null) Text(sub!, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
