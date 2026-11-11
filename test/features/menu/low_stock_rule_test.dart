import 'package:delycattessen_flutter/features/menu/utils/low_stock_rule.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_stock_badges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LowStockRule', () {
    test('warns from 1 up to the threshold, never at zero or unknown', () {
      expect(LowStockRule.isLow(null), isFalse);
      expect(LowStockRule.isLow(0), isFalse);
      expect(LowStockRule.isLow(1), isTrue);
      expect(LowStockRule.isLow(LowStockRule.threshold), isTrue);
      expect(LowStockRule.isLow(LowStockRule.threshold + 1), isFalse);
    });

    test('the last unit is exactly one', () {
      expect(LowStockRule.isLast(1), isTrue);
      expect(LowStockRule.isLast(2), isFalse);
      expect(LowStockRule.isLast(null), isFalse);
    });
  });

  group('CatalogStockBadges', () {
    test('low says "Quedan N", "Última unidad" or nothing', () {
      expect(CatalogStockBadges.low(3)!.label, 'Quedan 3');
      expect(CatalogStockBadges.low(1)!.label, 'Última unidad');
      expect(CatalogStockBadges.low(LowStockRule.threshold + 1), isNull);
      expect(CatalogStockBadges.low(0), isNull);
      expect(CatalogStockBadges.low(null), isNull);
    });

    test('exact shows the number, also zero, and nothing when unknown', () {
      expect(CatalogStockBadges.exact(12)!.label, 'Stock: 12');
      expect(CatalogStockBadges.exact(0)!.label, 'Stock: 0');
      expect(CatalogStockBadges.exact(null), isNull);
    });
  });
}
