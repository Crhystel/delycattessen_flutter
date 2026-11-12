import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/widgets/initials_avatar.dart';
import '../models/pos_identification_model.dart';
import '../models/sale_models.dart';
import '../utils/sale_receipt_summary.dart';

/// Receipt the cashier sees after a sale is registered. Its only exit is
/// "Nueva venta" (or dismissing the sheet): the caller then goes back to the
/// identification screen.
class PosSaleSuccessSheet {
  PosSaleSuccessSheet._();

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    required PaymentMethod method,
    IdentifiedUser? user,
  }) {
    final summary = SaleReceiptSummary.of(
      sale: sale,
      method: method,
      user: user,
    );
    return AppBottomSheet.show<void>(
      context,
      design: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: _ReceiptBody(
          sale: sale,
          summary: summary,
          customerName: user?.fullName,
          onNewSale: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({
    required this.sale,
    required this.summary,
    required this.customerName,
    required this.onNewSale,
  });

  final Sale sale;
  final SaleReceiptSummary summary;
  final String? customerName;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xs),
        const _SuccessBadge(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '¡Venta registrada!',
          textAlign: TextAlign.center,
          style: AppText.detailTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          summary.subtitle,
          textAlign: TextAlign.center,
          style: AppText.detailSubtitle,
        ),
        const SizedBox(height: 10),
        Text(_money(sale.totalAmount), style: AppText.heroAmount),
        const SizedBox(height: AppSpacing.page),
        _ReceiptCard(sale: sale, summary: summary, customerName: customerName),
        const SizedBox(height: AppSpacing.page),
        PrimaryButton(
          label: 'Nueva venta',
          icon: Icons.add,
          design: true,
          onPressed: onNewSale,
        ),
      ],
    );
  }
}

/// Check on a halo that pops in. Plain tweens, so there is no controller to
/// dispose.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  static const _haloSize = 116.0;
  static const _badgeSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _haloSize,
        height: _haloSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
              ),
              child: Container(
                width: _haloSize,
                height: _haloSize,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              // Starts after 100 ms and overshoots slightly before settling.
              curve: const Interval(1 / 6, 1, curve: Curves.easeOutBack),
              builder: (_, value, child) => Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.4 + 0.6 * value, child: child),
              ),
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.success500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success500.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.sale,
    required this.summary,
    required this.customerName,
  });

  final Sale sale;
  final SaleReceiptSummary summary;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (customerName != null)
        _CustomerRow(name: customerName!, methodLabel: summary.methodLabel),
      for (final item in sale.items)
        _LineRow(
          label: '${item.quantity}× ${item.dishName}',
          amount: _money(item.priceAtPurchase * item.quantity),
        ),
      if (summary.hasBalance)
        _BalanceRow(
          label: summary.balanceLabel!,
          amount: summary.balanceAmount!,
        ),
    ];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.ink50,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.lineStrong),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.name, required this.methodLabel});

  final String name;
  final String methodLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brand50,
            child: Text(
              InitialsAvatar.initialsOf(name),
              style: AppText.badge.copyWith(
                fontSize: 14,
                color: AppColors.brand700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.rowTitle),
                Text('Cliente', style: AppText.secondary),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.teal50,
              borderRadius: AppRadius.fullAll,
            ),
            child: Text(
              methodLabel,
              style: AppText.badge.copyWith(
                fontSize: 12.5,
                color: AppColors.teal700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppText.receiptLine)),
          const SizedBox(width: AppSpacing.md),
          Text(amount, style: AppText.receiptLineAmount),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppText.receiptNote)),
          const SizedBox(width: AppSpacing.md),
          Text(_money(amount), style: AppText.price),
        ],
      ),
    );
  }
}

String _money(double amount) => '\$${amount.toStringAsFixed(2)}';
