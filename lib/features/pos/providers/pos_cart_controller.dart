import 'package:flutter/foundation.dart';

import '../../menu/models/menu_models.dart';
import '../models/sale_models.dart';

/// Line of the POS cart: a loose product at its (discounted) price or a
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

  /// Products the POS can sell; drops cart lines of products that are gone.
  void setCatalog(List<MenuItem> items) {
    _products = {for (final item in items) item.id: item};
    _productQuantities.removeWhere((id, _) => !_products.containsKey(id));
    notifyListeners();
  }

  bool get isEmpty => _productQuantities.isEmpty && _comboQuantities.isEmpty;
  int get lineCount => _productQuantities.length + _comboQuantities.length;

  /// Units in the cart, counting each combo once.
  int get itemCount => [
    ..._productQuantities.values,
    ..._comboQuantities.values,
  ].fold(0, (sum, quantity) => sum + quantity);

  int quantityOfProduct(int productId) => _productQuantities[productId] ?? 0;

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
    final short = _shortProduct({item.id: quantity});
    if (short != null) return short;
    _productQuantities[item.id] = quantityOfProduct(item.id) + quantity;
    notifyListeners();
    return null;
  }

  String? addCombo(Combo combo, [int quantity = 1]) {
    final short = _shortProduct(_unitsOfCombo(combo, quantity), combo: combo);
    if (short != null) return short;
    _combos[combo.id] = combo;
    _comboQuantities[combo.id] = (_comboQuantities[combo.id] ?? 0) + quantity;
    notifyListeners();
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

  /// Units of [productId] the cart already uses, loose and inside combos.
  int _unitsInCart(int productId) {
    var units = quantityOfProduct(productId);
    for (final entry in _comboQuantities.entries) {
      units += _unitsOfCombo(_combos[entry.key]!, entry.value)[productId] ?? 0;
    }
    return units;
  }

  /// First product that would exceed its stock after adding [extraUnits]
  /// (productId -> units). A product the POS does not sell (e.g. a combo
  /// product without stock) counts as out; [combo] names it.
  String? _shortProduct(Map<int, int> extraUnits, {Combo? combo}) {
    for (final entry in extraUnits.entries) {
      final product = _products[entry.key];
      if (product == null) return _nameInCombo(combo, entry.key);
      final needed = _unitsInCart(entry.key) + entry.value;
      if (product.stock > 0 && needed > product.stock) return product.name;
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
