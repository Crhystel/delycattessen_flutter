import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../wallet/models/wallet_models.dart';
import '../providers/child_movements_controller.dart';

/// Sección "Movimientos" de la ficha: título con "Ver todo" y una tarjeta con
/// los últimos movimientos de la billetera del hijo (recargas y compras).
class ChildRecentMovements extends StatelessWidget {
  const ChildRecentMovements({
    super.key,
    required this.controller,
    required this.onSeeAll,
  });

  final ChildMovementsController controller;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Movimientos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sectionTitleXs,
              ),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: AppRadius.smAll,
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver todo', style: AppText.link),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.secondary500,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppCard(
          design: true,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _body(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    switch (controller.status) {
      case ChildMovementsStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.secondary500,
              ),
            ),
          ),
        );
      case ChildMovementsStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                controller.errorMessage ?? 'No pudimos cargar los movimientos.',
                textAlign: TextAlign.center,
                style: AppText.secondaryLg,
              ),
              TextButton(
                onPressed: controller.load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case ChildMovementsStatus.ready:
        final items = controller.items;
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Aún no hay movimientos. Las recargas y compras aparecerán aquí.',
              textAlign: TextAlign.center,
              style: AppText.secondaryLg,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              _MovementRow(transaction: items[i]),
            ],
          ],
        );
    }
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.transaction});

  final TransactionModel transaction;

  /// Signo menos tipográfico (U+2212) de los consumos, como en el diseño.
  static const String _minus = '−';

  @override
  Widget build(BuildContext context) {
    final isRecharge = transaction.kind == TransactionKind.recharge;
    final isFailed = transaction.status == 'failed';
    final amount = transaction.amount.toStringAsFixed(2);
    final amountText = isFailed
        ? 'Fallida'
        : isRecharge
        ? '+\$$amount'
        : '$_minus\$$amount';
    final amountColor = isFailed
        ? AppColors.muted
        : isRecharge
        ? AppColors.success700
        : AppColors.ink900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecharge ? AppColors.teal50 : AppColors.ink50,
            ),
            child: Icon(
              isRecharge ? Icons.add : Icons.restaurant_outlined,
              size: 18,
              color: isRecharge ? AppColors.teal500 : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle.copyWith(fontSize: 15),
                ),
                Text(
                  transaction.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: AppText.amount.copyWith(
              fontSize: 15.5,
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
