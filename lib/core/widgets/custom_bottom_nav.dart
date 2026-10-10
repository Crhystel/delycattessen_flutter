import 'package:flutter/material.dart';

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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menú',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Pedidos',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Billetera',
        ),
      ],
    );
  }
}
