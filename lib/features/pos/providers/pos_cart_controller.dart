import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../menu/models/menu_models.dart';
import '../models/sale_models.dart';

/// Line of the POS cart: a loose product at its price or a
/// combo at its fixed price.
class PosCartLine {
  final int id;
  final String name;
  final double unitPrice;
  final int quantity;
  final bool isCombo;

  const PosCartLine({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.isCombo = false,
  });
}

/// Cart shared by the POS menu and checkout. Loose products and combos are
/// separate lines, but stock is checked on the units a product uses in total
/// (loose plus inside combos). Methods that add units return the name of the
/// product that would run out, or null when the change was applied.
class PosCartController extends ChangeNotifier {
  Map<int, MenuItem> _products = const {};
  final Map<int, int> _productQuantities = {}; // keeps selection order
  final Map<int, Combo> _combos = {};
  final Map<int, int> _comboQuantities = {};

  /// Products the POS can sell (and, when given, the combos on sale) with the
  /// server's current stock. The cart is rebuilt over that stock: lines that
  /// no longer fit (sold out, hidden or no longer offered) are reduced or
  /// removed. Returns the names of the lines that changed, so the cashier can
  /// be told why.
  List<String> setCatalog(List<MenuItem> items, {List<Combo>? combos}) {
    final previousProducts = _products;
    _products = {for (final item in items) item.id: item};
    final fresh = combos == null ? null : {for (final c in combos) c.id: c};

    final productQuantities = Map.of(_productQuantities);
    final comboQuantities = Map.of(_comboQuantities);
    _productQuantities.clear();
    _comboQuantities.clear();

    final adjusted = <String>[];
    for (final entry in productQuantities.entries) {
      final item = _products[entry.key];
      final added = item == null
          ? 0
          : _addUpTo(entry.value, () => _tryAddProduct(item, 1));
      if (added < entry.value) {
        adjusted.add(
          item?.name ?? previousProducts[entry.key]?.name ?? 'Producto',
        );
      }
    }
    for (final entry in comboQuantities.entries) {
      final combo = fresh == null ? _combos[entry.key] : fresh[entry.key];
      final added = combo == null
          ? 0
          : _addUpTo(entry.value, () => _tryAddCombo(combo, 1));
      if (added < entry.value) adjusted.add(_combos[entry.key]!.name);
    }
    notifyListeners();
    return adjusted;
  }

  /// Calls [addOne] up to [quantity] times while it succeeds; returns how many.
  static int _addUpTo(int quantity, String? Function() addOne) {
    var added = 0;
    while (added < quantity && addOne() == null) {
      added++;
    }
    return added;
  }

  bool get isEmpty => _productQuantities.isEmpty && _comboQuantities.isEmpty;
  int get lineCount => _productQuantities.length + _comboQuantities.length;

  /// Units in the cart, counting each combo once.
  int get itemCount => [
    ..._productQuantities.values,
    ..._comboQuantities.values,
  ].fold(0, (sum, quantity) => sum + quantity);

  int quantityOfProduct(int productId) => _productQuantities[productId] ?? 0;

  /// Units of a combo in the cart (each one counts as a single line unit).
  int quantityOfCombo(int comboId) => _comboQuantities[comboId] ?? 0;

  List<PosCartLine> get lines => [
    for (final entry in _productQuantities.entries)
      PosCartLine(
        id: entry.key,
        name: _products[entry.key]!.name,
        unitPrice: _products[entry.key]!.price,
        quantity: entry.value,
      ),
    for (final entry in _comboQuantities.entries)
      PosCartLine(
        id: entry.key,
        name: _combos[entry.key]!.name,
        unitPrice: _combos[entry.key]!.price,
        quantity: entry.value,
        isCombo: true,
      ),
  ];

  double get total =>
      lines.fold(0.0, (sum, line) => sum + line.unitPrice * line.quantity);

  String? addProduct(MenuItem item, int quantity) {
    final short = _tryAddProduct(item, quantity);
    if (short == null) notifyListeners();
    return short;
  }

  String? _tryAddProduct(MenuItem item, int quantity) {
    final short = _shortProduct({item.id: quantity});
    if (short != null) return short;
    _productQuantities[item.id] = quantityOfProduct(item.id) + quantity;
    return null;
  }

  /// A combo is limited by its own [Combo.availableQuantity] (counting the
  /// units already in the cart) and by the stock of each of its products.
  /// Returns the name of what would run out.
  String? addCombo(Combo combo, [int quantity = 1]) {
    final short = _tryAddCombo(combo, quantity);
    if (short == null) notifyListeners();
    return short;
  }

  String? _tryAddCombo(Combo combo, int quantity) {
    final limit = combo.availableQuantity;
    if (limit != null && quantityOfCombo(combo.id) + quantity > limit) {
      return combo.name;
    }
    final short = _shortProduct(_unitsOfCombo(combo, quantity), combo: combo);
    if (short != null) return short;
    _combos[combo.id] = combo;
    _comboQuantities[combo.id] = (_comboQuantities[combo.id] ?? 0) + quantity;
    return null;
  }

  /// Adds or removes one unit of [line]; at zero the line is removed.
  String? changeLine(PosCartLine line, int delta) {
    if (line.quantity + delta <= 0) {
      removeLine(line);
      return null;
    }
    if (delta > 0) {
      return line.isCombo
          ? addCombo(_combos[line.id]!, delta)
          : addProduct(_products[line.id]!, delta);
    }
    final quantities = line.isCombo ? _comboQuantities : _productQuantities;
    quantities[line.id] = line.quantity + delta;
    notifyListeners();
    return null;
  }

  void removeLine(PosCartLine line) {
    (line.isCombo ? _comboQuantities : _productQuantities).remove(line.id);
    notifyListeners();
  }

  /// Removes the loose units of a product (its combos stay).
  void removeProduct(int productId) {
    _productQuantities.remove(productId);
    notifyListeners();
  }

  void clear() {
    _productQuantities.clear();
    _comboQuantities.clear();
    notifyListeners();
  }

  /// Payload of `POST /api/pos/sales/`; the server recalculates every price.
  SaleRequest toSaleRequest(PaymentMethod method, {int? userId}) => SaleRequest(
    paymentMethod: method,
    userId: userId,
    items: [
      for (final entry in _productQuantities.entries)
        SaleItemInput(menuItemId: entry.key, quantity: entry.value),
    ],
    combos: [
      for (final entry in _comboQuantities.entries)
        SaleComboInput(comboId: entry.key, quantity: entry.value),
    ],
  );

  Map<int, int> _unitsOfCombo(Combo combo, int quantity) => {
    for (final item in combo.items) item.productId: item.quantity * quantity,
  };

  /// Units of [productId] still addable: its stock minus what the cart already
  /// uses, loose and inside combos. Without stock data it counts as 0, like in
  /// [_shortProduct].
  int remainingOfProduct(int productId) =>
      math.max(0, (_stockOf(productId, null) ?? 0) - _unitsInCart(productId));

  /// Units of [combo] still addable: the scarcest of its products once the
  /// cart's usage is taken out, and its own [Combo.availableQuantity] minus the
  /// units of it already in the cart. Null when nothing limits it.
  int? remainingOfCombo(Combo combo) {
    final limits = <int>[
      for (final item in combo.items)
        math.max(
          0,
          ((_stockOf(item.productId, combo) ?? 0) -
                  _unitsInCart(item.productId)) ~/
              item.quantity,
        ),
    ];
    final available = combo.availableQuantity;
    if (available != null) {
      limits.add(math.max(0, available - quantityOfCombo(combo.id)));
    }
    return limits.isEmpty ? null : limits.reduce(math.min);
  }

  /// Units of [productId] the cart already uses, loose and inside combos.
  int _unitsInCart(int productId) {
    var units = quantityOfProduct(productId);
    for (final entry in _comboQuantities.entries) {
      units += _unitsOfCombo(_combos[entry.key]!, entry.value)[productId] ?? 0;
    }
    return units;
  }

  /// First product that would exceed its stock after adding [extraUnits]
  /// (productId -> units). Stock zero means sold out, as the server treats it.
  /// The stock comes from the POS catalog or, for a combo product that is not
  /// in it, from the combo's own item; with neither, the product counts as out
  /// (the safe choice) and [combo] names it.
  String? _shortProduct(Map<int, int> extraUnits, {Combo? combo}) {
    for (final entry in extraUnits.entries) {
      final stock = _stockOf(entry.key, combo);
      final needed = _unitsInCart(entry.key) + entry.value;
      if (stock == null || needed > stock) {
        return _products[entry.key]?.name ?? _nameInCombo(combo, entry.key);
      }
    }
    return null;
  }

  /// Units in stock of [productId]; null when neither the catalog nor [combo]
  /// say so.
  int? _stockOf(int productId, Combo? combo) {
    final product = _products[productId];
    if (product != null) return product.stock;
    for (final item in combo?.items ?? const <ComboItem>[]) {
      if (item.productId == productId) return item.stock;
    }
    return null;
  }

  String _nameInCombo(Combo? combo, int productId) {
    for (final item in combo?.items ?? const <ComboItem>[]) {
      if (item.productId == productId) return item.name;
    }
    return 'un producto';
  }
}
