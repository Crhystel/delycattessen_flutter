import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Modal dialog strictly used for user action confirmation (e.g. Logout, Cancel).
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final IconData? icon;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.confirmColor = AppColors.danger500,
    this.icon,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    Color confirmColor = AppColors.danger500,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: confirmColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: confirmColor, size: 28),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink900.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.ink900.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
