import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

enum CustomButtonStyle { primary, secondary, outlined }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool disabled;
  final CustomButtonStyle style;

  const CustomButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.style = CustomButtonStyle.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = disabled || isLoading || onPressed == null;

    switch (style) {
      case CustomButtonStyle.secondary:
        return ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppRadius.base)),
          child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : child,
        );
      case CustomButtonStyle.outlined:
        return OutlinedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: AppRadius.base)),
          child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : child,
        );
      case CustomButtonStyle.primary:
        return ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: AppRadius.base)),
          child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : child,
        );
    }
  }
}
