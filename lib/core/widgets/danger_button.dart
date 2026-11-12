import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Outlined red button for actions that end something ("Cerrar sesión",
/// "Dar de baja"): 54 high, white background, 1.5 red border and dark red text.
/// With [isLoading] it shows a spinner and ignores taps.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.danger700,
      side: const BorderSide(color: AppColors.danger500, width: 1.5),
      shape: const StadiumBorder(),
    );
    final text = Text(
      label,
      style: AppText.button.copyWith(color: AppColors.danger700),
    );
    final enabled = isLoading ? null : onPressed;

    if (isLoading) {
      return OutlinedButton(
        onPressed: enabled,
        style: style,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.danger700,
          ),
        ),
      );
    }
    if (icon == null) {
      return OutlinedButton(onPressed: enabled, style: style, child: text);
    }
    return OutlinedButton.icon(
      onPressed: enabled,
      icon: Icon(icon, size: 20),
      label: text,
      style: style,
    );
  }
}
