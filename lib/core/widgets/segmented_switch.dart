import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Colores del [SegmentedSwitch]: morado (Menú, Pedidos) o azul (Billetera).
enum SegmentedSwitchPalette {
  purple(
    track: AppColors.secondary50,
    active: AppColors.secondary500,
    inactiveText: AppColors.secondary700,
  ),
  blue(
    track: AppColors.teal50,
    active: AppColors.teal500,
    inactiveText: AppColors.teal700,
  );

  const SegmentedSwitchPalette({
    required this.track,
    required this.active,
    required this.inactiveText,
  });

  final Color track;
  final Color active;
  final Color inactiveText;
}

/// Selector segmentado de dos o tres opciones iguales sobre una pastilla clara
/// (p. ej. "Menú del mes | Productos", "Recargar | Movimientos").
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.palette = SegmentedSwitchPalette.purple,
    this.height = 44,
    this.fontSize = 15,
  });

  /// Valor y texto de cada opción, en orden.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final SegmentedSwitchPalette palette;

  /// Alto de cada opción (44 en Menú/Billetera, 42 en Pedidos).
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.track,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: BoxConstraints(minHeight: height),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? palette.active
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: value == selected
                            ? Colors.white
                            : palette.inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
