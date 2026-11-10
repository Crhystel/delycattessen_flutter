import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/sale_models.dart';
import '../utils/payment_method_policy.dart';

/// Comprobante que ve el cajero tras registrar una venta.
class PosSaleSuccessSheet {
  PosSaleSuccessSheet._();

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    required PaymentMethod method,
    String? customerName,
  }) {
    final option = PaymentMethodPolicy.optionFor(method);
    return AppBottomSheet.show<void>(
      context,
      title: 'Venta registrada',
      subtitle: customerName ?? 'Venta rápida',
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: AppSpacing.xl),
            for (final item in sale.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.dishName}')),
                    Text(
                      '\$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option?.label ?? 'Pago',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '\$${sale.totalAmount.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Listo',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }
}
