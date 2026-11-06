import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../models/menu_models.dart';
import '../providers/parent_menu_controller.dart';
import '../widgets/catalog_search_row.dart';
import '../widgets/catalog_title_block.dart';
import '../widgets/menu_days_strip.dart';
import 'cart_screen.dart';
import 'dish_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final int? studentId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  /// Fecha preseleccionada (opcional, p.ej. al tocar un platillo desde Inicio)
  final DateTime? initialDate;

  /// Widget bajo el título (selector Menú/Productos del ParentShell).
  final Widget? headerAccessory;

  /// Estado del menú. Por defecto la pantalla crea (y libera) el suyo; en las
  /// pruebas se inyecta uno con un servicio simulado.
  final ParentMenuController? menuController;

  const MenuScreen({
    super.key,
    this.studentId,
    this.embedded = false,
    this.initialDate,
    this.headerAccessory,
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

  Future<void> _fetchMonthlyMenu(int studentId) =>
      _menu.load(studentId, initialDate: widget.initialDate);

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
      if (!confirmed) return;
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

  void _openChildSwitcher(List<Child> children) {
    if (children.length <= 1) return;
    ChildPickerSheet.show(
      context,
      _childrenProvider,
      title: '¿Para quién estás pidiendo?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ChildrenProvider>().children;
    final total = _menu.total;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        maxWidth: AppLayout.wideMaxWidth,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondary500,
                  onRefresh: _refreshMenu,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Only the search field and the days stay; the title,
                      // selector and banner shrink together with the scroll
                      // (1 to 1 with the finger) and return at the top.
                      CollapsingHeader(
                        keep: CollapsingHeaderKeep.bottom,
                        kept: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CatalogSearchRow(
                              showBackButton: !widget.embedded,
                              searchController: _searchController,
                              onSearchChanged: (value) {
                                setState(() {});
                                _onSearchChanged(value);
                              },
                            ),
                            if (!_isLoading && _days.isNotEmpty)
                              MenuDaysStrip(
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
                              title: 'Menú',
                              accessory: widget.headerAccessory,
                            ),
                            if (_selectedChild != null)
                              _buildChildBanner(children),
                            const SizedBox(height: AppSpacing.sm),
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
    );
  }

  Widget _buildChildBanner(List<Child> children) {
    final canSwitch = children.length > 1;
    final child = _selectedChild!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: canSwitch ? () => _openChildSwitcher(children) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            decoration: BoxDecoration(
              color: AppColors.secondary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChildAvatarChip(imageUrl: child.profilePictureUrl, radius: 12),
                const SizedBox(width: 8),
                // Flexible: a long name or a large font is cut, never overflows.
                Flexible(
                  child: Text(
                    'Pidiendo para ${child.firstName} · \$${(child.balance ?? 0).toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary700,
                    ),
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: AppColors.secondary700,
                  ),
                ],
              ],
            ),
          ),
        ),
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
    return [
      SliverResponsiveItemList(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: dishes.length,
        itemBuilder: (context, index) => _buildDishCard(dishes[index]),
      ),
    ];
  }

  Widget _buildDishCard(MenuDish dish) {
    final hasAllergens = dish.hasStudentAllergens;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: hasAllergens ? 0.6 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          if (hasAllergens) {
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (dish.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dish.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // Wrap: with a large font the badge drops to the next line.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        '\$${dish.price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.brand700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasAllergens) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppColors.danger700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Alérgeno',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.danger700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: Container(
                width: 100,
                height: 75,
                color: AppColors.ink50,
                child: dish.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: dish.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: AppImageCacheHelper.cacheSize(
                          context,
                          100,
                        ),
                        memCacheHeight: AppImageCacheHelper.cacheSize(
                          context,
                          75,
                        ),
                        placeholder: (_, _) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary500,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.fastfood,
                          color: AppColors.secondary500,
                        ),
                      )
                    : const Icon(Icons.fastfood, color: AppColors.secondary500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(double total, MenuDay currentDay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
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
            },
            child: Text(
              'Ver carrito (${_menu.cartItemCount})',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
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
