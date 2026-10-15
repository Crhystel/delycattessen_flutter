import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
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

  const MenuScreen({
    super.key,
    this.studentId,
    this.embedded = false,
    this.initialDate,
    this.headerAccessory,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with NotificationMixin {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  String? _errorMessage;

  List<MenuDay> _days = [];
  MenuDay? _selectedDay;

  final Map<int, int> _cart = {}; // dishId -> quantity
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  Child? _selectedChild;
  bool _hasInitializedSelectedChild = false;
  late final ChildrenProvider _childrenProvider;

  @override
  void initState() {
    super.initState();
    _childrenProvider = context.read<ChildrenProvider>();
    _childrenProvider.addListener(_onSelectedChildChanged);

    Future.microtask(() async {
      await _childrenProvider.ensureLoaded();
      _initializeSelectedChild();
    });
  }

  @override
  void dispose() {
    _childrenProvider.removeListener(_onSelectedChildChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _selectedChild = initial;
      _hasInitializedSelectedChild = true;
    });
    _fetchMonthlyMenu(initial.id);
  }

  Future<void> _fetchMonthlyMenu(int studentId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final days = await _menuService.getStudentMonthlyMenu(studentId);
      if (!mounted) return;

      MenuDay? targetDay;
      if (widget.initialDate != null) {
        final initialIso = DateFormatter.toIsoDate(widget.initialDate!);
        targetDay = days.where((d) => d.date == initialIso).firstOrNull;
      }
      targetDay ??= days.isNotEmpty ? days.first : null;

      setState(() {
        _days = days;
        _selectedDay = targetDay;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
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
      if (!confirmed) return;
    }

    setState(() {
      _selectedChild = newChild;
      _cart.clear();
    });
    _fetchMonthlyMenu(newChild.id);
  }

  Future<void> _onSelectDay(MenuDay day) async {
    if (day.id == _selectedDay?.id) return;

    if (day.isBlockedByParentalControl) {
      showWarningSnackBar(
        day.blockedReason ?? 'Este día no está habilitado por el control parental.',
        title: 'Día bloqueado',
      );
      return;
    }

    if (_cart.isNotEmpty) {
      final currentFormatted = _selectedDay != null
          ? DateFormatter.formatLong(DateFormatter.parseIsoDate(_selectedDay!.date))
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

    setState(() {
      _selectedDay = day;
      _cart.clear();
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _addToCart(int dishId, int quantity) {
    setState(() {
      _cart[dishId] = (_cart[dishId] ?? 0) + quantity;
    });
  }

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
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  List<MenuDish> get _visibleDishes {
    if (_selectedDay == null) return [];
    final dishes = _selectedDay!.dishes;
    if (_searchQuery.isEmpty) return dishes;
    return dishes
        .where((d) => d.name.toLowerCase().contains(_searchQuery))
        .toList();
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
    final total = _cart.entries.fold<double>(0, (sum, entry) {
      if (_selectedDay == null) return sum;
      final matches = _selectedDay!.dishes.where((d) => d.id == entry.key);
      if (matches.isEmpty) return sum;
      return sum + (matches.first.price * entry.value);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_selectedChild != null) _buildChildBanner(children),
            const SizedBox(height: AppSpacing.sm),
            if (!_isLoading && _days.isNotEmpty) _buildDaysSelector(),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary500,
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _days.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              color: AppColors.secondary500,
                              onRefresh: _refreshMenu,
                              child: _buildDishList(),
                            ),
            ),
            if (total > 0 && _selectedDay != null)
              _buildCartSummary(total, _selectedDay!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                'Menú',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          if (widget.headerAccessory != null) ...[
            const SizedBox(height: AppSpacing.sm),
            widget.headerAccessory!,
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
              _onSearchChanged(value);
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search, color: AppColors.secondary500),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _onSearchChanged('');
                      },
                    ),
              filled: true,
              fillColor: AppColors.ink50,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
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
                Text(
                  'Pidiendo para ${child.firstName} · \$${(child.balance ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary700,
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

  Widget _buildDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Días disponibles',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final day = _days[index];
              final isSelected = _selectedDay?.id == day.id;
              final isBlocked = day.isBlockedByParentalControl;
              final parsedDate = DateFormatter.parseIsoDate(day.date);
              final weekdayShort = DateFormatter.shortWeekdayName(parsedDate);
              final dayNum = parsedDate.day.toString();

              return GestureDetector(
                onTap: () => _onSelectDay(day),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.grey.shade200
                            : isSelected
                                ? AppColors.secondary500
                                : AppColors.secondary50,
                        shape: BoxShape.circle,
                        border: isBlocked
                            ? Border.all(color: Colors.grey.shade400)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: isBlocked
                          ? Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Colors.grey.shade600,
                            )
                          : Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.secondary700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekdayShort,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isBlocked
                            ? Colors.grey.shade500
                            : isSelected
                                ? AppColors.secondary500
                                : AppColors.ink900.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDishList() {
    final dishes = _visibleDishes;

    if (dishes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.restaurant,
            title: _searchQuery.isNotEmpty
                ? 'No encontramos "$_searchQuery"'
                : 'No hay platillos asignados para este día',
            message: _searchQuery.isNotEmpty ? 'Prueba con otro término.' : null,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: dishes.length,
      itemBuilder: (context, index) => _buildDishCard(dishes[index]),
    );
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
                  Row(
                    children: [
                      Text(
                        '\$${dish.price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.brand700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasAllergens) ...[
                        const SizedBox(width: AppSpacing.sm),
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
                        memCacheWidth: AppImageCacheHelper.cacheSize(context, 100),
                        memCacheHeight: AppImageCacheHelper.cacheSize(context, 75),
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
                  setState(() => _cart.clear());
                  _childrenProvider.refresh();
                } else if (result is Map<int, int>) {
                  setState(() {
                    _cart.clear();
                    _cart.addAll(result);
                  });
                }
              });
            },
            child: Text(
              'Ver carrito (${_cart.values.fold(0, (sum, q) => sum + q)})',
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
          message: 'Cuando la institución publique el menú mensual, aparecerá aquí.',
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
