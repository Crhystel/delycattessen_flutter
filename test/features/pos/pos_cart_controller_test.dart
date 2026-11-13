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

  test('quantityOfCombo counts the units of each combo', () {
    expect(cart.quantityOfCombo(combo.id), 0);

    cart.addCombo(combo);
    cart.addCombo(combo, 2);

    expect(cart.quantityOfCombo(combo.id), 3);
    expect(cart.quantityOfCombo(999), 0);
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

  group('stock of the combo products', () {
    Combo comboOf(
      List<ComboItem> items, {
      int id = 20,
      int? availableQuantity,
    }) => Combo(
      id: id,
      name: 'Combo especial',
      price: 5.00,
      regularPrice: 6.00,
      endDate: DateTime(2026, 10, 31),
      items: items,
      availableQuantity: availableQuantity,
    );

    test(
      'a product outside the visible catalog uses the stock of its item',
      () {
        final hidden = comboOf(const [
          ComboItem(productId: 1, name: 'Sanduche', quantity: 1, stock: 3),
          ComboItem(
            productId: 99,
            name: 'Postre oculto',
            quantity: 2,
            stock: 4,
          ),
        ]);

        expect(cart.addCombo(hidden, 2), isNull);
        expect(cart.quantityOfCombo(hidden.id), 2);
        // 2 combos use 4 units of the hidden product: a third needs 6 > 4.
        expect(cart.addCombo(hidden), 'Postre oculto');
        expect(cart.quantityOfCombo(hidden.id), 2);
      },
    );

    test('a product outside the catalog without stock data is rejected', () {
      final unknown = comboOf(const [
        ComboItem(productId: 99, name: 'Postre oculto', quantity: 1),
      ]);

      expect(cart.addCombo(unknown), 'Postre oculto');
      expect(cart.isEmpty, isTrue);
    });

    test('stock zero means sold out, in the catalog and in the item', () {
      final soldOut = product(3, 'Galleta', 1.0, stock: 0);
      cart.setCatalog([sandwich, cola, soldOut]);

      expect(cart.addProduct(soldOut, 1), 'Galleta');
      expect(cart.isEmpty, isTrue);

      final hiddenZero = comboOf(const [
        ComboItem(productId: 99, name: 'Postre oculto', quantity: 1, stock: 0),
      ]);
      expect(cart.addCombo(hiddenZero), 'Postre oculto');
      expect(cart.isEmpty, isTrue);
    });

    test('the catalog stock wins over the one of the item', () {
      final stale = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 1, stock: 100),
      ]);

      // Cola has 5 in the catalog.
      expect(cart.addCombo(stale, 5), isNull);
      expect(cart.addCombo(stale), 'Cola');
    });

    test('availableQuantity limits the combos, counting those in the cart', () {
      final limited = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 1),
      ], availableQuantity: 2);

      expect(cart.addCombo(limited), isNull);
      expect(cart.addCombo(limited), isNull);
      expect(cart.addCombo(limited), 'Combo especial');
      expect(cart.quantityOfCombo(limited.id), 2);

      // The checkout "+" button goes through the same rule.
      expect(cart.changeLine(cart.lines.single, 1), 'Combo especial');
    });

    test('availableQuantity zero rejects the combo', () {
      final soldOut = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 1),
      ], availableQuantity: 0);

      expect(cart.addCombo(soldOut), 'Combo especial');
      expect(cart.isEmpty, isTrue);
    });

    test('loose product plus combo of the same product count together', () {
      final colaCombo = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 2, stock: 5),
      ], availableQuantity: 10);

      expect(cart.addProduct(cola, 3), isNull); // 3 of 5
      expect(cart.addCombo(colaCombo), isNull); // +2 = 5 of 5
      expect(cart.addCombo(colaCombo), 'Cola');
      expect(cart.addProduct(cola, 1), 'Cola');
      expect(cart.quantityOfProduct(cola.id), 3);
      expect(cart.quantityOfCombo(colaCombo.id), 1);
    });
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

  group('refreshing the stock', () {
    test('a product sold out by a combo is removed from the cart', () {
      cart.addProduct(sandwich, 2);

      // A combo sale elsewhere used the last sandwiches: the catalog no longer
      // lists it (the server hides products without stock).
      final adjusted = cart.setCatalog([cola]);

      expect(adjusted, ['Sanduche']);
      expect(cart.quantityOfProduct(sandwich.id), 0);
      expect(cart.addProduct(sandwich, 1), isNotNull);
    });

    test('a line is reduced to the stock that is left', () {
      cart.addProduct(cola, 4);

      final adjusted = cart.setCatalog([
        sandwich,
        product(2, 'Cola', 1.50, stock: 1),
      ]);

      expect(adjusted, ['Cola']);
      expect(cart.quantityOfProduct(cola.id), 1);
    });

    test('a combo no longer offered is removed', () {
      cart.addCombo(combo);

      final adjusted = cart.setCatalog([sandwich, cola], combos: const []);

      expect(adjusted, ['Combo almuerzo']);
      expect(cart.isEmpty, isTrue);
    });

    test('nothing changes when the stock still covers the cart', () {
      cart
        ..addProduct(cola, 1)
        ..addCombo(combo);

      expect(cart.setCatalog([sandwich, cola], combos: [combo]), isEmpty);
      expect(
        (cart.quantityOfProduct(cola.id), cart.quantityOfCombo(combo.id)),
        (1, 1),
      );
    });
  });

  group('remaining stock', () {
    Combo comboOf(
      List<ComboItem> items, {
      int id = 30,
      int? availableQuantity,
    }) => Combo(
      id: id,
      name: 'Combo $id',
      price: 3,
      regularPrice: 4,
      endDate: DateTime(2026, 10, 31),
      items: items,
      availableQuantity: availableQuantity,
    );

    test('a product with nothing in the cart has all its stock', () {
      expect(cart.remainingOfProduct(sandwich.id), 3);
      expect(cart.remainingOfProduct(cola.id), 5);
    });

    test('loose units take stock away', () {
      cart.addProduct(sandwich, 2);

      expect(cart.remainingOfProduct(sandwich.id), 1);
    });

    test('units inside a combo take stock away from each of its products', () {
      cart.addCombo(combo, 2);

      expect(cart.remainingOfProduct(sandwich.id), 1);
      expect(cart.remainingOfProduct(cola.id), 3);
    });

    test('loose and combo units add up and it never goes below zero', () {
      cart.addCombo(combo, 2);
      cart.addProduct(sandwich, 1);

      expect(cart.remainingOfProduct(sandwich.id), 0);
      expect(cart.remainingOfProduct(sandwich.id), isNonNegative);
    });

    test('removing the line gives the stock back', () {
      cart.addCombo(combo);
      cart.removeLine(cart.lines.single);

      expect(cart.remainingOfProduct(sandwich.id), 3);
      expect(cart.remainingOfProduct(cola.id), 5);
    });

    test('a product without stock data counts as sold out', () {
      expect(cart.remainingOfProduct(999), 0);
    });

    test('a combo has what its scarcest product allows', () {
      // Sanduche 3 and Cola 5, one of each per combo.
      expect(cart.remainingOfCombo(combo), 3);
    });

    test('a combo counts the quantity each unit needs', () {
      final double = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 2),
      ]);

      expect(cart.remainingOfCombo(double), 2); // 5 colas, 2 per combo
    });

    test('a combo shrinks with its own units in the cart', () {
      cart.addCombo(combo, 2);

      expect(cart.remainingOfCombo(combo), 1);
    });

    test('a combo shrinks with the loose products it shares', () {
      cart.addProduct(sandwich, 3);

      expect(cart.remainingOfCombo(combo), 0);
    });

    test('another combo that shares a product takes from this one too', () {
      final other = comboOf(const [
        ComboItem(productId: 1, name: 'Sanduche', quantity: 1),
      ], id: 31);
      cart.addCombo(other, 2);

      expect(cart.remainingOfCombo(combo), 1);
    });

    test('the combo limit of the server caps it', () {
      final capped = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 1),
      ], availableQuantity: 2);

      expect(cart.remainingOfCombo(capped), 2);
      cart.addCombo(capped);
      expect(cart.remainingOfCombo(capped), 1);
    });

    test('a server limit of zero keeps the combo sold out', () {
      final soldOut = comboOf(const [
        ComboItem(productId: 2, name: 'Cola', quantity: 1),
      ], availableQuantity: 0);

      expect(cart.remainingOfCombo(soldOut), 0);
    });

    test('a combo with a product the POS does not sell is sold out', () {
      cart.setCatalog([cola]);

      expect(cart.remainingOfCombo(combo), 0);
    });

    test('the stock of a product outside the catalog comes from the combo', () {
      cart.setCatalog([cola]);
      final withStock = comboOf(const [
        ComboItem(productId: 1, name: 'Sanduche', quantity: 1, stock: 4),
      ]);

      expect(cart.remainingOfCombo(withStock), 4);
    });

    test('a combo without items and without a limit has none', () {
      expect(cart.remainingOfCombo(comboOf(const [])), isNull);
    });
  });
}
