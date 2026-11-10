import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';
import '../utils/transaction_grouping.dart' as grouping;
import '../widgets/month_picker.dart';
import '../widgets/transaction_day_group.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_kind_badge.dart';
import '../widgets/wallet_summary_header.dart';
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

  /// true cuando vive dentro de la pestaña Billetera del padre: solo la lista,
  /// sin encabezado morado, burbujas ni barra propia.
  final bool embedded;

  /// Saldo actual para el resumen de la pestaña Billetera ([embedded]).
  final double? balance;

  const TransactionHistoryScreen({
    super.key,
    required this.loader,
    required this.personName,
    this.title = 'Historial de consumo',
    this.emptyMessage = 'Las recargas y los pagos con saldo aparecerán aquí.',
    this.embedded = false,
    this.balance,
  });

  /// Movimientos de la billetera de un hijo. En la pestaña Billetera
  /// ([embedded]) lleva arriba el resumen de [balance] y lo consumido en el mes
  /// que se muestra.
  factory TransactionHistoryScreen.forWallet({
    Key? key,
    required int walletId,
    required String childName,
    bool embedded = false,
    double? balance,
  }) {
    return TransactionHistoryScreen(
      key: key,
      personName: childName,
      embedded: embedded,
      balance: balance,
      loader: () async => TransactionHistoryData(
        await WalletService().getTransactions(walletId),
      ),
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
  Widget? _header;
  TransactionKind? _filter; // null = todos (solo en la vista no embebida)
  DateTime? _month; // mes elegido en la vista embebida; null = el más reciente
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
          : widget.embedded
          ? _buildEmbeddedList()
          : _transactions.isEmpty
          ? _buildMessage(
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aún no hay movimientos',
                message: widget.emptyMessage,
              ),
            )
          : _buildList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildContent();
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
              Expanded(child: ResponsiveCenter(child: _buildContent())),
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

  /// Vista de la pestaña Billetera: resumen, selector de mes y un bloque por
  /// día. Los días se construyen bajo demanda (sliver).
  Widget _buildEmbeddedList() {
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
      onTap: () => _showDetail(transaction),
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
}
