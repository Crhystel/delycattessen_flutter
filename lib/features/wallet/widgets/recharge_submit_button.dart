import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/primary_button.dart';

/// Botón "Recargar $10.00 a Julieta". Su texto sigue lo escrito en
/// [amountController] y solo él se reconstruye al teclear.
///
/// Con [design] = true toma las medidas de la pestaña Billetera del padre (52
/// de alto, texto 15/800); sin él es el [PrimaryButton] de siempre.
class RechargeSubmitButton extends StatelessWidget {
  const RechargeSubmitButton({
    super.key,
    required this.amountController,
    required this.firstName,
    required this.isLoading,
    required this.onPressed,
    this.design = false,
  });

  final TextEditingController amountController;
  final String? firstName;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool design;

  static const double _height = 52;

  String _label(String text) {
    final amount = double.tryParse(text);
    final name = firstName;
    return (amount != null && amount > 0 && name != null)
        ? 'Recargar \$${amount.toStringAsFixed(2)} a $name'
        : 'Recargar saldo seguro';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, _) {
        final label = _label(value.text);
        if (!design) {
          return PrimaryButton(
            label: label,
            icon: Icons.lock_outline,
            isLoading: isLoading,
            onPressed: onPressed,
          );
        }
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary500,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(_height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            elevation: 0,
          ),
          icon: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_outline, size: 18),
          label: Text(label, style: AppText.button.copyWith(fontSize: 15)),
        );
      },
    );
  }
}
