import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import 'parental_switch.dart';

/// Tarjeta de un control parental: icono cuadrado, título y subtítulo, la fila
/// "Activado/Desactivado" con su interruptor y, según el estado, el contenido
/// de [child] (monto, días...) cuando está activado o [offChild] (texto de
/// ayuda) cuando no.
///
/// El icono es un [icon] o, si se da [glyph], un texto (el "$" del límite).
class ParentalControlCard extends StatelessWidget {
  final IconData? icon;
  final String? glyph;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Widget? child;
  final Widget? offChild;

  const ParentalControlCard({
    super.key,
    this.icon,
    this.glyph,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    this.child,
    this.offChild,
  }) : assert(icon != null || glyph != null, 'Pasa un icono o un glifo');

  @override
  Widget build(BuildContext context) {
    final content = enabled ? child : offChild;
    return AppCard(
      design: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.secondary50,
                  borderRadius: AppRadius.fieldAll,
                ),
                child: glyph != null
                    ? Text(
                        glyph!,
                        style: AppText.amount.copyWith(
                          fontSize: 22,
                          color: AppColors.secondary500,
                        ),
                      )
                    : Icon(icon, color: AppColors.secondary500, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle),
                    Text(subtitle, style: AppText.secondaryLg),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  enabled ? 'Activado' : 'Desactivado',
                  style: AppText.secondaryLg.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              ParentalSwitch(
                value: enabled,
                onChanged: onChanged,
                label: title,
              ),
            ],
          ),
          // Collapses smoothly when the control is turned off.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: content == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(width: double.infinity, child: content),
                  ),
          ),
        ],
      ),
    );
  }
}
