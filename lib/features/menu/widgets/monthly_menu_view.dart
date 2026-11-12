import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/collapsing_scroll_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../models/menu_models.dart';
import '../providers/parent_menu_controller.dart';
import '../screens/dish_detail_screen.dart';
import '../utils/allergen_advisory.dart';
import '../utils/dish_allergens.dart';
import 'catalog_search_row.dart';
import 'catalog_title_block.dart';
import 'menu_days_strip.dart';
import 'menu_dish_card.dart';
import 'monthly_menu_day_heading.dart';
import 'monthly_menu_ordering.dart';

/// Menú del mes: la misma vista para todos los roles. Burbujas decorativas,
/// cabecera plegable (título, selector y barra del hijo se pliegan; quedan el
/// buscador y los días), contador de platos y la lista de platillos.
///
/// Las diferencias entre roles llegan como datos o callbacks: con [ordering]
/// nulo la vista es de solo lectura (sin "Agregar", sin pie, el detalle sin
/// "Añadir"). No conoce al hijo ni lee ningún provider: lo del hijo entra solo
/// por [childBar] y por los callbacks.
class MonthlyMenuView extends StatefulWidget {
  const MonthlyMenuView({
    super.key,
    required this.menu,
    required this.title,
    required this.onRefresh,
    required this.onRetry,
    this.showBackButton = false,
    this.headerAccessory,
    this.profileAction,
    this.childBar,
    this.footer,
    this.onSelectDay,
    this.ordering,
    this.allergenAudience = AllergenAudience.unknown,
    this.orderingFor,
    this.onChangeChild,
  });

  final ParentMenuController menu;
  final String title;

  /// Pull-to-refresh y "Actualizar" cuando no hay menú publicado.
  final Future<void> Function() onRefresh;

  /// "Reintentar" cuando falla la carga.
  final VoidCallback onRetry;
  final bool showBackButton;

  /// Widget bajo el título (selector Menú/Productos del padre).
  final Widget? headerAccessory;

  /// Widget a la derecha del título (burbuja de perfil).
  final Widget? profileAction;

  /// Barra bajo el título para elegir hijo; se pliega con la cabecera.
  final Widget? childBar;

  /// Pie fijo bajo la lista (barra del carrito).
  final Widget? footer;

  /// Cambia de día. Por defecto, `menu.selectDay`.
  final Future<void> Function(MenuDay day)? onSelectDay;

  /// Acciones de pedido; nulo = solo lectura.
  final MonthlyMenuOrdering? ordering;

  /// Whose allergies the dish detail is checked against.
  final AllergenAudience allergenAudience;

  /// Name of the child the order is for, shown in the dish detail.
  final String? orderingFor;

  /// Opens the child picker from the dish detail; true if the child changed.
  final Future<bool> Function()? onChangeChild;

  @override
  State<MonthlyMenuView> createState() => _MonthlyMenuViewState();
}

class _MonthlyMenuViewState extends State<MonthlyMenuView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int? _shownDayId;

  ParentMenuController get _menu => widget.menu;

  @override
  void initState() {
    super.initState();
    _shownDayId = _menu.selectedDay?.id;
    _menu.addListener(_onMenuChanged);
  }

  @override
  void didUpdateWidget(MonthlyMenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu != widget.menu) {
      oldWidget.menu.removeListener(_onMenuChanged);
      _shownDayId = _menu.selectedDay?.id;
      _menu.addListener(_onMenuChanged);
    }
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenuChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onMenuChanged() {
    if (!mounted) return;
    final dayId = _menu.selectedDay?.id;
    // The search is per day: a new day starts with an empty field.
    if (_shownDayId != null && dayId != _shownDayId) {
      _searchDebounce?.cancel();
      _searchController.clear();
      if (_menu.searchQuery.isNotEmpty) _menu.setSearchQuery('');
    }
    _shownDayId = dayId;
    setState(() {});
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _menu.setSearchQuery(value);
    });
  }

  void _selectDay(MenuDay day) {
    final custom = widget.onSelectDay;
    if (custom == null) {
      _menu.selectDay(day);
    } else {
      unawaited(custom(day));
    }
  }

  /// The detail always opens, with or without allergen conflicts: the notice
  /// is what blocks the order, never hiding the dish.
  void _openDish(MenuDish dish) {
    final ordering = widget.ordering;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DishDetailScreen(
          dish: dish,
          servedDate: DateTime.tryParse(_menu.selectedDay?.date ?? ''),
          advisory: dishAdvisory(dish, audience: widget.allergenAudience),
          orderingFor: widget.orderingFor,
          onChangeChild: widget.onChangeChild,
          onAdd: ordering == null
              ? null
              : (qty) => ordering.onAddDish(dish, qty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final dishes = _showsDishes ? _menu.visibleDishes : const <MenuDish>[];

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
                      onRefresh: widget.onRefresh,
                      // The header always folds completely from 2 dishes on.
                      child: CollapsingScrollView(
                        itemCount: dishes.length,
                        header: _buildHeader(topInset),
                        slivers: _buildContent(dishes),
                      ),
                    ),
                  ),
                  ?widget.footer,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// There is a day with its dishes to show (not loading, failed or empty).
  bool get _showsDishes =>
      !_menu.isLoading &&
      _menu.errorMessage == null &&
      _menu.days.isNotEmpty &&
      _menu.selectedDay != null;

  /// Only the search field and the days stay; the title, selector and child
  /// bar shrink with the scroll (1 to 1 with the finger) and return at the top.
  /// The bubbles are also drawn behind the pinned band so it does not cut them.
  Widget _buildHeader(double topInset) {
    return CollapsingHeader(
      backgroundColor: AppColors.ink50,
      transparentAtTop: true,
      keep: CollapsingHeaderKeep.bottom,
      topInset: topInset,
      backdrop: const FloatingBubbles(
        corner: BubbleCorner.topRight,
        design: true,
      ),
      kept: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatalogSearchRow(
            hintText: 'Buscar platos',
            outlined: true,
            design: true,
            showBackButton: widget.showBackButton,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
          if (!_menu.isLoading && _menu.days.isNotEmpty)
            MenuDaysStrip(
              design: true,
              days: _menu.days,
              selectedDayId: _menu.selectedDay?.id,
              onSelect: _selectDay,
            ),
        ],
      ),
      collapsible: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatalogTitleBlock(
            design: true,
            title: widget.title,
            accessory: widget.headerAccessory,
            trailing: widget.profileAction,
          ),
          ?widget.childBar,
        ],
      ),
    );
  }

  /// Loading, error, empty menu or the dishes of the chosen day, as slivers of
  /// the same scroll view as the header.
  List<Widget> _buildContent(List<MenuDish> dishes) {
    if (_menu.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondary500),
          ),
        ),
      ];
    }
    if (_menu.errorMessage != null) {
      return [
        _centered(
          EmptyState(
            icon: Icons.error_outline,
            title: 'No pudimos cargar el menú',
            message: _menu.errorMessage,
            actionLabel: 'Reintentar',
            onAction: widget.onRetry,
          ),
        ),
      ];
    }
    final day = _menu.selectedDay;
    if (_menu.days.isEmpty || day == null) {
      return [
        _centered(
          EmptyState(
            icon: Icons.restaurant_menu,
            title: 'Aún no hay un menú publicado para la institución.',
            message:
                'Cuando la institución publique el menú mensual, aparecerá aquí.',
            actionLabel: 'Actualizar',
            onAction: widget.onRefresh,
          ),
        ),
      ];
    }
    if (dishes.isEmpty) {
      final searching = _menu.searchQuery.isNotEmpty;
      return [
        if (day.isBlockedByParentalControl)
          SliverToBoxAdapter(
            child: MonthlyMenuDayHeading(day: day, dishCount: 0),
          ),
        SliverToBoxAdapter(
          child: EmptyState(
            icon: searching ? Icons.search_off : Icons.restaurant,
            title: searching
                ? 'No encontramos "${_menu.searchQuery}"'
                : 'No hay platillos asignados para este día',
            message: searching ? 'Prueba con otro término.' : null,
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: MonthlyMenuDayHeading(day: day, dishCount: dishes.length),
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

  Widget _centered(Widget child) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    ),
  );

  Widget _buildDishCard(MenuDish dish) {
    final ordering = widget.ordering;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MenuDishCard(
        dish: dish,
        inCart: _menu.cart.containsKey(dish.id),
        onShowAllergens: () => _openDish(dish),
        onToggle: ordering == null ? null : () => ordering.onToggleDish(dish),
        onTap: () => _openDish(dish),
      ),
    );
  }
}
