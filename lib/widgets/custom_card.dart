import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const CustomCard({Key? key, required this.child, this.padding, this.elevation = 1, this.borderRadius, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding ?? const EdgeInsets.all(12.0), child: child);
    final card = Card(elevation: elevation, shape: RoundedRectangleBorder(borderRadius: borderRadius ?? AppRadius.base), child: content);
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: borderRadius ?? AppRadius.base, child: card);
    return card;
  }
}
