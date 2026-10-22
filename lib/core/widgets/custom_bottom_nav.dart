import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Destinos de la barra inferior. Orden fijo: el índice es el de la pestaña
/// en el ParentShell, así agregar o mover un destino se hace en un solo lugar.
class BottomNavDestination {
  static const int home = 0;
  static const int menu = 1;
  static const int orders = 2;
  static const int wallet = 3;
}

/// Barra de navegación inferior con etiquetas. Es solo presentación: quien la
/// aloja (ParentShell) decide qué pestaña mostrar al tocar un destino.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brand500,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Inicio'),
              _buildNavItem(1, Icons.restaurant_menu, 'Menú'),
              _buildNavItem(2, Icons.receipt_long, 'Pedidos'),
              _buildNavItem(3, Icons.account_balance_wallet, 'Billetera'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.navActiveCircle
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
