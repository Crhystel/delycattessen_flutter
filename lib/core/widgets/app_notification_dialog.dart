import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum NotificationType { success, danger, warning, info }

class _NotificationStyle {
  final Color iconBackground;
  final Color iconColor;
  final Color accentColor;
  final IconData icon;

  const _NotificationStyle({
    required this.iconBackground,
    required this.iconColor,
    required this.accentColor,
    required this.icon,
  });
}

class AppNotificationDialog extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String message;
  final String? highlightValue;
  final String? highlightCaption;
  final String primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;

  const AppNotificationDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.highlightValue,
    this.highlightCaption,
    this.primaryButtonLabel = 'Aceptar',
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
  });

  static const Map<NotificationType, _NotificationStyle> _styles = {
    NotificationType.success: _NotificationStyle(
      iconBackground: AppColors.success500,
      iconColor: Colors.white,
      accentColor: AppColors.success700,
      icon: Icons.check_rounded,
    ),
    NotificationType.danger: _NotificationStyle(
      iconBackground: AppColors.danger500,
      iconColor: Colors.white,
      accentColor: AppColors.danger700,
      icon: Icons.close_rounded,
    ),
    NotificationType.warning: _NotificationStyle(
      iconBackground: AppColors.warning500,
      iconColor: Colors.white,
      accentColor: AppColors.warning700,
      icon: Icons.priority_high_rounded,
    ),
    NotificationType.info: _NotificationStyle(
      iconBackground: AppColors.teal500,
      iconColor: Colors.white,
      accentColor: AppColors.teal500,
      icon: Icons.info_outline_rounded,
    ),
  };

  static Future<void> show(
    BuildContext context, {
    required NotificationType type,
    required String title,
    required String message,
    String? highlightValue,
    String? highlightCaption,
    String primaryButtonLabel = 'Aceptar',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => AppNotificationDialog(
        type: type,
        title: title,
        message: message,
        highlightValue: highlightValue,
        highlightCaption: highlightCaption,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonLabel: secondaryButtonLabel,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _styles[type]!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: style.iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.iconColor, size: 32),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.ink900.withValues(alpha: 0.55),
                    ),
                  ),
                  if (highlightValue != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      highlightValue!,
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: style.accentColor,
                      ),
                    ),
                    if (highlightCaption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        highlightCaption!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.ink900.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed:
                          onPrimaryPressed ?? () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: style.accentColor, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        primaryButtonLabel,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: style.accentColor,
                        ),
                      ),
                    ),
                  ),
                  if (secondaryButtonLabel != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onSecondaryPressed,
                      child: Text(
                        secondaryButtonLabel!,
                        style: GoogleFonts.nunito(
                          color: AppColors.ink900.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: -40,
              left: -30,
              child: IgnorePointer(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: style.accentColor.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 60,
                        top: 6,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.brand500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
