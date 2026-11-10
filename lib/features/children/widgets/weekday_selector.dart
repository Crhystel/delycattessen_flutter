import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../utils/parental_weekdays.dart';

/// Los siete días en una sola fila (celdas a todo el ancho, 44 de alto). Los
/// días permitidos se pintan en morado; los demás en blanco con borde.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  /// Índices seleccionados (0 = lunes).
  final Iterable<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final selected = selectedDays.toSet();
    return Semantics(
      container: true,
      label: 'Días de la semana',
      child: Row(
        children: [
          for (var i = 0; i < ParentalWeekday.all.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayCell(
                day: ParentalWeekday.all[i],
                isSelected: selected.contains(i),
                onTap: () => onToggle(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final ParentalWeekday day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: day.name,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary500 : Colors.white,
              borderRadius: AppRadius.fieldAll,
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.lineStrong, width: 1.5),
            ),
            child: Text(
              day.letter,
              style: AppText.badge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
