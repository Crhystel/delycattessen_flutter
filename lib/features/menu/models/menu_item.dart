enum MenuCategory { general, snacks, bebidas }

class MenuItem {
  final String name;
  final String description;
  final double price;
  final String emoji; // placeholder visual mientras no hay imágenes reales
  final MenuCategory category;

  const MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
  });
}

/// Datos inventados solo para simular la vista — el catálogo real
const mockMenuItems = [
  MenuItem(
    name: 'Hamburguesa',
    description: 'Carne a la parrilla, Queso, Lechuga, Tomate',
    price: 3.50,
    emoji: '🍔',
    category: MenuCategory.general,
  ),
  MenuItem(
    name: 'Fritada',
    description: 'Fritada, Mote, Aguacate, Maduro, Mote',
    price: 2.50,
    emoji: '🍖',
    category: MenuCategory.general,
  ),
  MenuItem(
    name: 'Pop Tarts Fresa',
    description: 'Fresa, Leche, Mantequilla, Harina, Miel',
    price: 0.75,
    emoji: '🥧',
    category: MenuCategory.snacks,
  ),
  MenuItem(
    name: 'Barra de chocolate',
    description: 'Fresa, Leche, Chocolate, Harina, Miel',
    price: 0.75,
    emoji: '🍫',
    category: MenuCategory.snacks,
  ),
  MenuItem(
    name: 'Milkshake Vainilla',
    description: 'Leche, Vainilla, Crema, Cereza',
    price: 1.00,
    emoji: '🥤',
    category: MenuCategory.bebidas,
  ),
];
