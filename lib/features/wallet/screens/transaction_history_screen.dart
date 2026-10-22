import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import '../widgets/consumption_invoice.dart';
import '../widgets/transaction_kind_badge.dart';
import '../../../core/utils/error_message.dart';

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

  /// Persona dueña del historial, mostrada en el encabezado morado (Figma).
  final String personName;

  const TransactionHistoryScreen({
    super.key,
    required this.loader,
    required this.personName,
    this.title = 'Historial de consumo',
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
      personName: childName,
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
        _errorMessage = errorMessageOf(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.homeBottomLeft),
          ),
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.homeBottomRight),
          ),
          Column(
            children: [
              _buildPurpleHeader(),
              Expanded(
                child: ResponsiveCenter(
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Encabezado morado del Figma: flecha, título, avatar y nombre.
  Widget _buildPurpleHeader() {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: AppColors.secondary500,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      // El fondo morado ocupa todo el ancho; el contenido se centra en tablet.
      child: ResponsiveCenter(child: _buildHeaderContent(textTheme)),
    );
  }

  Widget _buildHeaderContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Volver',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                widget.title,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.personName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detalles de compra',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<TransactionModel> get _visibleTransactions => _filter == null
      ? _transactions
      : _transactions.where((t) => t.kind == _filter).toList();

  /// Cabecera + filtro por tipo (si hay más de un tipo) + movimientos.
  Widget _buildList() {
    final visible = _visibleTransactions;
    final hasMixedKinds = _transactions.map((t) => t.kind).toSet().length > 1;
    const sidePadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    );
    final divider = Divider(
      height: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: AppColors.ink900.withValues(alpha: 0.12),
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Margen inferior amplio para que la lista no quede bajo las burbujas.
      padding: EdgeInsets.only(
        bottom: AppSpacing.xxl * 3 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        if (_header != null) Padding(padding: sidePadding, child: _header),
        if (hasMixedKinds)
          Padding(padding: sidePadding, child: _buildFilterBar()),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: _filter == TransactionKind.recharge
                ? 'No hay recargas'
                : 'No hay consumos',
          ),
        for (var i = 0; i < visible.length; i++) ...[
          _buildTransactionRow(visible[i]),
          if (i < visible.length - 1) divider,
        ],
      ],
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

    // Figma: consumos con ícono de cubiertos naranja y monto en rojo.
    final isConsumption = kind == TransactionKind.consumption;
    return InkWell(
      onTap: () => _showTransactionDetail(transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kind.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isConsumption ? Icons.restaurant : kind.icon,
                color: isConsumption ? AppColors.brand500 : kind.color,
                size: 24,
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
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isFailed
                    ? AppColors.ink900.withValues(alpha: 0.4)
                    : (isConsumption ? AppColors.danger500 : kind.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
    final kind = transaction.kind;
    final isRecharge = kind == TransactionKind.recharge;

    if (!isRecharge) {
      AppBottomSheet.show<void>(
        context,
        title: transaction.displayName,
        subtitle: ConsumptionInvoice.formatDate(transaction.createdAt),
        isScrollControlled: true,
        builder: (_) => SingleChildScrollView(
          child: ConsumptionInvoice(
            studentName: widget.personName,
            transaction: transaction,
          ),
        ),
      );
      return;
    }

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
