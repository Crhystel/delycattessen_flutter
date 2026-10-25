import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/providers/pos_cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem product(int id, String name, double price, {int stock = 5}) =>
    MenuItem(
      id: id,
      name: name,
      description: '',
      price: price,
      category: '',
      ingredients: const [],
      allergens: const [],
      stock: stock,
    );

void main() {
  final sandwich = product(1, 'Sanduche', 2.50, stock: 3);
  final cola = product(2, 'Cola', 1.50);
  final combo = Combo(
    id: 10,
    name: 'Combo almuerzo',
    price: 3.50,
    regularPrice: 4.00,
    endDate: DateTime(2026, 10, 31),
    items: const [
      ComboItem(productId: 1, name: 'Sanduche', quantity: 1),
      ComboItem(productId: 2, name: 'Cola', quantity: 1),
    ],
  );

  late PosCartController cart;

  setUp(() {
    cart = PosCartController()..setCatalog([sandwich, cola]);
  });

  test('a combo is one line at its fixed price next to loose products', () {
    expect(cart.addCombo(combo), isNull);
    expect(cart.addProduct(cola, 2), isNull);

    expect(cart.lineCount, 2);
    expect(cart.itemCount, 3);
    expect(cart.total, closeTo(3.50 + 2 * 1.50, 1e-9));
    final comboLine = cart.lines.firstWhere((line) => line.isCombo);
    expect((comboLine.name, comboLine.unitPrice), ('Combo almuerzo', 3.50));
  });

  test('stock counts the units a product uses inside combos', () {
    expect(cart.addCombo(combo, 2), isNull);
    expect(cart.addProduct(sandwich, 1), isNull);
    expect(cart.addProduct(sandwich, 1), 'Sanduche');
    expect(cart.addCombo(combo), 'Sanduche');
    expect(cart.quantityOfProduct(sandwich.id), 1);
  });

  test('a combo with a product the POS does not sell cannot be added', () {
    cart.setCatalog([cola]);
    expect(cart.addCombo(combo), 'Sanduche');
    expect(cart.isEmpty, isTrue);
  });

  test('changing a line to zero removes it', () {
    cart.addCombo(combo);
    final line = cart.lines.single;
    expect(cart.changeLine(line, 1), isNull);
    expect(cart.lines.single.quantity, 2);
    cart.changeLine(cart.lines.single, -2);
    expect(cart.isEmpty, isTrue);
  });

  test('builds the sale request with products and combos', () {
    cart
      ..addProduct(cola, 1)
      ..addCombo(combo);
    final json = cart.toSaleRequest(PaymentMethod.cash, userId: 7).toJson();
    expect(json['items'], [
      {'menu_item_id': 2, 'quantity': 1},
    ]);
    expect(json['combos'], [
      {'combo_id': 10, 'quantity': 1},
    ]);
    expect(json['user_id'], 7);
  });
}
