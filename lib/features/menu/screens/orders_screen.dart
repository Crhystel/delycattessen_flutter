import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../../core/widgets/subpage_header.dart';
import '../../../core/widgets/tab_header.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_switch_bar.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../utils/order_filters.dart';
import '../utils/orders_reload_policy.dart';
import '../widgets/order_row.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int? studentId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  /// Si la pestaña está visible. Al volver a activarse se recargan los pedidos
  /// solo si están viejos o algo los invalidó (ver [OrdersReloadPolicy]).
  final bool isActive;

  /// Burbuja de perfil a la derecha del título (la pone el ParentShell).
  final Widget? profileAction;

  /// Servicio de pedidos; se inyecta en las pruebas.
  final MenuService? menuService;

  const OrdersScreen({
    super.key,
    this.studentId,
    this.embedded = false,
    this.isActive = true,
    this.profileAction,
    this.menuService,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  /// Separación entre la cabecera y la barra del hijo (o el selector).
  static const double _headerGap = 18;

  late final MenuService _menuService = widget.menuService ?? MenuService();
  bool _isLoading = true;
  List<OrderEntry> _orders = [];
  String? _errorMessage;

  /// Aviso cuando solo uno de los dos orígenes (preórdenes / compras en caja) falló.
  String? _partialWarning;
  OrderStatusFilter _filter = OrderStatusFilter.all;

  /// Mes de "Entregados"; nulo = el más reciente con pedidos.
  DateTime? _month;
  int? _studentId;
  ChildrenProvider? _childrenProvider;

  final OrdersReloadPolicy _reloadPolicy = OrdersReloadPolicy();

  /// Identifica la última carga pedida: una respuesta de una carga anterior
  /// (otro hijo, otro refresco) se descarta para no pisar datos más nuevos.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    if (widget.embedded) {
      _childrenProvider = context.read<ChildrenProvider>();
      _studentId = _childrenProvider!.selectedChild?.id ?? _studentId;
      _childrenProvider!.addListener(_onSelectedChildChanged);
    }
    OrdersReloadSignal.listenable.addListener(_onReloadRequested);
    _fetchOrders();
  }

  @override
  void dispose() {
    _childrenProvider?.removeListener(_onSelectedChildChanged);
    OrdersReloadSignal.listenable.removeListener(_onReloadRequested);
    super.dispose();
  }

  @override
  void didUpdateWidget(OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _reloadIfNeeded();
  }

  /// Recarga solo con la pestaña visible y si los datos están viejos o
  /// invalidados; una pestaña oculta no pide nada.
  void _reloadIfNeeded() {
    if (!mounted || !widget.isActive || !_reloadPolicy.shouldReload) return;
    _fetchOrders();
  }

  /// Los pedidos siguen al hijo seleccionado global. Si la pestaña está oculta
  /// se descartan los datos del hijo anterior y se espera a que se muestre.
  void _onSelectedChildChanged() {
    final id = _childrenProvider?.selectedChild?.id;
    if (!mounted || id == _studentId) return;
    _loadToken++;
    _reloadPolicy.invalidate();
    setState(() {
      _studentId = id;
      _isLoading = true;
    });
    _reloadIfNeeded();
  }

  /// Hubo una acción que cambia los pedidos (p. ej. una compra nueva).
  void _onReloadRequested() {
    _reloadPolicy.invalidate();
    _reloadIfNeeded();
  }

  /// Ejecuta una carga sin lanzar: devuelve sus pedidos o el mensaje de error.
  Future<({List<OrderEntry> entries, String? error})> _safeLoad(
    Future<List<OrderEntry>> Function() load,
  ) async {
    try {
      return (entries: await load(), error: null);
    } catch (e) {
      return (entries: const <OrderEntry>[], error: errorMessageOf(e));
    }
  }

  Future<void> _fetchOrders() async {
    final token = ++_loadToken;
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
    if (!mounted || token != _loadToken) return;

    final errors = [
      for (final r in results)
        if (r.error != null) r.error!,
    ];
    final bothFailed = errors.length == results.length;
    if (errors.isEmpty) _reloadPolicy.markLoaded();
    setState(() {
      _orders = [for (final r in results) ...r.entries];
      _errorMessage = bothFailed ? errors.first : null;
      _partialWarning = (!bothFailed && errors.isNotEmpty)
          ? 'Algunos pedidos no se pudieron cargar. Desliza para reintentar.'
          : null;
      _isLoading = false;
    });
  }

  void _openDetail(OrderEntry order) {
    final child = _childrenProvider?.children
        .where((c) => c.id == order.studentId)
        .firstOrNull;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OrderDetailScreen(order: order, walletId: child?.walletId),
      ),
    );
  }

  /// "Octubre 2026".
  String _monthLabel(DateTime date) {
    final month = DateFormatter.monthName(date);
    return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final showFilters =
        !_isLoading && _errorMessage == null && _orders.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topRight, design: true),
          ),
          ResponsiveCenter(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabHeader(
                    leading: Row(
                      children: [
                        if (!widget.embedded) ...[
                          const SubpageBackButton(),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pedidos', style: AppText.tabTitle),
                              const SizedBox(height: 2),
                              Text(
                                'Lo que se pidió, pendiente o entregado',
                                style: AppText.secondary.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: widget.profileAction,
                  ),
                  const SizedBox(height: _headerGap),
                  if (widget.embedded)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.page,
                      ),
                      child: ChildSwitchBar(label: 'Pedidos de'),
                    ),
                  if (showFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.md,
                        AppSpacing.page,
                        0,
                      ),
                      child: SegmentedSwitch<OrderStatusFilter>(
                        options: [
                          for (final f in OrderStatusFilter.values)
                            (f, f.label),
                        ],
                        selected: _filter,
                        height: 42,
                        fontSize: 14.5,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                    ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ],
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
      return _scrollable(
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
      );
    }

    if (_orders.isEmpty) {
      return _scrollable(
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Todavía no hay pedidos',
          message: 'Tus preórdenes y las compras en caja aparecerán aquí.',
        ),
      );
    }

    final orders = filterOrdersByStatus(_orders, _filter);
    if (orders.isEmpty) {
      return _scrollable(
        const EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No hay pedidos en esta sección',
          message: 'Prueba con otro filtro.',
        ),
      );
    }

    // "Pendientes" por fecha de entrega más próxima; "Entregados" del mes
    // elegido, del más reciente al más antiguo y agrupados por día.
    final pending = orders.where((o) => o.isPendingPickup).toList()
      ..sort((a, b) {
        if (a.deliveryDate.isNotEmpty && b.deliveryDate.isNotEmpty) {
          return a.deliveryDate.compareTo(b.deliveryDate);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    final delivered = orders.where((o) => !o.isPendingPickup).toList();
    final months = monthsOf(delivered);
    final month = months.contains(_month) ? _month : months.firstOrNull;
    final history =
        month == null ? <OrderEntry>[] : ordersInMonth(delivered, month)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final rows = <Object>[
      if (_partialWarning != null) _PartialWarning(_partialWarning!),
      if (pending.isNotEmpty) ...[
        _Section(
          'Pendientes',
          detail:
              '${pending.length} '
              '${pending.length == 1 ? 'pedido' : 'pedidos'}',
        ),
        ...pending,
      ],
      if (month != null) ...[
        _Section(
          'Entregados',
          monthLabel: _monthLabel(month),
          onMonthTap: () => _pickMonth(months, month),
        ),
        ..._groupByDay(history),
      ],
    ];

    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is _Section) return _buildSectionTitle(row);
          if (row is _DayGroup) {
            final afterDay = index > 0 && rows[index - 1] is _DayGroup;
            return _buildDayGroup(row, topGap: afterDay ? 14 : 4);
          }
          if (row is _PartialWarning) return _buildPartialWarning(row.message);
          final order = row as OrderEntry;
          // Entre pedidos pendientes 10; el último no deja hueco extra.
          final more = index + 1 < rows.length && rows[index + 1] is OrderEntry;
          return Padding(
            padding: EdgeInsets.only(bottom: more ? 10 : 0),
            child: OrderRow(order: order, onTap: () => _openDetail(order)),
          );
        },
      ),
    );
  }

  /// Agrupa los pedidos (ya ordenados) por día: una tarjeta por día.
  List<_DayGroup> _groupByDay(List<OrderEntry> sorted) {
    final groups = <_DayGroup>[];
    for (final order in sorted) {
      final day = orderDay(order);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add(_DayGroup(day, []));
      }
      groups.last.orders.add(order);
    }
    return groups;
  }

  Future<void> _pickMonth(List<DateTime> months, DateTime selected) async {
    final picked = await AppBottomSheet.show<DateTime>(
      context,
      title: 'Elige un mes',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final month in months)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _monthLabel(month),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: month == selected
                  ? const Icon(Icons.check, color: AppColors.secondary500)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(month),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _month = picked);
  }

  Widget _scrollable(Widget child) {
    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _fetchOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [child],
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

  Widget _buildSectionTitle(_Section section) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sectionTitleXs,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (section.monthLabel != null)
            _MonthButton(label: section.monthLabel!, onTap: section.onMonthTap)
          else if (section.detail.isNotEmpty)
            Text(section.detail, style: AppText.secondaryLg),
        ],
      ),
    );
  }

  /// "Jueves 22 de octubre" sobre una tarjeta con los pedidos de ese día.
  Widget _buildDayGroup(_DayGroup group, {required double topGap}) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              DateFormatter.formatLongCapitalized(group.day),
              style: AppText.secondary.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.orders.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  OrderRow(
                    order: group.orders[i],
                    grouped: true,
                    onTap: () => _openDetail(group.orders[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón "Octubre 2026 ▾" que abre la lista de meses con pedidos entregados.
class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cambiar de mes. $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.secondaryLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.secondary500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marca de fila para el título de una sección de la lista: con un texto a la
/// derecha ([detail]) o con el selector de mes ([monthLabel]).
class _Section {
  final String title;
  final String detail;
  final String? monthLabel;
  final VoidCallback? onMonthTap;

  const _Section(
    this.title, {
    this.detail = '',
    this.monthLabel,
    this.onMonthTap,
  });
}

/// Marca de fila para los pedidos de un mismo día.
class _DayGroup {
  final DateTime day;
  final List<OrderEntry> orders;

  _DayGroup(this.day, this.orders);
}

/// Marca de fila para el aviso de carga parcial dentro de la lista.
class _PartialWarning {
  final String message;

  const _PartialWarning(this.message);
}
