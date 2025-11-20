import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final double size;

  const BadgeIcon({Key? key, required this.icon, this.count = 0, this.size = 24}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon, size: size);
    final label = count > 99 ? '99+' : count.toString();
    return Stack(clipBehavior: Clip.none, children: [
      Icon(icon, size: size),
      Positioned(right: -6, top: -6, child: CircleAvatar(radius: 9, backgroundColor: Colors.red, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)))),
    ]);
  }
}
