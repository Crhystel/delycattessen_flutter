import 'package:delycattessen_flutter/features/menu/utils/cart_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartRules.total', () {
    const prices = {1: 2.5, 2: 10.0};

    test('is zero for an empty cart', () {
      expect(CartRules.total({}, (id) => prices[id]), 0);
    });

    test('adds price times quantity for every line', () {
      expect(CartRules.total({1: 2, 2: 1}, (id) => prices[id]), 15.0);
    });

    test('ignores lines whose price is no longer available', () {
      expect(CartRules.total({1: 2, 99: 5}, (id) => prices[id]), 5.0);
    });
  });

  group('CartRules.itemCount', () {
    test('sums the quantity of every line', () {
      expect(CartRules.itemCount({}), 0);
      expect(CartRules.itemCount({1: 2, 2: 3}), 5);
    });
  });

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
