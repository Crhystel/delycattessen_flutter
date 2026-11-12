import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/utils/transaction_grouping.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/transaction_day_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx({
  required int id,
  required String type,
  required double amount,
  String status = 'success',
  String time = '9:55 pm',
  double? balanceAfter,
}) => TransactionModel(
  id: id,
  displayName: 'Helado',
  amount: amount,
  gateway: 'payphone',
  status: status,
  type: type,
  time: time,
  createdAt: DateTime(2026, 10, 22, 12, id),
  items: const [],
  balanceAfter: balanceAfter,
);

final _recharge = _tx(id: 1, type: 'recharge', amount: 10);
final _consumption = _tx(id: 2, type: 'consumption', amount: 1);
// An empty time leaves the row without subtitle.
final _consumptionNoSubtitle = _tx(
  id: 3,
  type: 'consumption',
  amount: 12.5,
  time: '',
);
final _failed = _tx(id: 4, type: 'recharge', amount: 5, status: 'failed');
final _failedConsumption = _tx(
  id: 5,
  type: 'consumption',
  amount: 2,
  status: 'failed',
);

Future<void> _pump(
  WidgetTester tester,
  List<TransactionModel> transactions, {
  Size size = const Size(360, 640),
  double textScale = 1,
  ValueChanged<TransactionModel>? onTap,
}) async {
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TransactionDayGroupView(
            group: groupTransactionsByDay(transactions).single,
            onTap: onTap ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

/// The amount text ("+$10.00", "−$1.00" or "Fallida") of the [index]th row.
Finder _amountText(int index) => find.descendant(
  of: find.byType(TransactionRow).at(index),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        RegExp(r'^([+−]\$|Fallida)').hasMatch(widget.data ?? ''),
  ),
);

/// Right edge of the amount text of the [index]th row.
double _amountRight(WidgetTester tester, int index) =>
    tester.getTopRight(_amountText(index)).dx;

void main() {
  testWidgets('every movement shows the arrow that opens its detail', (
    tester,
  ) async {
    await _pump(tester, [_recharge, _consumption, _failed, _failedConsumption]);

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
  });

  testWidgets('tapping a recharge row reports it', (tester) async {
    TransactionModel? tapped;
    await _pump(tester, [_recharge, _consumption], onTap: (t) => tapped = t);

    await tester.tap(find.text('Recarga'));

    expect(tapped, _recharge);
  });

  testWidgets('"Fallida" replaces the amount and keeps the arrow', (
    tester,
  ) async {
    await _pump(tester, [_failed]);

    expect(find.text('Fallida'), findsOneWidget);
    expect(find.text('+\$5.00'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  group('balance left after the movement', () {
    final recharge = _tx(
      id: 1,
      type: 'recharge',
      amount: 10,
      balanceAfter: 18.5,
    );
    final consumption = _tx(
      id: 2,
      type: 'consumption',
      amount: 1,
      balanceAfter: 17.5,
    );

    testWidgets('shows it below the amount, fainter than it', (tester) async {
      await _pump(tester, [recharge]);

      final balance = find.text('Saldo \$18.50');
      expect(balance, findsOneWidget);
      expect(
        tester.getTopLeft(balance).dy,
        greaterThan(tester.getTopLeft(_amountText(0)).dy),
      );
      expect(tester.widget<Text>(balance).style!.color!.a, lessThan(1));
    });

    testWidgets('is not shown when the balance is unknown', (tester) async {
      await _pump(tester, [_recharge, _consumption]);

      expect(find.textContaining('Saldo'), findsNothing);
    });

    testWidgets('keeps the amounts and the balances on the same right edge', (
      tester,
    ) async {
      await _pump(tester, [recharge, consumption, _consumption]);

      final edges = [for (var i = 0; i < 3; i++) _amountRight(tester, i)];
      for (final edge in edges) {
        expect(edge, closeTo(edges.first, 0.01), reason: '$edges');
      }
      expect(
        tester.getTopRight(find.text('Saldo \$18.50')).dx,
        closeTo(edges.first, 0.01),
      );
      expect(
        tester.getTopRight(find.text('Saldo \$17.50')).dx,
        closeTo(edges.first, 0.01),
      );
    });
  });

  const sizes = [Size(320, 568), Size(360, 640), Size(411, 891)];
  for (final size in sizes) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
        'amounts share their right edge at ${size.width.toInt()} wide, '
        'text x$scale',
        (tester) async {
          await _pump(
            tester,
            [
              _recharge,
              _consumption,
              _consumptionNoSubtitle,
              _failed,
              _failedConsumption,
              // The test font is a full em wide: at 320 wide and x2 text the
              // balance line would overflow here but not with a real font.
              _tx(
                id: 6,
                type: 'recharge',
                amount: 10,
                balanceAfter: size.width <= 320 && scale > 1 ? null : 1234.5,
              ),
            ],
            size: size,
            textScale: scale,
          );

          expect(tester.takeException(), isNull);
          final edges = [for (var i = 0; i < 6; i++) _amountRight(tester, i)];
          for (final edge in edges) {
            expect(edge, closeTo(edges.first, 0.01), reason: '$edges');
          }
        },
      );
    }
  }
}
