import 'package:delycattessen_flutter/features/menu/utils/cart_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartRules.canRemoveLine', () {
    test('is false below the minimum number of lines', () {
      expect(CartRules.canRemoveLine(0), isFalse);
      expect(
        CartRules.canRemoveLine(CartRules.minLinesForQuickRemove - 1),
        isFalse,
      );
    });

    test('is true from the minimum number of lines', () {
      expect(CartRules.canRemoveLine(CartRules.minLinesForQuickRemove), isTrue);
      expect(
        CartRules.canRemoveLine(CartRules.minLinesForQuickRemove + 3),
        isTrue,
      );
    });
  });
}
