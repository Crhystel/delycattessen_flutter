import 'package:flutter/material.dart';

import '../config/password_policy.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Guía en vivo de los requisitos de contraseña: gris (sin escribir),
/// verde (cumple) o rojo (falta).
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  static const _met = AppColors.success700;
  static const _unmet = AppColors.danger700;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink50,
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu contraseña debe tener:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 6),
          for (final rule in PasswordPolicy.rules) _row(rule),
        ],
      ),
    );
  }

  Widget _row(PasswordRule rule) {
    final isEmpty = password.isEmpty;
    final isMet = !isEmpty && rule.test(password);
    final color = isMet
        ? _met
        : isEmpty
        ? AppColors.ink900.withValues(alpha: 0.6)
        : _unmet;
    final icon = isMet
        ? Icons.check_circle
        : isEmpty
        ? Icons.radio_button_unchecked
        : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule.label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
