import 'dart:ui';

import 'package:delycattessen_flutter/features/pos/utils/pos_home_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PosHomeVariant.fromSize', () {
    test('is a phone below 600 dp on the shorter side', () {
      expect(
        PosHomeVariant.fromSize(const Size(390, 844)),
        PosHomeVariant.phone,
      );
      expect(
        PosHomeVariant.fromSize(const Size(844, 390)),
        PosHomeVariant.phone,
      );
      expect(
        PosHomeVariant.fromSize(const Size(599, 900)),
        PosHomeVariant.phone,
      );
    });

    test('is a landscape tablet when it is wider than tall', () {
      expect(
        PosHomeVariant.fromSize(const Size(1024, 768)),
        PosHomeVariant.tabletLandscape,
      );
    });

    test('is a portrait tablet when it is taller than wide', () {
      expect(
        PosHomeVariant.fromSize(const Size(768, 1024)),
        PosHomeVariant.tabletPortrait,
      );
      expect(PosHomeVariant.fromSize(const Size(600, 600)).isTablet, isTrue);
    });
  });

  group('PosHomeMetrics', () {
    test(
      'a phone stacks the options in rows and keeps the quick sale below',
      () {
        final m = PosHomeMetrics.of(PosHomeVariant.phone);
        expect(m.stacked, isFalse);
        expect(m.quickSaleInline, isFalse);
        expect(m.cardHeight, 132);
        expect(m.buttonHeight, 60);
      },
    );

    test('a landscape tablet puts the quick sale next to its label', () {
      final m = PosHomeMetrics.of(PosHomeVariant.tabletLandscape);
      expect(m.stacked, isTrue);
      expect(m.quickSaleInline, isTrue);
      expect(m.cardHeight, 300);
      expect(m.gridMaxWidth, 760);
    });

    test('a portrait tablet uses taller cards and the quick sale below', () {
      final m = PosHomeMetrics.of(PosHomeVariant.tabletPortrait);
      expect(m.stacked, isTrue);
      expect(m.quickSaleInline, isFalse);
      expect(m.cardHeight, 360);
      expect(m.iconBox, 124);
    });
  });
}
