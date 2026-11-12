import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/allergen_section_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/child_ordering_row.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_link_section.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_info_grid.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_scaffold.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_tag.dart';
import 'package:delycattessen_flutter/features/menu/widgets/other_combos_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/detail_test_support.dart';

const _longName = 'Combo almuerzo familiar con bebida y postre incluidos hoy';

final _combos = [
  for (var i = 1; i <= 3; i++)
    Combo(
      id: i,
      name: '$_longName $i',
      price: 12.5,
      regularPrice: 20,
      endDate: DateTime(2026, 12, 31),
      items: const [
        ComboItem(
          productId: 1,
          name: 'Sánduche de pollo con queso',
          quantity: 2,
        ),
        ComboItem(productId: 2, name: 'Cola personal de vidrio', quantity: 1),
      ],
    ),
];

final _conflict = AllergenAdvisory.of(
  allergens: ['Gluten', 'Lácteos', 'Sulfitos', 'Frutos secos', 'Mariscos'],
  conflicts: ['Gluten', 'Lácteos', 'Frutos secos'],
  audience: const AllergenAudience.named(
    'Pepito Alejandro Pérez Villavicencio',
  ),
);

final _safe = AllergenAdvisory.of(
  allergens: ['Gluten', 'Lácteos'],
  audience: const AllergenAudience.named(
    'Pepito Alejandro Pérez Villavicencio',
  ),
);

void main() {
  // An overflow ("RenderFlex overflowed") is a framework exception, so a clean
  // takeException means nothing was cut or overflowed.
  for (final entry in detailSizes.entries) {
    for (final scale in detailTextScales) {
      final where = '${entry.key}, text x$scale';

      testWidgets('page pieces with long texts: $where', (tester) async {
        await pumpDetailPiece(
          tester,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DetailInfoGrid(
                tiles: [
                  DetailInfoTile(
                    icon: Icons.event,
                    label: 'Se sirve el',
                    value: 'Miércoles 30 septiembre',
                  ),
                  DetailInfoTile(
                    icon: Icons.schedule,
                    label: 'Pide hasta',
                    value: 'Martes 29 septiembre',
                    tone: DetailInfoTone.amber,
                  ),
                  DetailInfoTile(
                    icon: Icons.storefront,
                    label: 'Se compra',
                    value: 'En caja',
                    tone: DetailInfoTone.blue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ChildOrderingRow(
                name: 'Pepito Alejandro Pérez Villavicencio',
                onChange: () {},
              ),
              const SizedBox(height: 14),
              AllergenSectionCard(
                advisory: _conflict,
                subject: AllergenSubject.combo,
              ),
              const SizedBox(height: 14),
              AllergenSectionCard(
                advisory: _safe,
                subject: AllergenSubject.product,
              ),
              const SizedBox(height: 14),
              ComboLinkSection(combos: _combos, onComboTap: (_) {}),
              const SizedBox(height: 14),
              OtherCombosGrid(combos: _combos, onComboTap: (_) {}),
            ],
          ),
          size: entry.value,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('blocked bar with a long name: $where', (tester) async {
        await pumpDetailPiece(
          tester,
          Align(
            alignment: Alignment.bottomCenter,
            child: BlockedPurchaseBar(
              label: 'No disponible para Pepito Alejandro Pérez Villavicencio',
              secondaryLabel: 'Pedir para otro hijo',
              onSecondary: () {},
            ),
          ),
          size: entry.value,
          textScale: scale,
          scroll: false,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('scaffold with a long tag and a blocked bar: $where', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: page!,
            ),
            home: DetailScaffold(
              tag: const DetailTag.neutral(
                'Categoría con un nombre larguísimo de producto',
              ),
              bottomBar: BlockedPurchaseBar(
                label: 'No disponible para Pepito',
                secondaryLabel: 'Pedir para otro hijo',
                onSecondary: () {},
              ),
              children: [
                Text(_longName * 3),
                AllergenSectionCard(
                  advisory: _conflict,
                  subject: AllergenSubject.dish,
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
