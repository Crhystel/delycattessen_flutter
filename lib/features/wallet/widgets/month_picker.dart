import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../utils/transaction_grouping.dart';

/// Botón "Octubre 2026 ▾" que abre la lista de meses con movimientos.
class MonthButton extends StatelessWidget {
  const MonthButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cambiar de mes. $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.secondaryLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.secondary500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja "Elige un mes". Devuelve el mes elegido o null si se cierra sin elegir.
Future<DateTime?> showMonthPickerSheet(
  BuildContext context, {
  required List<DateTime> months,
  required DateTime selected,
}) {
  return AppBottomSheet.show<DateTime>(
    context,
    title: 'Elige un mes',
    design: true,
    // La hoja pinta su fondo blanco: sin este Material los toques de las filas
    // no se verían.
    builder: (sheetContext) => Material(
      type: MaterialType.transparency,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final month in months)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                monthLabel(month),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: month == selected
                  ? const Icon(Icons.check, color: AppColors.secondary500)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(month),
            ),
        ],
      ),
    ),
  );
}
