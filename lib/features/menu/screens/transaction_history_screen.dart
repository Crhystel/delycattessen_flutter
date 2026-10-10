import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../wallet/models/wallet_models.dart';
import '../../wallet/services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int walletId;
  final String childName;

  const TransactionHistoryScreen({
    super.key,
    required this.walletId,
    required this.childName,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _walletService = WalletService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactions = await _walletService.getTransactions(
        widget.walletId,
      );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(title: Text('Movimientos de ${widget.childName}')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal500,
          onRefresh: _loadTransactions,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal500),
                )
              : _errorMessage != null
              ? _buildMessage(
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'No pudimos cargar los movimientos',
                    message: _errorMessage,
                    actionLabel: 'Reintentar',
                    onAction: _loadTransactions,
                  ),
                )
              : _transactions.isEmpty
              ? _buildMessage(
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no hay movimientos',
                    message: 'Las recargas y compras aparecerán aquí.',
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _buildTransactionRow(_transactions[index]),
                ),
        ),
      ),
    );
  }

  /// Keeps the empty/error state scrollable so pull-to-refresh still works.
  Widget _buildMessage(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [child],
    );
  }

  Widget _buildTransactionRow(TransactionModel transaction) {
    final textTheme = Theme.of(context).textTheme;
    final isRecharge = transaction.type == 'recharge';
    final isFailed = transaction.status == 'failed';

    return AppCard(
      onTap: () => _showTransactionDetail(transaction),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isRecharge ? AppColors.successBg : AppColors.brand50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRecharge ? Icons.add : Icons.restaurant,
              color: isRecharge ? AppColors.success700 : AppColors.brand700,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.time,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            isFailed
                ? 'Fallida'
                : '${isRecharge ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isFailed
                  ? AppColors.ink900.withValues(alpha: 0.4)
                  : (isRecharge ? AppColors.success700 : AppColors.danger700),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
    final isRecharge = transaction.type == 'recharge';

    AppBottomSheet.show<void>(
      context,
      title: transaction.displayName,
      subtitle: transaction.time,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: AppSpacing.xl),
            if (isRecharge) ...[
              _buildDetailRow(
                'Método',
                transaction.gateway.isNotEmpty
                    ? transaction.gateway
                    : 'No especificado',
              ),
              _buildDetailRow(
                'Estado',
                transaction.status == 'failed' ? 'Fallida' : 'Exitosa',
              ),
            ] else if (transaction.items.isNotEmpty) ...[
              ...transaction.items.map(
                (item) => _buildDetailRow(
                  '${item.quantity}x ${item.menuItemName}',
                  '\$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                ),
              ),
              const Divider(height: AppSpacing.xl),
            ] else
              Text(
                'No hay detalle disponible para este movimiento.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink900.withValues(alpha: 0.55),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${isRecharge ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isRecharge
                        ? AppColors.success700
                        : AppColors.danger700,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
