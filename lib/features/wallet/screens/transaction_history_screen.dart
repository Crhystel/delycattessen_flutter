import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import '../utils/transaction_grouping.dart' as grouping;
import '../widgets/month_picker.dart';
import '../widgets/transaction_day_group.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/wallet_summary_header.dart';
import '../../../core/utils/error_message.dart';

/// Carga los movimientos de la billetera a mostrar.
typedef TransactionsLoader = Future<List<TransactionModel>> Function();

/// Movimientos de la billetera de un hijo: es la sección "Movimientos" de la
/// pestaña Billetera del padre (la barra inferior amarilla) y la ÚNICA vista de
/// movimientos de la app. Solo dibuja el contenido (resumen del saldo, mes y un
/// bloque por día); la cabecera, el interruptor Recargar | Movimientos y el
/// hijo los pone la pantalla que la aloja.
class TransactionHistoryScreen extends StatefulWidget {
  final TransactionsLoader loader;
  final String emptyMessage;

  /// Nombre del hijo, mostrado en el detalle de cada movimiento.
  final String personName;

  /// Saldo actual para el resumen de arriba.
  final double? balance;

  const TransactionHistoryScreen({
    super.key,
    required this.loader,
    required this.personName,
    this.emptyMessage = 'Las recargas y los pagos con saldo aparecerán aquí.',
    this.balance,
  });

  /// Movimientos de la billetera de un hijo. Lleva arriba el resumen de
  /// [balance] y lo consumido en el mes que se muestra.
  factory TransactionHistoryScreen.forWallet({
    Key? key,
    required int walletId,
    required String childName,
    double? balance,
  }) {
    return TransactionHistoryScreen(
      key: key,
      personName: childName,
      balance: balance,
      loader: () => WalletService().getTransactions(walletId),
    );
  }

  /// Total de consumos del mes de [now] (hoy por defecto); no cuenta las
  /// fallidas.
  static double consumedInMonth(
    List<TransactionModel> transactions, {
    DateTime? now,
  }) {
    return grouping.consumedInMonth(transactions, month: now);
  }

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  DateTime? _month; // mes elegido; null = el más reciente
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
      final transactions = await widget.loader();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
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

  /// Carga, error, vacío o la lista, con pull-to-refresh.
  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _loadTransactions,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary500),
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
          : _buildList(),
    );
  }

  @override
  Widget build(BuildContext context) => _buildContent();

  void _showDetail(TransactionModel transaction) => showTransactionDetail(
    context,
    transaction: transaction,
    personName: widget.personName,
  );

  /// Mes que se muestra: el elegido si aún tiene movimientos; si no, el más
  /// reciente con movimientos o, sin ninguno, el actual.
  DateTime _shownMonth(List<DateTime> months) {
    final chosen = _month;
    if (chosen != null && months.contains(chosen)) return chosen;
    if (months.isNotEmpty) return months.first;
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _pickMonth(List<DateTime> months, DateTime selected) async {
    final picked = await showMonthPickerSheet(
      context,
      months: months,
      selected: selected,
    );
    if (picked != null && mounted) setState(() => _month = picked);
  }

  /// Resumen, selector de mes y un bloque por día. Los días se construyen bajo
  /// demanda (sliver).
  Widget _buildList() {
    final months = grouping.monthsOfTransactions(_transactions);
    final month = _shownMonth(months);
    final groups = grouping.groupTransactionsByDay(
      grouping.transactionsInMonth(_transactions, month),
    );
    final balance = widget.balance;
    const sidePadding = EdgeInsets.symmetric(horizontal: AppSpacing.page);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: sidePadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (balance != null)
                  WalletSummaryHeader(
                    balance: balance,
                    consumed: grouping.consumedInMonth(
                      _transactions,
                      month: month,
                    ),
                    consumedLabel: grouping.consumedInLabel(month),
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Historial',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sectionTitleXs,
                      ),
                    ),
                    if (months.isNotEmpty)
                      MonthButton(
                        label: grouping.monthLabel(month),
                        onTap: () => _pickMonth(months, month),
                      ),
                  ],
                ),
                if (groups.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no hay movimientos',
                    message: widget.emptyMessage,
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: sidePadding,
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (_, i) => TransactionDayGroupView(
              group: groups[i],
              isFirst: i == 0,
              onTap: _showDetail,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page + 4,
            14,
            AppSpacing.page + 4,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Las compras pagadas en efectivo no aparecen aquí porque no '
              'usan la billetera. Las ves en Pedidos.',
              style: AppText.secondary,
            ),
          ),
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
}
