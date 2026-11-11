import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// Tarjeta azul con el saldo actual del hijo y, si ya hay un monto escrito en
/// [amountController], lo que quedará después de recargar. Solo ella se
/// reconstruye al teclear.
class RechargeBalanceCard extends StatelessWidget {
  const RechargeBalanceCard({
    super.key,
    required this.balance,
    required this.firstName,
    required this.amountController,
  });

  final double balance;
  final String firstName;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, _) {
        final amount = double.tryParse(value.text);
        final afterRecharge = (amount != null && amount > 0)
            ? balance + amount
            : null;
        return _buildCard(afterRecharge);
      },
    );
  }

  Widget _buildCard(double? afterRecharge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.teal500,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo actual de $firstName',
            style: AppText.secondary.copyWith(
              fontSize: 13,
              color: AppColors.teal50,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: AppText.amount.copyWith(
              fontSize: 30,
              height: 1,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (afterRecharge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.fullAll,
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Después de recargar: ',
                  children: [
                    TextSpan(
                      text: '\$${afterRecharge.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                style: AppText.secondary.copyWith(
                  fontSize: 12.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
