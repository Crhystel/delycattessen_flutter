import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_switch_bar.dart';
import '../models/menu_models.dart';
import '../providers/parent_menu_controller.dart';
import '../widgets/catalog_search_row.dart';
import '../widgets/catalog_title_block.dart';
import '../widgets/menu_days_strip.dart';
import '../widgets/menu_dish_card.dart';
import 'cart_screen.dart';
import 'dish_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final int? studentId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  /// Fecha preseleccionada (opcional, p.ej. al tocar un platillo desde Inicio)
  final DateTime? initialDate;

  /// Cambia cada vez que Inicio vuelve a pedir un día: la pantalla abre
  /// [initialDate] sin recrearse (así conserva el carrito). Con la misma fecha
  /// pedida dos veces, el cambio de este valor es lo que la distingue.
  final Object? dateRequest;

  /// Widget bajo el título (selector Menú/Productos del ParentShell).
  final Widget? headerAccessory;

  /// Burbuja de perfil a la derecha del título (la pone el ParentShell).
  final Widget? profileAction;

  /// Estado del menú. Por defecto la pantalla crea (y libera) el suyo; en las
  /// pruebas se inyecta uno con un servicio simulado.
  final ParentMenuController? menuController;

  const MenuScreen({
    super.key,
    this.studentId,
    this.embedded = false,
    this.initialDate,
    this.dateRequest,
    this.headerAccessory,
    this.profileAction,
    this.menuController,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with NotificationMixin {
  late final ParentMenuController _menu =
      widget.menuController ?? ParentMenuController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Child? _selectedChild;
  bool _hasInitializedSelectedChild = false;

  /// Día pedido por Inicio mientras el menú aún cargaba (p. ej. al cambiar de
  /// hijo a la vez): se abre en cuanto termina la carga.
  DateTime? _pendingDate;
  late final ChildrenProvider _childrenProvider;

  // Lecturas del estado del menú, que vive en [_menu].
  bool get _isLoading => _menu.isLoading;
  String? get _errorMessage => _menu.errorMessage;
  List<MenuDay> get _days => _menu.days;
  MenuDay? get _selectedDay => _menu.selectedDay;
  Map<int, int> get _cart => _menu.cart;
  String get _searchQuery => _menu.searchQuery;

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenuChanged);
    _childrenProvider = context.read<ChildrenProvider>();
    _childrenProvider.addListener(_onSelectedChildChanged);

    Future.microtask(() async {
      await _childrenProvider.ensureLoaded();
      _initializeSelectedChild();
    });
  }

  @override
  void didUpdateWidget(MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requested = widget.initialDate;
    final changed =
        requested != oldWidget.initialDate ||
        widget.dateRequest != oldWidget.dateRequest;
    if (requested == null || !changed || !_hasInitializedSelectedChild) return;
    _pendingDate = requested;
    if (!_isLoading) _openPendingDate();
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenuChanged);
    if (widget.menuController == null) _menu.dispose();
    _childrenProvider.removeListener(_onSelectedChildChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onMenuChanged() {
    if (mounted) setState(() {});
  }

  void _onSelectedChildChanged() {
    if (!mounted || !_hasInitializedSelectedChild) return;
    final selected = _childrenProvider.selectedChild;
    if (selected == null) return;
    if (selected.id != _selectedChild?.id) {
      _confirmAndSwitchChild(selected);
    } else if (!identical(selected, _selectedChild)) {
      setState(() => _selectedChild = selected);
    }
  }

  void _initializeSelectedChild() {
    if (_hasInitializedSelectedChild || !mounted) return;
    if (widget.studentId != null) {
      _childrenProvider.select(widget.studentId!);
    }
    final initial = _childrenProvider.selectedChild;
    if (initial == null) {
      _menu.stopLoading();
      return;
    }

    setState(() {
      _selectedChild = initial;
      _hasInitializedSelectedChild = true;
    });
    _fetchMonthlyMenu(initial.id);
  }

  Future<void> _fetchMonthlyMenu(int studentId) async {
    await _menu.load(
      studentId,
      initialDate: _pendingDate ?? widget.initialDate,
    );
    if (mounted) _openPendingDate();
  }

  /// Abre el día que pidió Inicio, si existe en el menú cargado.
  void _openPendingDate() {
    final date = _pendingDate;
    if (date == null) return;
    _pendingDate = null;
    final iso = DateFormatter.toIsoDate(date);
    final day = _days.where((d) => d.date == iso).firstOrNull;
    if (day != null) _onSelectDay(day);
  }

  Future<void> _refreshMenu() async {
    if (_selectedChild != null) {
      await _fetchMonthlyMenu(_selectedChild!.id);
      await _childrenProvider.refresh();
    }
  }

  Future<void> _confirmAndSwitchChild(Child newChild) async {
    if (_cart.isNotEmpty) {
      final confirmed = await AppConfirmationDialog.show(
        context,
        title: 'Cambiar de estudiante',
        message:
            'Tienes productos en el carrito para ${_selectedChild?.firstName ?? "este estudiante"}. Si cambias, el carrito se vaciará.',
        confirmLabel: 'Cambiar y vaciar',
        cancelLabel: 'Conservar',
        isDestructive: true,
      );
      if (!mounted) return;
      if (!confirmed) {
        // Se conserva al hijo del menú: la selección global vuelve a él para
        // que Pedidos y Billetera no apunten a otro.
        final current = _selectedChild;
        if (current != null) _childrenProvider.select(current.id);
        return;
      }
    }

    _menu.clearCart();
    setState(() => _selectedChild = newChild);
    _fetchMonthlyMenu(newChild.id);
  }

  Future<void> _onSelectDay(MenuDay day) async {
    if (day.id == _selectedDay?.id) return;

    if (day.isBlockedByParentalControl) {
      showWarningSnackBar(
        day.blockedReason ??
            'Este día no está habilitado por el control parental.',
        title: 'Día bloqueado',
      );
      return;
    }

    if (_cart.isNotEmpty) {
      final currentFormatted = _selectedDay != null
          ? DateFormatter.formatLong(
              DateFormatter.parseIsoDate(_selectedDay!.date),
            )
          : 'el día actual';
      final confirmed = await AppConfirmationDialog.show(
        context,
        title: 'Cambiar de día',
        message:
            'Tienes productos en el carrito para $currentFormatted. Si cambias de día se vaciará el carrito.',
        confirmLabel: 'Cambiar y vaciar',
        cancelLabel: 'Conservar',
        isDestructive: true,
      );
      if (!confirmed) return;
    }

    _searchController.clear();
    _menu.selectDay(day);
  }

  void _addToCart(int dishId, int quantity) =>
      _menu.addToCart(dishId, quantity);

  void _showAllergenBlockedDialog(MenuDish dish) {
    final childName = _selectedChild != null
        ? '${_selectedChild!.firstName} ${_selectedChild!.lastName}'
        : 'este estudiante';
    final allergenList = dish.allergens.isNotEmpty
        ? dish.allergens.join(', ')
        : 'alérgenos registrados';

    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'Platillo no disponible',
      message:
          '"${dish.name}" contiene $allergenList, registrados como alergias de $childName. No se puede ordenar este producto.',
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _menu.setSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _menu.total;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topRight, design: true),
          ),
          ResponsiveCenter(
            maxWidth: AppLayout.wideMaxWidth,
            // The header adds the status bar inset itself (it stays pinned
            // under it), so the page is drawn edge to edge.
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.secondary500,
                      edgeOffset: topInset,
                      onRefresh: _refreshMenu,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Only the search field and the days stay; the title,
                          // selector and banner shrink together with the scroll
                          // (1 to 1 with the finger) and return at the top.
                          CollapsingHeader(
                            backgroundColor: AppColors.ink50,
                            transparentAtTop: true,
                            keep: CollapsingHeaderKeep.bottom,
                            topInset: topInset,
                            kept: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CatalogSearchRow(
                                  hintText: 'Buscar platos',
                                  outlined: true,
                                  design: true,
                                  showBackButton: !widget.embedded,
                                  searchController: _searchController,
                                  onSearchChanged: _onSearchChanged,
                                ),
                                if (!_isLoading && _days.isNotEmpty)
                                  MenuDaysStrip(
                                    design: true,
                                    days: _days,
                                    selectedDayId: _selectedDay?.id,
                                    onSelect: _onSelectDay,
                                  ),
                              ],
                            ),
                            collapsible: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CatalogTitleBlock(
                                  design: true,
                                  title: 'Menú',
                                  accessory: widget.headerAccessory,
                                  trailing: widget.profileAction,
                                ),
                                if (_selectedChild != null)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      AppSpacing.page,
                                      AppSpacing.lg,
                                      AppSpacing.page,
                                      0,
                                    ),
                                    child: ChildSwitchBar(
                                      label: 'Pidiendo para',
                                      showBalance: true,
                                      sheetTitle: '¿Para quién estás pidiendo?',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ..._buildContent(),
                        ],
                      ),
                    ),
                  ),
                  if (total > 0 && _selectedDay != null)
                    _buildCartSummary(total, _selectedDay!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading, error, empty menu or the dishes of the chosen day, as slivers of
  /// the same scroll view as the header.
  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondary500),
          ),
        ),
      ];
    }
    if (_errorMessage != null) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildErrorView()),
      ];
    }
    if (_days.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView()),
      ];
    }

    final dishes = _menu.visibleDishes;
    if (dishes.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.restaurant,
            title: _searchQuery.isNotEmpty
                ? 'No encontramos "$_searchQuery"'
                : 'No hay platillos asignados para este día',
            message: _searchQuery.isNotEmpty
                ? 'Prueba con otro término.'
                : null,
          ),
        ),
      ];
    }
    final day = _selectedDay;
    return [
      if (day != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              22,
              AppSpacing.page,
              0,
            ),
            child: _DayHeading(day: day, dishCount: dishes.length),
          ),
        ),
      SliverResponsiveItemList(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          10,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        itemCount: dishes.length,
        itemBuilder: (context, index) => _buildDishCard(dishes[index]),
      ),
    ];
  }

  Widget _buildDishCard(MenuDish dish) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MenuDishCard(
        dish: dish,
        inCart: _cart.containsKey(dish.id),
        onShowAllergens: () => _showDishAllergens(dish),
        onToggle: () => _cart.containsKey(dish.id)
            ? _menu.removeFromCart(dish.id)
            : _addToCart(dish.id, 1),
        onTap: () {
          if (dish.hasStudentAllergens) {
            _showAllergenBlockedDialog(dish);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DishDetailScreen(
                dish: dish,
                onAdd: (qty) => _addToCart(dish.id, qty),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Chip "Ver alérgenos": si choca con las alergias del hijo es el aviso de
  /// bloqueo; si no, solo lista lo que contiene el platillo.
  void _showDishAllergens(MenuDish dish) {
    if (dish.hasStudentAllergens) {
      _showAllergenBlockedDialog(dish);
      return;
    }
    AppNotificationDialog.show(
      context,
      type: NotificationType.warning,
      title: 'Alérgenos de ${dish.name}',
      message: dish.allergens.isEmpty
          ? 'Este platillo no tiene alérgenos registrados.'
          : 'Contiene: ${dish.allergens.join(', ')}.',
    );
  }

  Widget _buildCartSummary(double total, MenuDay currentDay) {
    final count = _menu.cartItemCount;
    final childName = _selectedChild?.firstName ?? 'tu hijo/a';
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.secondary500,
        borderRadius: AppRadius.mdAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${count == 1 ? '1 plato' : '$count platos'} para $childName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.secondary.copyWith(
                    color: AppColors.secondary50,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: AppText.price.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: AppColors.ink900,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.controlAll,
              ),
              textStyle: AppText.button.copyWith(fontSize: 15),
            ),
            onPressed: () => _openCart(currentDay),
            child: const Text('Confirmar pedido'),
          ),
        ],
      ),
    );
  }

  void _openCart(MenuDay currentDay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          studentId: _selectedChild?.id ?? widget.studentId ?? 0,
          deliveryDate: currentDay.date,
          cart: _cart,
          dishes: currentDay.dishes,
          childName: _selectedChild != null
              ? '${_selectedChild!.firstName} ${_selectedChild!.lastName}'
              : '',
          childBalance: _selectedChild?.balance,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _menu.clearCart();
        _childrenProvider.refresh();
      } else if (result is Map<int, int>) {
        _menu.replaceCart(result);
      }
    });
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.restaurant_menu,
          title: 'Aún no hay un menú publicado para la institución.',
          message:
              'Cuando la institución publique el menú mensual, aparecerá aquí.',
          actionLabel: 'Actualizar',
          onAction: _refreshMenu,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar el menú',
          message: _errorMessage,
          actionLabel: 'Reintentar',
          onAction: () {
            if (_selectedChild != null) {
              _fetchMonthlyMenu(_selectedChild!.id);
            }
          },
        ),
      ),
    );
  }
}

/// "Martes 10 de noviembre" con la cantidad de platos del día a la derecha.
class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.day, required this.dishCount});

  final MenuDay day;
  final int dishCount;

  @override
  Widget build(BuildContext context) {
    final date = DateFormatter.parseIsoDate(day.date);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            DateFormatter.formatLongCapitalized(date),
            style: AppText.sectionTitleSm,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          dishCount == 1 ? '1 plato' : '$dishCount platos',
          style: AppText.secondaryLg,
        ),
      ],
    );
  }
}
