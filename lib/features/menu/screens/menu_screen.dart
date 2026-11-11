import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../../children/widgets/child_switch_bar.dart';
import '../models/menu_models.dart';
import '../providers/parent_menu_controller.dart';
import '../utils/allergen_advisory.dart';
import '../widgets/menu_cart_bar.dart';
import '../widgets/monthly_menu_ordering.dart';
import '../widgets/monthly_menu_view.dart';
import 'cart_screen.dart';

/// Menú del mes del padre: elige hijo, día y platillos y arma el carrito. Aquí
/// viven la selección del hijo, las confirmaciones y el carrito; lo que se ve
/// es [MonthlyMenuView], la misma vista de los demás roles.
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

  Child? _selectedChild;
  bool _hasInitializedSelectedChild = false;

  /// Día pedido por Inicio mientras el menú aún cargaba (p. ej. al cambiar de
  /// hijo a la vez): se abre en cuanto termina la carga.
  DateTime? _pendingDate;
  late final ChildrenProvider _childrenProvider;

  /// Child switch started by the selection listener; the dish detail waits for
  /// it to know whether the child really changed.
  Future<bool>? _switching;

  late final MonthlyMenuOrdering _ordering = MonthlyMenuOrdering(
    onToggleDish: (dish) {
      if (_hasConflict(dish)) return;
      _menu.cart.containsKey(dish.id)
          ? _menu.removeFromCart(dish.id)
          : _menu.addToCart(dish.id, 1);
    },
    onAddDish: (dish, quantity) {
      if (!_hasConflict(dish)) _menu.addToCart(dish.id, quantity);
    },
  );

  /// A dish with allergens of the child never reaches the cart, whatever the UI
  /// offers.
  static bool _hasConflict(MenuDish dish) =>
      dish.hasStudentAllergens || dish.conflictingAllergens.isNotEmpty;

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
    if (!_menu.isLoading) _openPendingDate();
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenuChanged);
    if (widget.menuController == null) _menu.dispose();
    _childrenProvider.removeListener(_onSelectedChildChanged);
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
      _switching = _confirmAndSwitchChild(selected);
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
    final day = _menu.days.where((d) => d.date == iso).firstOrNull;
    if (day != null) _onSelectDay(day);
  }

  Future<void> _refreshMenu() async {
    if (_selectedChild != null) {
      await _fetchMonthlyMenu(_selectedChild!.id);
      await _childrenProvider.refresh();
    }
  }

  void _retry() {
    final child = _selectedChild;
    if (child != null) _fetchMonthlyMenu(child.id);
  }

  /// True when the menu now belongs to [newChild]; false if the parent kept the
  /// current child (declined to empty the cart).
  Future<bool> _confirmAndSwitchChild(Child newChild) async {
    if (_menu.cart.isNotEmpty) {
      final confirmed = await AppConfirmationDialog.show(
        context,
        title: 'Cambiar de estudiante',
        message:
            'Tienes productos en el carrito para ${_selectedChild?.firstName ?? "este estudiante"}. Si cambias, el carrito se vaciará.',
        confirmLabel: 'Cambiar y vaciar',
        cancelLabel: 'Conservar',
        isDestructive: true,
      );
      if (!mounted) return false;
      if (!confirmed) {
        // Se conserva al hijo del menú: la selección global vuelve a él para
        // que Pedidos y Billetera no apunten a otro.
        final current = _selectedChild;
        if (current != null) _childrenProvider.select(current.id);
        return false;
      }
    }

    _menu.clearCart();
    setState(() => _selectedChild = newChild);
    _fetchMonthlyMenu(newChild.id);
    return true;
  }

  /// Opens the child picker from the dish detail. True when the menu changed
  /// to another child (the detail then closes).
  Future<bool> _pickAnotherChild() async {
    final previousId = _selectedChild?.id;
    await ChildPickerSheet.show(
      context,
      _childrenProvider,
      title: '¿Para quién estás pidiendo?',
    );
    await _switching;
    return mounted && _selectedChild?.id != previousId;
  }

  Future<void> _onSelectDay(MenuDay day) async {
    final current = _menu.selectedDay;
    if (day.id == current?.id) return;

    if (day.isBlockedByParentalControl) {
      showWarningSnackBar(
        day.blockedReason ??
            'Este día no está habilitado por el control parental.',
        title: 'Día bloqueado',
      );
      return;
    }

    if (_menu.cart.isNotEmpty) {
      final currentFormatted = current != null
          ? DateFormatter.formatLong(DateFormatter.parseIsoDate(current.date))
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
      if (!confirmed || !mounted) return;
    }

    _menu.selectDay(day);
  }

  void _openCart(MenuDay currentDay) {
    final cart = _menu.cart;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          studentId: _selectedChild?.id ?? widget.studentId ?? 0,
          deliveryDate: currentDay.date,
          cart: cart,
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

  @override
  Widget build(BuildContext context) {
    final total = _menu.total;
    final day = _menu.selectedDay;
    final child = _selectedChild;
    final canSwitchChild =
        context.watch<ChildrenProvider>().children.length > 1;

    return MonthlyMenuView(
      menu: _menu,
      title: 'Menú',
      showBackButton: !widget.embedded,
      headerAccessory: widget.headerAccessory,
      profileAction: widget.profileAction,
      onRefresh: _refreshMenu,
      onRetry: _retry,
      onSelectDay: _onSelectDay,
      ordering: _ordering,
      allergenAudience: child == null
          ? AllergenAudience.unknown
          : AllergenAudience.named(child.firstName),
      orderingFor: child?.displayName,
      onChangeChild: canSwitchChild ? _pickAnotherChild : null,
      childBar: _selectedChild == null
          ? null
          : const Padding(
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
      footer: total > 0 && day != null
          ? MenuCartBar(
              count: _menu.cartItemCount,
              total: total,
              childName: _selectedChild?.firstName ?? 'tu hijo/a',
              onConfirm: () => _openCart(day),
            )
          : null,
    );
  }
}
