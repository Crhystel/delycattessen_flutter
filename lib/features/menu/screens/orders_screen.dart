import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_selector_chip.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../widgets/order_origin_badge.dart';

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
  List<OrderEntry> _orders = [];
  String? _errorMessage;

  /// Aviso cuando solo uno de los dos orígenes (preórdenes / compras en caja) falló.
  String? _partialWarning;
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

  /// Ejecuta una carga sin lanzar: devuelve sus pedidos o el mensaje de error.
  Future<({List<OrderEntry> entries, String? error})> _safeLoad(
    Future<List<OrderEntry>> Function() load,
  ) async {
    try {
      return (entries: await load(), error: null);
    } catch (e) {
      return (
        entries: const <OrderEntry>[],
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _fetchOrders() async {
    // Preórdenes y compras en caja se piden en paralelo.
    final results = await Future.wait([
      _safeLoad(() async {
        final preOrders = await _menuService.getPreOrders(
          studentId: _studentId,
        );
        return preOrders.map(OrderEntry.fromPreOrder).toList();
      }),
      _safeLoad(() => _menuService.getPurchases(studentId: _studentId)),
    ]);
    if (!mounted) return;

    final errors = [
      for (final r in results)
        if (r.error != null) r.error!,
    ];
    final bothFailed = errors.length == results.length;
    setState(() {
      _orders = [for (final r in results) ...r.entries];
      _errorMessage = bothFailed ? errors.first : null;
      _partialWarning = (!bothFailed && errors.isNotEmpty)
          ? 'Algunos pedidos no se pudieron cargar. Desliza para reintentar.'
          : null;
      _isLoading = false;
    });
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

  String _formatDeliveryDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final parsed = DateFormatter.parseIsoDate(isoDate);
      return DateFormatter.formatLong(parsed);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        child: SafeArea(
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
                          Icons.arrow_back,
                          color: AppColors.ink900,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Text(
                      'Mis pedidos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
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
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary500),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        color: AppColors.secondary500,
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
        color: AppColors.secondary500,
        onRefresh: _fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Todavía no hay pedidos',
              message: 'Tus preórdenes y las compras en caja aparecerán aquí.',
            ),
          ],
        ),
      );
    }

    // Se agrupa en "Por retirar" (pendientes, ordenadas por fecha de entrega más próxima)
    // e "Historial" (el resto, ordenadas por creación descendente).
    final pending = _orders.where((o) => o.isPendingPickup).toList()
      ..sort((a, b) {
        if (a.deliveryDate.isNotEmpty && b.deliveryDate.isNotEmpty) {
          return a.deliveryDate.compareTo(b.deliveryDate);
        }
        return a.createdAt.compareTo(b.createdAt);
      });

    final history = _orders.where((o) => !o.isPendingPickup).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final rows = <Object>[
      if (_partialWarning != null) _PartialWarning(_partialWarning!),
      if (pending.isNotEmpty) ...['Por retirar', ...pending],
      if (history.isNotEmpty) ...['Historial', ...history],
    ];

    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) return _buildSectionTitle(row);
          if (row is _PartialWarning) return _buildPartialWarning(row.message);
          return _buildOrderCard(row as OrderEntry);
        },
      ),
    );
  }

  Widget _buildPartialWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.warning700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
            color: AppColors.secondary500,
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

  Widget _buildOrderCard(OrderEntry order) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _statusAccent(order.status);
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    final deliveryText = _formatDeliveryDate(order.deliveryDate);

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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OrderOriginBadge(
              origin: order.origin,
              paymentLabel: order.paymentLabel,
            ),
          ),
          const SizedBox(height: 6),
          if (deliveryText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.secondary500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Entrega: $deliveryText',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
                      '${item.quantity}x ${item.dishName}',
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

/// Marca de fila para el aviso de carga parcial dentro de la lista.
class _PartialWarning {
  final String message;

  const _PartialWarning(this.message);
}
