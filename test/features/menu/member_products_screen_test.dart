import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/member_products_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/category_filter_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _items = [
  product(1, 'Sánduche', 2.50),
  product(
    2,
    'Cola',
    1.60,
    originalPrice: 2.00,
    discount: 20,
    category: 'Bebidas',
  ),
];

Future<void> _pump(WidgetTester tester, {CatalogOffers? offers}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MemberProductsScreen(
        source: FakeCatalogSource(
          items: _items,
          offers: offers ?? CatalogOffers.empty,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows the combo carousel, a back button and no add button', (
    tester,
  ) async {
    await _pump(
      tester,
      offers: CatalogOffers(combos: [lunchCombo()], promotions: []),
    );

    expect(find.byType(ComboCarousel), findsOneWidget);
    expect(find.text('Combos de hoy'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.text('Agregar'), findsNothing);
    expect(find.textContaining('Agregar'), findsNothing);
    expect(tester.takeException(), isNull);

    // The carousel advances by itself with a timer: unmount to stop it.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('categories are even circles, like the parent catalog', (
    tester,
  ) async {
    await _pump(tester);

    final bar = tester.widget<CategoryFilterBar>(
      find.byType(CategoryFilterBar),
    );
    expect(bar.style, CategoryFilterStyle.evenCircles);
    expect(find.byType(ComboCarousel), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
