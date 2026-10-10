import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Main call-to-action button (yellow). Use one per screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: AppColors.brand500,
      foregroundColor: AppColors.ink900,
      minimumSize: const Size.fromHeight(52),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
    final enabled = isLoading ? null : onPressed;

    if (isLoading) {
      return ElevatedButton(
        onPressed: enabled,
        style: style,
        child: const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.ink900,
          ),
        ),
      );
    }
    if (icon == null) {
      return ElevatedButton(onPressed: enabled, style: style, child: text);
    }
    return ElevatedButton.icon(
      onPressed: enabled,
      style: style,
      icon: Icon(icon, size: 20),
      label: text,
    );
  }
}
