import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// Campo de monto del control parental: "$" morado, el número en 24/800 y un
/// lápiz que indica que se puede editar. Acepta dígitos con punto y hasta dos
/// decimales (una coma se leería como 0).
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.semanticLabel,
  });

  final TextEditingController controller;
  final String semanticLabel;

  static final _allowed = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,5}\.?\d{0,2}$'),
  );

  @override
  Widget build(BuildContext context) {
    final style = AppText.amount.copyWith(fontSize: 24);
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.ink50,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: [
          Text('\$', style: style.copyWith(color: AppColors.secondary500)),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              textField: true,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_allowed],
                style: style,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: style.copyWith(color: AppColors.placeholder),
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.secondary500,
          ),
        ],
      ),
    );
  }
}
