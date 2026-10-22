import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.secondary500,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
    final enabled = isLoading ? null : onPressed;

    if (isLoading) {
      return ElevatedButton(
        onPressed: enabled,
        style: style,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
