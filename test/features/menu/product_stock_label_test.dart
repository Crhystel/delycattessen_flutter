import 'package:delycattessen_flutter/features/menu/utils/product_stock_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plenty of stock reads "Disponible"', () {
    expect(productStockLabel(6), 'Disponible');
    expect(productStockLabel(50), 'Disponible');
  });

  test('few units reads "Quedan N" up to the low stock threshold', () {
    expect(productStockLabel(5), 'Quedan 5');
    expect(productStockLabel(1), 'Quedan 1');
  });

  test('zero or less is sold out, exact or not', () {
    expect(productStockLabel(0), 'Agotado');
    expect(productStockLabel(-2), 'Agotado');
    expect(productStockLabel(0, exact: true), 'Agotado');
  });

  test('exact shows the real count', () {
    expect(productStockLabel(12, exact: true), '12 unidades');
    expect(productStockLabel(1, exact: true), '1 unidad');
  });
}
