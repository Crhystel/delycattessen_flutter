import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Row of the days of the monthly menu as rounded chips (weekday over number,
/// a lock when the parental control blocks the day). Six chips share the width
/// (so they grow on tablets); with more days it scrolls sideways. It takes the
/// height its content needs, so it works with any text size.
class MenuDaysStrip extends StatelessWidget {
  final List<MenuDay> days;
  final int? selectedDayId;
  final ValueChanged<MenuDay> onSelect;

  /// Márgenes del rediseño del padre: 20 a los lados y 16 sobre las fichas.
  final bool design;

  const MenuDaysStrip({
    super.key,
    required this.days,
    required this.selectedDayId,
    required this.onSelect,
    this.design = false,
  });

  static const int _visibleChips = 6;
  static const double _gap = 6;
  static const double _minChipWidth = 52;
  static const double _maxChipWidth = 84;

  @override
  Widget build(BuildContext context) {
    final padding = design ? AppSpacing.page : AppSpacing.lg;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 2 * padding;
        final chipWidth =
            ((available - _gap * (_visibleChips - 1)) / _visibleChips).clamp(
              _minChipWidth,
              _maxChipWidth,
            );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: design
              ? EdgeInsets.fromLTRB(padding, AppSpacing.lg, padding, 0)
              : EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: AppSpacing.sm,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                _DayItem(
                  day: days[i],
                  width: chipWidth,
                  isSelected: selectedDayId == days[i].id,
                  onTap: () => onSelect(days[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayItem extends StatelessWidget {
  final MenuDay day;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayItem({
    required this.day,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = day.isBlockedByParentalControl;
    final parsedDate = DateFormatter.parseIsoDate(day.date);
    final weekdayShort = DateFormatter.shortWeekdayName(parsedDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 64),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBlocked
              ? AppColors.divider
              : isSelected
              ? AppColors.secondary500
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected && !isBlocked
              ? null
              : Border.all(color: AppColors.lineStrong),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayShort,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isBlocked
                    ? AppColors.chevron
                    : isSelected
                    ? AppColors.secondary50
                    : AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            isBlocked
                ? Icon(Icons.lock_outline, size: 20, color: AppColors.chevron)
                : Text(
                    parsedDate.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.ink900,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
