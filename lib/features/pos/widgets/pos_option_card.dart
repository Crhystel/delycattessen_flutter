import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../utils/pos_home_layout.dart';

/// Large tappable option of the cashier home (face or QR identification).
/// On a phone it is a row with the icon at the left and a chevron; on a tablet
/// the icon goes above the centered text ([PosHomeMetrics.stacked]).
class PosOptionCard extends StatelessWidget {
  const PosOptionCard({
    super.key,
    required this.metrics,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.onTap,
  });

  final PosHomeMetrics metrics;
  final IconData icon;
  final Color iconBackground;
  final String title;
  final Color titleColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final radius = BorderRadius.circular(m.cardRadius);
    final align = m.stacked ? TextAlign.center : TextAlign.start;

    final iconBox = Container(
      width: m.iconBox,
      height: m.iconBox,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(m.iconRadius),
      ),
      child: Icon(icon, color: Colors.white, size: m.iconSize),
    );
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: m.stacked
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: AppText.cardTitle.copyWith(
            fontSize: m.optionTitleSize,
            fontWeight: FontWeight.w800,
            color: titleColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: align,
          style: AppText.secondary.copyWith(fontSize: m.optionSubtitleSize),
        ),
      ],
    );

    final content = m.stacked
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBox,
              SizedBox(height: m.iconGap),
              texts,
            ],
          )
        : Row(
            children: [
              iconBox,
              SizedBox(width: m.iconGap),
              Expanded(child: texts),
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: AppColors.chevron,
              ),
            ],
          );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink900.withValues(alpha: m.shadowAlpha),
              blurRadius: m.shadowBlur,
              offset: Offset(0, m.shadowOffset),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: m.cardHeight),
              child: Padding(
                padding: EdgeInsets.all(m.cardPadding),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
