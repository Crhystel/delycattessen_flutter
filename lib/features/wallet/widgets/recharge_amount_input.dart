import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Campo del monto a recargar: el recuadro grande de la pestaña Billetera.
class RechargeAmountField extends StatelessWidget {
  const RechargeAmountField({super.key, required this.controller});

  final TextEditingController controller;

  static const _keyboard = TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    // El NÚMERO queda exactamente en el centro del recuadro: a cada lado hay un
    // `Expanded` igual, así el campo (que mide lo que mide el texto) se centra
    // solo. El "$" va pegado a su izquierda, dentro del hueco izquierdo, sin
    // correr el número.
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary500, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '\$',
                    style: AppText.amount.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 48,
                // Un monto largo nunca invade los lados (que quedan iguales).
                maxWidth: constraints.maxWidth * 0.6,
              ),
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: _keyboard,
                  style: AppText.amount.copyWith(
                    fontSize: 26,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                    // El tema global (`AppTheme.inputDecorationTheme`) pone 14 de
                    // relleno en todos los campos: aquí se anula, si no el
                    // número queda alto y separado del "$".
                    contentPadding: EdgeInsets.zero,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: AppColors.placeholder),
                  ),
                ),
              ),
            ),
            // Hueco derecho de igual peso que el izquierdo: mantiene el centro.
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Montos rápidos ($5, $10…). Marca el que coincide con lo escrito en
/// [controller] sin reconstruir el resto de la pantalla.
class QuickAmountChips extends StatelessWidget {
  const QuickAmountChips({
    super.key,
    required this.controller,
    required this.amounts,
  });

  final TextEditingController controller;
  final List<double> amounts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final entered = double.tryParse(value.text);
        return Row(
          children: [
            for (final amount in amounts) ...[
              Expanded(
                child: _QuickAmountChip(
                  amount: amount,
                  selected: entered == amount,
                  onTap: () => controller.text = amount.toStringAsFixed(2),
                ),
              ),
              if (amount != amounts.last) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const height = 44.0;
    final textStyle = AppText.button.copyWith(
      fontSize: 14,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
      color: selected ? AppColors.ink900 : AppColors.brand700,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brand500 : AppColors.brand50,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.brand500, width: 1.5),
          ),
          child: Text('\$${amount.toStringAsFixed(0)}', style: textStyle),
        ),
      ),
    );
  }
}
