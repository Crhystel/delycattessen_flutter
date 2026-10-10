import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../children/widgets/child_selector_chip.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import 'package:provider/provider.dart';
import '../../children/providers/children_provider.dart';

class OrdersScreen extends StatefulWidget {
  final int? studentId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  /// Si la pestaña está visible. Al volver a activarse se recargan los pedidos
  /// (por ejemplo, tras pagar desde el carrito).
  final bool isActive;

  const OrdersScreen({
    super.key,
    this.studentId,
    this.embedded = false,
    this.isActive = true,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<PreOrderSummary> _orders = [];
  String? _errorMessage;
  int? _studentId;
  ChildrenProvider? _childrenProvider;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    if (widget.embedded) {
      _childrenProvider = context.read<ChildrenProvider>();
      _studentId = _childrenProvider!.selectedChild?.id ?? _studentId;
      _childrenProvider!.addListener(_onSelectedChildChanged);
    }
    _fetchOrders();
  }

  @override
  void dispose() {
    _childrenProvider?.removeListener(_onSelectedChildChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _fetchOrders();
  }

  /// Los pedidos siguen al hijo seleccionado global.
  void _onSelectedChildChanged() {
    final id = _childrenProvider?.selectedChild?.id;
    if (!mounted || id == _studentId) return;
    setState(() {
      _studentId = id;
      _isLoading = true;
    });
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await _menuService.getPreOrders(studentId: _studentId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusAccent(PreOrderStatus status) {
    switch (status) {
      case PreOrderStatus.pending:
        return AppColors.warning700;
      case PreOrderStatus.delivered:
        return AppColors.success700;
      case PreOrderStatus.canceled:
        return AppColors.danger700;
    }
  }

  Color _statusBackground(PreOrderStatus status) {
    switch (status) {
      case PreOrderStatus.pending:
        return AppColors.warningBg;
      case PreOrderStatus.delivered:
        return AppColors.successBg;
      case PreOrderStatus.canceled:
        return AppColors.dangerBg;
    }
  }

  IconData _statusIcon(PreOrderStatus status) {
    switch (status) {
      case PreOrderStatus.pending:
        return Icons.schedule;
      case PreOrderStatus.delivered:
        return Icons.check_circle;
      case PreOrderStatus.canceled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (!widget.embedded)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.ink900,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Text(
                    'Mis pedidos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal700,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.embedded)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ChildSelectorChip(label: 'Pedidos de'),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal500),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        color: AppColors.teal500,
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos cargar los pedidos',
              message: _errorMessage,
              actionLabel: 'Reintentar',
              onAction: () {
                setState(() => _isLoading = true);
                _fetchOrders();
              },
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.teal500,
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Todavía no hay pedidos',
              message: 'Cuando hagas un pedido aparecerá aquí.',
            ),
          ],
        ),
      );
    }

    // Se agrupa en "Por retirar" (pendientes) e "Historial" (el resto),
    // conservando el orden que entrega el backend dentro de cada grupo.
    final pending = _orders
        .where((o) => o.status == PreOrderStatus.pending)
        .toList();
    final history = _orders
        .where((o) => o.status != PreOrderStatus.pending)
        .toList();
    final rows = <Object>[
      if (pending.isNotEmpty) ...['Por retirar', ...pending],
      if (history.isNotEmpty) ...['Historial', ...history],
    ];

    return RefreshIndicator(
      color: AppColors.teal500,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) return _buildSectionTitle(row);
          return _buildOrderCard(row as PreOrderSummary);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            title == 'Historial' ? Icons.history : Icons.shopping_bag_outlined,
            size: 20,
            color: AppColors.teal500,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink900.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(PreOrderSummary order) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _statusAccent(order.status);
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.studentName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(order.status), size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      order.statusDisplay,
                      style: textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.ink900.withValues(alpha: 0.55),
            ),
          ),
          const Divider(height: 20),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.menuItemName}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '\$${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
