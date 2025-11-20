import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.gradient,
    this.backgroundColor,
    this.elevation = 0.5,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      centerTitle: false,
      elevation: elevation,
      backgroundColor: gradient == null ? bg : null,
      leading: showBackButton ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)) : null,
      actions: actions,
      flexibleSpace: gradient != null
          ? Container(
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.small))),
            )
          : null,
    );
  }
}
