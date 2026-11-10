import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Row of the days of the monthly menu (weekday and number, a lock when the
/// parental control blocks the day). It scrolls sideways and takes the height
/// its content needs, so it works with any text size.
class MenuDaysStrip extends StatelessWidget {
  final List<MenuDay> days;
  final int? selectedDayId;
  final ValueChanged<MenuDay> onSelect;

  const MenuDaysStrip({
    super.key,
    required this.days,
    required this.selectedDayId,
    required this.onSelect,
  });

  static const double _circle = 50;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            _DayItem(
              day: days[i],
              isSelected: selectedDayId == days[i].id,
              onTap: () => onSelect(days[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final MenuDay day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayItem({
    required this.day,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MenuDaysStrip._circle,
            height: MenuDaysStrip._circle,
            decoration: BoxDecoration(
              color: isBlocked
                  ? Colors.grey.shade200
                  : isSelected
                  ? AppColors.secondary500
                  : AppColors.secondary50,
              shape: BoxShape.circle,
              border: isBlocked
                  ? Border.all(color: Colors.grey.shade400)
                  : null,
            ),
            alignment: Alignment.center,
            child: isBlocked
                ? Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  )
                : Text(
                    parsedDate.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.secondary700,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            weekdayShort,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isBlocked
                  ? Colors.grey.shade500
                  : isSelected
                  ? AppColors.secondary500
                  : AppColors.ink900.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
