import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';

/// Destinos de la barra inferior. Orden fijo: el índice es el de la pestaña
/// en el ParentShell, así agregar o mover un destino se hace en un solo lugar.
class BottomNavDestination {
  static const int home = 0;
  static const int menu = 1;
  static const int orders = 2;
  static const int wallet = 3;
}

/// Barra de navegación inferior con etiquetas. Es solo presentación: quien la
/// aloja (ParentShell) decide qué pestaña mostrar al tocar un destino. La barra
/// ocupa todo el ancho; los ítems se centran dentro del ancho de contenido.
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // 18 abajo como el diseño (barra de 88 en total); la zona de gestos
          // del sistema se suma por el SafeArea.
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          // Center + ConstrainedBox (no ResponsiveCenter): en la ranura de la
          // barra inferior el alto es el de toda la pantalla y no debe llenarse.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.pageMaxWidth,
                minHeight: 62,
              ),
              // Sin alto fijo: la barra crece con la letra del sistema.
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
                    _buildNavItem(
                      1,
                      Icons.restaurant_menu_outlined,
                      Icons.restaurant_menu,
                      'Menú',
                    ),
                    _buildNavItem(
                      2,
                      Icons.receipt_long_outlined,
                      Icons.receipt_long,
                      'Pedidos',
                    ),
                    _buildNavItem(
                      3,
                      Icons.account_balance_wallet_outlined,
                      Icons.account_balance_wallet,
                      'Billetera',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppColors.secondary500 : AppColors.ink900,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.ink900,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
