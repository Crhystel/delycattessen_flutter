import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Row of the days of the monthly menu as rounded chips (weekday over number,
/// a lock when the parental control blocks the day). Six chips share the width
/// (so they grow on tablets); with more days it scrolls sideways. It takes the
/// height its content needs, so it works with any text size.
///
/// With [design] the side margin belongs to the container (not to the scroll),
/// so the chip that leaves the strip is cut 20 px away from the screen edge,
/// aligned with the rest of the content, and the selected day is centered.
class MenuDaysStrip extends StatefulWidget {
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

  @override
  State<MenuDaysStrip> createState() => _MenuDaysStripState();
}

class _MenuDaysStripState extends State<MenuDaysStrip> {
  static const int _visibleChips = 6;
  static const double _gap = 6;
  static const double _minChipWidth = 52;
  static const double _minDesignChipWidth = 40;
  static const double _maxChipWidth = 84;
  static const Duration _centerDuration = Duration(milliseconds: 250);
  static const double _scrollTolerance = 0.5;

  final ScrollController _controller = ScrollController();
  double _chipWidth = _maxChipWidth;

  @override
  void initState() {
    super.initState();
    _centerSelectedAfterFrame(animate: false);
  }

  @override
  void didUpdateWidget(MenuDaysStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayId != widget.selectedDayId) {
      _centerSelectedAfterFrame(animate: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerSelectedAfterFrame({required bool animate}) {
    if (!widget.design) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerSelected(animate: animate);
    });
  }

  /// Scrolls so the selected chip sits in the middle of the visible strip
  /// (clamped to the scroll range). Does nothing when everything fits.
  void _centerSelected({required bool animate}) {
    if (!_controller.hasClients) return;
    final index = widget.days.indexWhere((d) => d.id == widget.selectedDayId);
    if (index < 0) return;
    final position = _controller.position;
    final max = position.maxScrollExtent;
    if (max <= _scrollTolerance) return;
    final target =
        (index * (_chipWidth + _gap) -
                (position.viewportDimension - _chipWidth) / 2)
            .clamp(0.0, max)
            .toDouble();
    if (animate) {
      _controller.animateTo(
        target,
        duration: _centerDuration,
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = widget.design;
    final padding = design ? AppSpacing.page : AppSpacing.lg;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 2 * padding;
        _chipWidth = ((available - _gap * (_visibleChips - 1)) / _visibleChips)
            .clamp(design ? _minDesignChipWidth : _minChipWidth, _maxChipWidth);
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.days.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _DayItem(
                day: widget.days[i],
                width: _chipWidth,
                isSelected: widget.selectedDayId == widget.days[i].id,
                onTap: () => widget.onSelect(widget.days[i]),
              ),
            ],
          ],
        );
        if (design) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              0,
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: row,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: AppSpacing.sm,
          ),
          child: row,
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
