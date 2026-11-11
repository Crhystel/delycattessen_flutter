import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/services/product_catalog_source.dart';

MenuItem product(
  int id,
  String name,
  double price, {
  double? originalPrice,
  int? discount,
  String category = 'Snacks',
}) => MenuItem(
  id: id,
  name: name,
  description: '',
  price: price,
  category: category,
  ingredients: const [],
  allergens: const [],
  stock: 10,
  originalPrice: originalPrice,
  discountPercentage: discount,
);

Combo lunchCombo({
  List<ComboItem>? items,
  String name = 'Combo almuerzo',
  int? availableQuantity,
}) => Combo(
  id: 10,
  name: name,
  price: 3.50,
  regularPrice: 4.00,
  endDate: DateTime(2026, 12, 31),
  availableQuantity: availableQuantity,
  items:
      items ??
      const [
        ComboItem(productId: 1, name: 'Sánduche', quantity: 1),
        ComboItem(productId: 2, name: 'Cola', quantity: 2),
      ],
);

Promotion colaPromotion() => Promotion(
  id: 20,
  discountPercentage: 20,
  endDate: DateTime(2026, 12, 31),
  productNames: const ['Cola'],
  productIds: const [2],
);

/// Catalog source with fixed data, for the catalog screen.
class FakeCatalogSource implements ProductCatalogSource {
  FakeCatalogSource({required this.items, this.offers = CatalogOffers.empty});

  final List<MenuItem> items;
  final CatalogOffers offers;

  @override
  String get id => 'fake';

  @override
  String get allergyOwnerLabel => 'tus alergias';

  @override
  Future<List<MenuItem>> loadItems() async => items;

  @override
  Future<CatalogOffers> loadOffers() async => offers;

  @override
  Future<Set<int>> loadAllergenIds() async => const {};
}
