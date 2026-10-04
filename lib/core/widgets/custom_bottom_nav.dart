import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/menu/screens/menu_screen.dart';
import '../../features/menu/screens/orders_screen.dart';
import '../../features/wallet/screens/wallet_recharge_screen.dart';

/// Barra de navegación inferior única para toda la app. Centraliza a dónde
/// lleva cada pestaña (Home/Menú/Billetera/Pedidos) para que agregar o
/// cambiar un destino se haga en un solo lugar, no en cada pantalla que
/// la muestra.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  /// Hijo "activo" para las pantallas que lo necesitan (Menú y Pedidos).
  /// Puede quedar en null; cada pantalla destino decide qué hacer sin él.
  final int? studentId;

  final bool Function(int index)? onBeforeNavigate;
  final void Function(int index)? onReturn;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    this.studentId,
    this.onBeforeNavigate,
    this.onReturn,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (onBeforeNavigate != null && !onBeforeNavigate!(index)) return;

    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => MenuScreen(studentId: studentId),
              ),
            )
            .then((_) => onReturn?.call(1));
        break;
      case 2:
        Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (_) => const WalletRechargeScreen()),
            )
            .then((_) => onReturn?.call(2));
        break;
      case 3:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => OrdersScreen(studentId: studentId),
              ),
            )
            .then((_) => onReturn?.call(3));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brand500,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context: context, index: 0, icon: Icons.home),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.restaurant_menu,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.attach_money,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.receipt_long,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => _navigate(context, index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand700 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
