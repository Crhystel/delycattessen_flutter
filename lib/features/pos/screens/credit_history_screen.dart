import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/subpage_header.dart';
import '../../wallet/models/wallet_models.dart';
import '../../wallet/utils/transaction_grouping.dart' as grouping;
import '../../wallet/widgets/transaction_day_group.dart';
import '../../wallet/widgets/transaction_detail_sheet.dart';
import '../services/pos_service.dart';
import '../widgets/credit_summary_card.dart';

/// Compras a crédito del docente: el acumulado del mes y una lista sencilla,
/// agrupada por día. Es solo del docente (no tiene billetera): los movimientos
/// de la billetera del padre se ven únicamente en la pestaña Billetera.
class CreditHistoryScreen extends StatefulWidget {
  /// Nombre del docente, mostrado en el detalle de cada compra.
  final String personName;
  final PosService? posService;

  const CreditHistoryScreen({
    super.key,
    required this.personName,
    this.posService,
  });

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen> {
  late final PosService _posService = widget.posService ?? PosService();

  List<TransactionModel> _transactions = const [];
  String _month = '';
  double _accumulatedTotal = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await _posService.getCreditHistory();
      if (!mounted) return;
      setState(() {
        _transactions = [
          for (final sale in history.sales) sale.toTransaction(),
        ];
        _month = history.month;
        _accumulatedTotal = history.accumulatedTotal;
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

  void _showDetail(TransactionModel transaction) => showTransactionDetail(
    context,
    transaction: transaction,
    personName: widget.personName,
  );

  /// Carga, error, vacío o la lista; siempre desplazable para poder refrescar.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary500),
      );
    }
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos cargar tus compras',
            message: _errorMessage,
            actionLabel: 'Reintentar',
            onAction: _load,
          ),
        ],
      );
    }
    final groups = grouping.groupTransactionsByDay(_transactions);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        CreditSummaryCard(month: _month, accumulatedTotal: _accumulatedTotal),
        const SizedBox(height: AppSpacing.lg),
        if (groups.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aún no hay compras',
            message: 'Tus compras a crédito aparecerán aquí.',
          ),
        for (var i = 0; i < groups.length; i++)
          TransactionDayGroupView(
            group: groups[i],
            isFirst: i == 0,
            onTap: _showDetail,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: ResponsiveCenter(
        child: Column(
          children: [
            SubpageHeader(
              title: 'Compras a crédito',
              subtitle: widget.personName,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondary500,
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
