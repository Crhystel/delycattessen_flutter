import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Interruptor del control parental según el diseño: 56×34, pista morada al
/// encender (gris `switchOff` apagado) y pulgar blanco de 28 con sombra. El
/// [label] es lo que lee el lector de pantalla.
class ParentalSwitch extends StatelessWidget {
  const ParentalSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      onTap: () => onChanged(!value),
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: _duration,
            width: 56,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.secondary500 : AppColors.switchOff,
              borderRadius: BorderRadius.circular(17),
            ),
            child: AnimatedAlign(
              duration: _duration,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
