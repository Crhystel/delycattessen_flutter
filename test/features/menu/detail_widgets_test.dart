import 'package:cached_network_image/cached_network_image.dart';
import 'package:delycattessen_flutter/core/widgets/app_network_image.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/allergen_section_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/child_ordering_row.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_link_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_link_section.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_chip.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_info_grid.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_scaffold.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_tag.dart';
import 'package:delycattessen_flutter/features/menu/widgets/other_combos_grid.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/detail_test_support.dart';

const _pepito = AllergenAudience.named('Pepito');

Combo _combo(
  int id,
  String name,
  double price, {
  double regular = 0,
  List<ComboItem> items = const [],
}) => Combo(
  id: id,
  name: name,
  price: price,
  regularPrice: regular,
  endDate: DateTime(2026, 12, 31),
  items: items,
);

Finder _chips() => find.byType(DetailChip);

void main() {
  group('AllergenSectionCard', () {
    Future<void> pump(WidgetTester tester, AllergenAdvisory advisory) =>
        pumpDetailPiece(
          tester,
          AllergenSectionCard(
            advisory: advisory,
            subject: AllergenSubject.dish,
          ),
        );

    testWidgets('conflict: chips and the red box with the warning', (
      tester,
    ) async {
      await pump(
        tester,
        AllergenAdvisory.of(
          allergens: ['Sulfitos', 'Gluten'],
          conflicts: ['Sulfitos'],
          audience: _pepito,
        ),
      );
      expect(find.text('Alérgenos'), findsOneWidget);
      expect(_chips(), findsNWidgets(2));
      expect(find.text('Contiene sulfitos'), findsOneWidget);
      expect(
        find.text(
          'Pepito tiene registrada esta alergia, por eso este plato no se le '
          'puede vender.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('no conflict: the green box with the check', (tester) async {
      await pump(
        tester,
        AllergenAdvisory.of(allergens: ['Gluten'], audience: _pepito),
      );
      expect(
        find.text('Pepito no tiene registrada esta alergia.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('self audience words it in the second person', (tester) async {
      await pump(
        tester,
        AllergenAdvisory.of(
          allergens: ['Gluten', 'Lácteos'],
          audience: AllergenAudience.self,
        ),
      );
      expect(
        find.text('No tienes registradas estas alergias.'),
        findsOneWidget,
      );
    });

    testWidgets('an item without allergens says so and has no boxes', (
      tester,
    ) async {
      await pump(tester, const AllergenAdvisory(audience: _pepito));
      expect(find.text('Alérgenos'), findsOneWidget);
      expect(find.text('Sin alérgenos registrados'), findsOneWidget);
      expect(_chips(), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('unknown audience: only the chips, no boxes', (tester) async {
      await pump(tester, AllergenAdvisory.of(allergens: ['Gluten', 'Lácteos']));
      expect(_chips(), findsNWidgets(2));
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });

  group('BlockedPurchaseBar', () {
    testWidgets('shows the reason on a disabled button', (tester) async {
      await pumpDetailPiece(
        tester,
        const BlockedPurchaseBar(label: 'No disponible para Pepito'),
        scroll: false,
      );
      expect(find.text('No disponible para Pepito'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('the optional link calls onSecondary', (tester) async {
      var taps = 0;
      await pumpDetailPiece(
        tester,
        BlockedPurchaseBar(
          label: 'No disponible para Pepito',
          secondaryLabel: 'Pedir para otro hijo',
          onSecondary: () => taps++,
        ),
        scroll: false,
      );
      await tester.tap(find.text('Pedir para otro hijo'));
      expect(taps, 1);
    });

    testWidgets('the disabled button does nothing when tapped', (tester) async {
      await pumpDetailPiece(
        tester,
        const BlockedPurchaseBar(label: 'No disponible para ti'),
        scroll: false,
      );
      await tester.tap(find.text('No disponible para ti'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shares its shell with the quantity bar', (tester) async {
      await pumpDetailPiece(
        tester,
        QuantityAddBar(unitPrice: 2, onAdd: (_) {}),
        scroll: false,
      );
      expect(find.text('Añadir \$2.00'), findsOneWidget);
    });
  });

  group('DetailInfoGrid', () {
    testWidgets('shows label and value of each tile', (tester) async {
      await pumpDetailPiece(
        tester,
        const DetailInfoGrid(
          tiles: [
            DetailInfoTile(
              icon: Icons.event,
              label: 'Se sirve el',
              value: 'Martes 10 nov',
            ),
            DetailInfoTile(
              icon: Icons.schedule,
              label: 'Pide hasta',
              value: 'Lun 9 nov',
              tone: DetailInfoTone.amber,
            ),
          ],
        ),
      );
      expect(find.text('Se sirve el'), findsOneWidget);
      expect(find.text('Martes 10 nov'), findsOneWidget);
      expect(find.text('Pide hasta'), findsOneWidget);
      expect(find.text('Lun 9 nov'), findsOneWidget);
    });

    testWidgets('tiles of a row have the same height', (tester) async {
      await pumpDetailPiece(
        tester,
        const DetailInfoGrid(
          tiles: [
            DetailInfoTile(icon: Icons.event, label: 'A', value: 'corto'),
            DetailInfoTile(
              icon: Icons.event,
              label: 'B',
              value:
                  'Un valor muy largo que ocupa varias líneas dentro de la '
                  'tarjeta de información',
            ),
          ],
        ),
        size: const Size(320, 568),
      );
      final tiles = find.byType(DetailInfoTile);
      expect(
        tester.getSize(tiles.at(0)).height,
        tester.getSize(tiles.at(1)).height,
      );
    });

    testWidgets('an odd number of tiles leaves the last column empty', (
      tester,
    ) async {
      await pumpDetailPiece(
        tester,
        const DetailInfoGrid(
          tiles: [
            DetailInfoTile(icon: Icons.event, label: 'A', value: '1'),
            DetailInfoTile(icon: Icons.event, label: 'B', value: '2'),
            DetailInfoTile(icon: Icons.event, label: 'C', value: '3'),
          ],
        ),
      );
      expect(find.byType(DetailInfoTile), findsNWidgets(3));
      expect(
        tester.getSize(find.byType(DetailInfoTile).at(2)).width,
        tester.getSize(find.byType(DetailInfoTile).at(0)).width,
      );
    });
  });

  group('ChildOrderingRow', () {
    testWidgets('shows the initials, the name and "Cambiar"', (tester) async {
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'Pepito Pérez', onChange: () {}),
      );
      expect(find.text('Pidiendo para'), findsOneWidget);
      expect(find.text('PP'), findsOneWidget);
      expect(find.text('Pepito Pérez'), findsOneWidget);
      expect(find.text('Cambiar'), findsOneWidget);
    });

    testWidgets('tapping the row calls onChange', (tester) async {
      var taps = 0;
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'Pepito Pérez', onChange: () => taps++),
      );
      await tester.tap(find.byType(ChildOrderingRow));
      expect(taps, 1);
    });

    testWidgets('without a photo it shows the initials and no image', (
      tester,
    ) async {
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'Pepito Pérez', onChange: () {}),
      );

      expect(find.text('PP'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('with a photo it loads that url and keeps the initials as '
        'fallback while it loads', (tester) async {
      const url = 'https://example.test/pepito.jpg';
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'Pepito Pérez', photoUrl: url, onChange: () {}),
      );

      final photo = tester.widget<AppNetworkImage>(
        find.byType(AppNetworkImage),
      );
      expect(photo.url, url);
      expect(photo.width, 44);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('PP'), findsOneWidget);
    });

    testWidgets('an empty photo url behaves like no photo', (tester) async {
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'Pepito Pérez', photoUrl: '', onChange: () {}),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('PP'), findsOneWidget);
    });

    testWidgets('keeps its accessible label with a photo', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(
          name: 'Pepito Pérez',
          photoUrl: 'https://example.test/pepito.jpg',
          onChange: () {},
        ),
      );

      expect(
        find.bySemanticsLabel('Cambiar hijo. Pidiendo para Pepito Pérez'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a single name gives a single initial', (tester) async {
      await pumpDetailPiece(
        tester,
        ChildOrderingRow(name: 'ana', onChange: () {}),
      );
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('OtherCombosGrid', () {
    testWidgets('shows name and price of every combo', (tester) async {
      await pumpDetailPiece(
        tester,
        OtherCombosGrid(
          combos: [
            _combo(1, 'Dulce tarde', 2.5),
            _combo(2, 'Recreo frío', 1.8),
            _combo(3, 'Almuerzo', 4),
          ],
          onComboTap: (_) {},
        ),
      );
      expect(find.text('Otros combos'), findsOneWidget);
      expect(find.text('Dulce tarde'), findsOneWidget);
      expect(find.text('\$2.50'), findsOneWidget);
      expect(find.text('Recreo frío'), findsOneWidget);
      expect(find.text('\$1.80'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
    });

    testWidgets('tapping a combo reports it', (tester) async {
      final tapped = <int>[];
      await pumpDetailPiece(
        tester,
        OtherCombosGrid(
          combos: [_combo(1, 'Dulce tarde', 2.5), _combo(2, 'Recreo', 1.8)],
          onComboTap: (c) => tapped.add(c.id),
        ),
      );
      await tester.tap(find.text('Recreo'));
      expect(tapped, [2]);
    });

    testWidgets('draws nothing without combos', (tester) async {
      await pumpDetailPiece(
        tester,
        OtherCombosGrid(combos: const [], onComboTap: (_) {}),
      );
      expect(find.text('Otros combos'), findsNothing);
    });
  });

  group('ComboLinkCard', () {
    const items = [
      ComboItem(productId: 1, name: 'Crepes', quantity: 1),
      ComboItem(productId: 2, name: 'Tostada', quantity: 1),
    ];

    testWidgets('shows name, summary, price and saving', (tester) async {
      await pumpDetailPiece(
        tester,
        ComboLinkCard(
          combo: _combo(1, 'Promo barata', 2, regular: 7, items: items),
          onTap: () {},
        ),
      );
      expect(find.text('Promo barata'), findsOneWidget);
      expect(find.text('Crepes + Tostada'), findsOneWidget);
      expect(find.text('\$2.00'), findsOneWidget);
      expect(find.text('Ahorras \$5.00'), findsOneWidget);
    });

    testWidgets('without savings it shows no "Ahorras"', (tester) async {
      await pumpDetailPiece(
        tester,
        ComboLinkCard(
          combo: _combo(1, 'Promo', 3, regular: 3, items: items),
          onTap: () {},
        ),
      );
      expect(find.textContaining('Ahorras'), findsNothing);
    });

    testWidgets('tapping it calls onTap', (tester) async {
      var taps = 0;
      await pumpDetailPiece(
        tester,
        ComboLinkCard(
          combo: _combo(1, 'Promo barata', 2, items: items),
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.byType(ComboLinkCard));
      expect(taps, 1);
    });

    test('summary marks quantities above one', () {
      final combo = _combo(
        1,
        'Promo',
        2,
        items: const [
          ComboItem(productId: 1, name: 'Sánduche', quantity: 1),
          ComboItem(productId: 2, name: 'Cola', quantity: 2),
        ],
      );
      expect(ComboLinkCard.summaryOf(combo), 'Sánduche + Cola ×2');
    });

    testWidgets('the section lists every combo and hides when empty', (
      tester,
    ) async {
      await pumpDetailPiece(
        tester,
        ComboLinkSection(
          combos: [_combo(1, 'Uno', 2), _combo(2, 'Dos', 3)],
          onComboTap: (_) {},
        ),
      );
      expect(find.text('También en combo'), findsOneWidget);
      expect(find.byType(ComboLinkCard), findsNWidgets(2));

      await pumpDetailPiece(
        tester,
        ComboLinkSection(combos: const [], onComboTap: (_) {}),
      );
      expect(find.text('También en combo'), findsNothing);
    });
  });

  group('DetailScaffold', () {
    Future<void> pump(WidgetTester tester, {Widget? bottomBar}) async {
      tester.view.physicalSize = const Size(411, 891);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScaffold(
            tag: const DetailTag.neutral('Menú del mes'),
            bottomBar: bottomBar,
            children: const [Text('uno'), Text('dos')],
          ),
        ),
      );
    }

    testWidgets('shows the tag, the content and the back button', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Menú del mes'), findsOneWidget);
      expect(find.text('uno'), findsOneWidget);
      expect(find.text('dos'), findsOneWidget);
      expect(find.byTooltip('Volver'), findsOneWidget);
    });

    testWidgets('the combo tag reads COMBO', (tester) async {
      tester.view.physicalSize = const Size(411, 891);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailScaffold(tag: DetailTag.combo(), children: []),
        ),
      );
      expect(find.text('COMBO'), findsOneWidget);
    });

    testWidgets('the bottom bar stays below the scrolling content', (
      tester,
    ) async {
      await pump(tester, bottomBar: const Text('barra'));
      final bar = tester.getTopLeft(find.text('barra')).dy;
      expect(bar, greaterThan(tester.getTopLeft(find.text('dos')).dy));
      expect(bar, greaterThan(891 - 150));
    });

    testWidgets('back pops the route', (tester) async {
      tester.view.physicalSize = const Size(411, 891);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DetailScaffold(
                    tag: DetailTag.combo(),
                    children: [Text('detalle')],
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('detalle'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('detalle'), findsNothing);
    });
  });
}
