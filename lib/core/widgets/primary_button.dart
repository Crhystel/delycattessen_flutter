import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Main call-to-action button (morado). Use one per screen.
///
/// Con [design] = true toma las medidas del rediseño del padre (54 de alto,
/// radio 27, texto 16/800) y, con [shadow], la sombra morada de los botones
/// fijos al pie. Sin él queda igual que siempre para el resto de roles.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool design;
  final bool shadow;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.design = false,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = design ? 54.0 : 50.0;
    final style = ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary500,
      foregroundColor: Colors.white,
      minimumSize: Size.fromHeight(height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height / 2),
      ),
      elevation: 0,
    );
    final text = Text(
      label,
      style: TextStyle(
        fontWeight: design ? FontWeight.w800 : FontWeight.w700,
        fontSize: 16,
      ),
    );
    final enabled = isLoading ? null : onPressed;

    final Widget button;
    if (isLoading) {
      button = ElevatedButton(
        onPressed: enabled,
        style: style,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    } else if (icon == null) {
      button = ElevatedButton(onPressed: enabled, style: style, child: text);
    } else {
      button = ElevatedButton.icon(
        onPressed: enabled,
        style: style,
        icon: Icon(icon, size: design ? 18 : 20),
        label: text,
      );
    }

    if (!(design && shadow) || enabled == null) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: button,
    );
  }
}
