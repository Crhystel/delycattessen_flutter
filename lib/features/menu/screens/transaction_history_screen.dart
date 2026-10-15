import 'package:flutter/material.dart';

import '../../../core/widgets/light_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../wallet/models/wallet_models.dart';
import '../../wallet/services/wallet_service.dart';
import '../../wallet/widgets/transaction_kind_badge.dart';

/// Movimientos a mostrar más un [header] opcional fijo sobre la lista
/// (p. ej. el acumulado del mes a crédito).
class TransactionHistoryData {
  final List<TransactionModel> transactions;
  final Widget? header;

  const TransactionHistoryData(this.transactions, {this.header});
}

/// Carga los movimientos a mostrar (billetera de un hijo, crédito docente…).
typedef TransactionsLoader = Future<TransactionHistoryData> Function();

class TransactionHistoryScreen extends StatefulWidget {
  final String title;
  final TransactionsLoader loader;
  final String emptyMessage;

  const TransactionHistoryScreen({
    super.key,
    required this.title,
    required this.loader,
    this.emptyMessage = 'Las recargas y los pagos con saldo aparecerán aquí.',
  });

  /// Movimientos de la billetera de un hijo.
  factory TransactionHistoryScreen.forWallet({
    Key? key,
    required int walletId,
    required String childName,
  }) {
    return TransactionHistoryScreen(
      key: key,
      title: 'Movimientos de $childName',
      loader: () async => TransactionHistoryData(
        await WalletService().getTransactions(walletId),
      ),
    );
  }

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  Widget? _header;
  TransactionKind? _filter; // null = todos
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
      final data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _transactions = data.transactions;
        _header = data.header;
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
      backgroundColor: Colors.white,
      appBar: AppTheme.lightAppBar(title: Text(widget.title)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary500,
          onRefresh: _loadTransactions,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary500,
                  ),
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
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no hay movimientos',
                    message: widget.emptyMessage,
                  ),
                )
              : _buildList(),
        ),
      ),
    );
  }

  List<TransactionModel> get _visibleTransactions => _filter == null
      ? _transactions
      : _transactions.where((t) => t.kind == _filter).toList();

  /// Cabecera + filtro por tipo (si hay más de un tipo) + movimientos.
  Widget _buildList() {
    final visible = _visibleTransactions;
    final hasMixedKinds = _transactions.map((t) => t.kind).toSet().length > 1;
    final rows = <Widget>[
      ?_header,
      if (hasMixedKinds) _buildFilterBar(),
      if (visible.isEmpty)
        EmptyState(
          icon: Icons.receipt_long_outlined,
          title: _filter == TransactionKind.recharge
              ? 'No hay recargas'
              : 'No hay consumos',
        ),
      for (final transaction in visible) _buildTransactionRow(transaction),
    ];
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) => rows[index],
    );
  }

  Widget _buildFilterBar() {
    final options = <(TransactionKind?, String)>[
      (null, 'Todos'),
      (TransactionKind.recharge, 'Recargas'),
      (TransactionKind.consumption, 'Consumos'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final (kind, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: _filter == kind,
            onSelected: (_) => setState(() => _filter = kind),
          ),
      ],
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
    final kind = transaction.kind;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kind.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(kind.icon, color: kind.color, size: 22),
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
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TransactionKindBadge(kind: kind),
                    Text(
                      transaction.time,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            isFailed
                ? 'Fallida'
                : '${kind.sign}\$${transaction.amount.toStringAsFixed(2)}',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isFailed
                  ? AppColors.ink900.withValues(alpha: 0.4)
                  : kind.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
    final kind = transaction.kind;
    final isRecharge = kind == TransactionKind.recharge;

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
                  '${item.quantity}x ${item.dishName}',
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
                  '${kind.sign}\$${transaction.amount.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kind.color,
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
