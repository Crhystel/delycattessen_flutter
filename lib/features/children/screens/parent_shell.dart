import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/profile_bubble.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/services/auth_service.dart';
import '../utils/parent_navigation.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/profile_children_section.dart';
import '../../menu/widgets/menu_mode_switcher.dart';
import '../../menu/screens/parent_menu_tab.dart';
import '../../menu/screens/orders_screen.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../providers/children_provider.dart';
import 'children_list_screen.dart';

/// Contenedor de las 4 pestañas del padre (Inicio, Menú, Pedidos, Billetera).
/// Cambiar de pestaña NO apila pantallas: cada una conserva su estado y se
/// construye solo la primera vez que se visita (carga perezosa). También abre
/// "Mi perfil" desde la burbuja de cada pestaña y cierra la sesión.
class ParentShell extends StatefulWidget {
  final AuthService? authService;

  const ParentShell({super.key, this.authService});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> with NotificationMixin {
  static const int _tabCount = 4;

  late final AuthService _authService = widget.authService ?? AuthService();

  int _index = BottomNavDestination.home;
  final List<bool> _visited = List<bool>.filled(_tabCount, false)..[0] = true;
  DateTime? _initialMenuDate;
  MenuMode _initialMenuMode = MenuMode.monthly;

  /// Cambia cada vez que Inicio pide un día o "Productos": vuelve a crear la
  /// pestaña Menú con esa vista. Nulo = se conserva la que ya está abierta.
  Object? _menuRequest;
  MeResponse? _me;

  /// Cambia cada vez que Inicio pide recargar a un hijo: vuelve a crear la
  /// pestaña Billetera en "Recargar".
  int _rechargeRequest = 0;

  /// Sección con la que se vuelve a crear la pestaña Billetera: "Recargar", o
  /// "Movimientos" cuando otra pantalla redirige al historial.
  WalletSection _walletSection = WalletSection.recharge;

  @override
  void initState() {
    super.initState();
    ParentNavigation.walletMovements.addListener(_onWalletMovementsRequest);
    ParentNavigation.walletRecharge.addListener(_onWalletRechargeRequest);
    _loadMe();
  }

  @override
  void dispose() {
    ParentNavigation.walletMovements.removeListener(_onWalletMovementsRequest);
    ParentNavigation.walletRecharge.removeListener(_onWalletRechargeRequest);
    super.dispose();
  }

  /// Otra pantalla (ficha del hijo) pidió recargar: se elige al hijo y se abre
  /// Billetera en "Recargar".
  void _onWalletRechargeRequest() {
    final request = ParentNavigation.walletRecharge.value;
    if (request == null || !mounted) return;
    _rechargeChild(request.childId);
  }

  /// Otra pantalla (ficha del hijo, detalle de pedido) pidió ver los
  /// movimientos: se elige al hijo y se abre Billetera en "Movimientos".
  void _onWalletMovementsRequest() {
    final request = ParentNavigation.walletMovements.value;
    if (request == null || !mounted) return;
    final childId = request.childId;
    if (childId != null) context.read<ChildrenProvider>().select(childId);
    setState(() {
      _rechargeRequest++;
      _walletSection = WalletSection.movements;
      _invalidateTabs();
    });
    _goTo(BottomNavDestination.wallet);
  }

  Future<void> _loadMe() async {
    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
        _invalidateTabs();
      });
    } catch (_) {
      // Sin perfil la burbuja muestra "?" y "Mi perfil" lo vuelve a pedir.
    }
  }

  /// Letra de la burbuja: la del nombre o, si no hay, la del correo.
  String get _initial {
    final me = _me;
    if (me == null) return '';
    final source = me.displayName.isNotEmpty ? me.displayName : me.email ?? '';
    return source.trim().isEmpty ? '' : source.trim().substring(0, 1);
  }

  Future<void> _openProfile() async {
    try {
      final me = _me ?? await _authService.getMe();
      if (!mounted) return;
      final updated = await Navigator.of(context).push<MeResponse>(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            me: me,
            authService: _authService,
            extraSections: const ProfileChildrenSection(),
            onLogout: _confirmLogout,
          ),
        ),
      );
      if (updated != null && mounted) {
        setState(() {
          _me = updated;
          _invalidateTabs();
        });
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(errorMessageOf(e), title: 'No se pudo abrir tu perfil');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: Icons.logout,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que quieres cerrar tu sesión?',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _goTo(int index) {
    if (index == _index) return;
    final children = context.read<ChildrenProvider>().children;
    if (index != BottomNavDestination.home && children.isEmpty) {
      showWarningSnackBar(
        'Registra al menos un hijo para continuar.',
        title: 'Sin hijos registrados',
      );
      return;
    }
    setState(() {
      _index = index;
      _visited[index] = true;
    });
  }

  void _orderForChild(int childId) {
    context.read<ChildrenProvider>().select(childId);
    setState(() {
      _initialMenuDate = null;
      _initialMenuMode = MenuMode.monthly;
      _menuRequest = null;
      _invalidateTabs();
    });
    _goTo(BottomNavDestination.menu);
  }

  void _openMenuDay(int childId, DateTime date) {
    context.read<ChildrenProvider>().select(childId);
    setState(() {
      _initialMenuDate = date;
      _initialMenuMode = MenuMode.monthly;
      _menuRequest = Object();
      _invalidateTabs();
    });
    _goTo(BottomNavDestination.menu);
  }

  void _rechargeChild(int? childId) {
    if (childId != null) context.read<ChildrenProvider>().select(childId);
    setState(() {
      _rechargeRequest++;
      _walletSection = WalletSection.recharge;
      _invalidateTabs();
    });
    _goTo(BottomNavDestination.wallet);
  }

  /// Abre la pestaña Menú ya en "Productos" (banner de combo de Inicio).
  void _openProducts() {
    setState(() {
      _initialMenuDate = null;
      _initialMenuMode = MenuMode.products;
      _menuRequest = Object();
      _invalidateTabs();
    });
    _goTo(BottomNavDestination.menu);
  }

  /// Pestañas ya construidas. Se reutiliza la misma instancia de widget entre
  /// reconstrucciones para que cambiar de pestaña no vuelva a construir las
  /// demás (Flutter salta los widgets idénticos). Se vacía cuando cambia algo
  /// que ellas usan: el perfil (burbuja) o las peticiones desde Inicio.
  final Map<int, Widget> _tabCache = {};

  void _invalidateTabs() => _tabCache.clear();

  Widget _buildTab(int index) {
    if (!_visited[index]) return const SizedBox.shrink();
    // Pedidos depende de si es la pestaña activa (recarga al entrar).
    if (index == BottomNavDestination.orders) return _createTab(index);
    return _tabCache.putIfAbsent(index, () => _createTab(index));
  }

  Widget _createTab(int index) {
    final bubble = ProfileBubble(initial: _initial, onTap: _openProfile);
    switch (index) {
      case BottomNavDestination.home:
        return ChildrenListScreen(
          profileAction: bubble,
          userName: _me?.firstName ?? '',
          onOrderForChild: _orderForChild,
          onOpenMenuDay: _openMenuDay,
          onRechargeChild: _rechargeChild,
          onOpenProducts: _openProducts,
        );
      case BottomNavDestination.menu:
        return ParentMenuTab(
          // Sin key: un pedido de Inicio cambia la vista de la misma pestaña
          // (didUpdateWidget) y conserva el carrito en vez de recrearla.
          request: _menuRequest,
          initialDate: _initialMenuDate,
          initialMode: _initialMenuMode,
          profileAction: bubble,
        );
      case BottomNavDestination.orders:
        return OrdersScreen(
          embedded: true,
          isActive: _index == BottomNavDestination.orders,
          profileAction: bubble,
        );
      default:
        return WalletRechargeScreen(
          key: ValueKey('wallet-$_rechargeRequest'),
          initialSection: _walletSection,
          profileAction: bubble,
        );
    }
  }

  /// Una pestaña oculta del IndexedStack sigue "viva": sin esto sus animaciones
  /// y temporizadores seguirían corriendo aunque nadie la vea.
  Widget _tab(int index) =>
      TickerMode(enabled: index == _index, child: _buildTab(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(_tabCount, _tab),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: _index, onTap: _goTo),
    );
  }
}
