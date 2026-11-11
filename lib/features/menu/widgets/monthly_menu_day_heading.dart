import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// "Martes 10 de noviembre" with the dishes of the day on the right and, when
/// the parental control blocks the day, the reason under the date.
class MonthlyMenuDayHeading extends StatelessWidget {
  const MonthlyMenuDayHeading({
    super.key,
    required this.day,
    required this.dishCount,
  });

  final MenuDay day;
  final int dishCount;

  @override
  Widget build(BuildContext context) {
    final date = DateFormatter.parseIsoDate(day.date);
    final reason = day.isBlockedByParentalControl
        ? (day.blockedReason ?? 'Día bloqueado por el control parental.')
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        22,
        AppSpacing.page,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  DateFormatter.formatLongCapitalized(date),
                  style: AppText.sectionTitleSm,
                ),
              ),
              if (dishCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  dishCount == 1 ? '1 plato' : '$dishCount platos',
                  style: AppText.secondaryLg,
                ),
              ],
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(reason, style: AppText.secondaryLg),
          ],
        ],
      ),
    );
  }
}
