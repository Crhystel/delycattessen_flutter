import 'package:delycattessen_flutter/core/widgets/profile_bubble.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/children/widgets/child_summary_card.dart';
import 'package:delycattessen_flutter/features/children/widgets/custom_bottom_nav.dart';
import 'package:delycattessen_flutter/features/children/widgets/low_balance_alert_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 390x844': Size(390, 844),
  'tablet 768x1024': Size(768, 1024),
};

final _child = Child(
  id: 3,
  firstName: 'Maria Fernanda Alexandra',
  lastName: 'Villavicencio Zambrano',
  institutionName: 'Unidad Educativa Particular Bilingue Martim Cerere Norte',
  balance: 0,
);

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget body,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: body),
        bottomNavigationBar: CustomBottomNav(currentIndex: 1, onTap: (_) {}),
      ),
    ),
  );
}

void main() {
  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('home cards and nav fit: ${entry.key}, text x$scale', (
        tester,
      ) async {
        await _pump(
          tester,
          entry.value,
          scale,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LowBalanceAlertCard(child: _child, onRecharge: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  width: 160,
                  child: ChildSummaryCard(child: _child, onTap: () {}),
                ),
                ProfileBubble(initial: 'c', onTap: () {}),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the alert has one button that recharges that child', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      _sizes['phone 390x844']!,
      1,
      LowBalanceAlertCard(child: _child, onRecharge: () => taps++),
    );
    await tester.pumpAndSettle(); // the first route finishes its transition

    expect(find.text('\$10'), findsNothing);
    expect(find.text('Otro'), findsNothing);
    await tester.tap(find.textContaining('Recargar a'));

    expect(taps, 1);
    expect(
      find.text('Maria Fernanda Alexandra se quedó sin saldo'),
      findsOneWidget,
    );
  });

  testWidgets('the bottom nav reports the tapped destination', (tester) async {
    int? tapped;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 0,
            onTap: (index) => tapped = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pedidos'));

    expect(tapped, BottomNavDestination.orders);
  });

  testWidgets('the profile bubble shows the initial and opens the profile', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileBubble(initial: 'c', onTap: () => opened = true),
        ),
      ),
    );

    expect(find.text('C'), findsOneWidget);
    await tester.tap(find.text('C'));
    expect(opened, isTrue);
  });
}
