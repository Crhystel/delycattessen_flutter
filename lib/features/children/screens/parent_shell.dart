import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../menu/screens/menu_screen.dart';
import '../../menu/screens/orders_screen.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../providers/children_provider.dart';
import 'children_list_screen.dart';

/// Contenedor de las 4 pestañas del padre (Inicio, Menú, Pedidos, Billetera).
/// Cambiar de pestaña NO apila pantallas: cada una conserva su estado y se
/// construye solo la primera vez que se visita (carga perezosa).
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> with NotificationMixin {
  static const int _tabCount = 4;

  int _index = BottomNavDestination.home;
  final List<bool> _visited = List<bool>.filled(_tabCount, false)..[0] = true;

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
    _goTo(BottomNavDestination.menu);
  }

  Widget _buildTab(int index) {
    if (!_visited[index]) return const SizedBox.shrink();
    switch (index) {
      case BottomNavDestination.home:
        return ChildrenListScreen(onOrderForChild: _orderForChild);
      case BottomNavDestination.menu:
        return const MenuScreen(embedded: true);
      case BottomNavDestination.orders:
        return OrdersScreen(
          embedded: true,
          isActive: _index == BottomNavDestination.orders,
        );
      default:
        return const WalletRechargeScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(_tabCount, _buildTab),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: _index, onTap: _goTo),
    );
  }
}
