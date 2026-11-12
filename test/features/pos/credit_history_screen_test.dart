import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/screens/credit_history_screen.dart';
import 'package:delycattessen_flutter/features/pos/services/pos_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePos extends PosService {
  _FakePos({this.history, this.fail = false});

  final CreditHistory? history;
  final bool fail;

  @override
  Future<CreditHistory> getCreditHistory() async {
    if (fail) throw Exception('sin conexión');
    return history!;
  }
}

CreditHistory _history(List<Map<String, dynamic>> sales) =>
    CreditHistory.fromJson({
      'month': '2026-10',
      'accumulated_total': '8.50',
      'results': sales,
    });

Map<String, dynamic> _sale(int id, String name, String total, String at) => {
  'id': id,
  'payment_method': 'credit',
  'total_amount': total,
  'created_at': at,
  'display_name': name,
  'time': '9:55 pm',
  'items': <Map<String, dynamic>>[],
};

Future<void> _pump(WidgetTester tester, PosService service) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: CreditHistoryScreen(personName: 'Ana Docente', posService: service),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the month total and the purchases grouped by day', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePos(
        history: _history([
          _sale(1, 'Helado', '3.50', '2026-10-22T21:55:00'),
          _sale(2, 'Crepes', '5.00', '2026-10-15T22:49:00'),
        ]),
      ),
    );

    expect(find.text('Compras a crédito'), findsOneWidget);
    expect(find.text('Ana Docente'), findsOneWidget);
    expect(find.textContaining('8.50'), findsWidgets);
    expect(find.text('Jueves 22 de octubre'), findsOneWidget);
    expect(find.text('Jueves 15 de octubre'), findsOneWidget);
    // It is a plain list: the old purple header and type filter are gone.
    expect(find.text('Detalles de compra'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('a purchase detail has no balance line (credit has no wallet)', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePos(
        history: _history([_sale(1, 'Helado', '3.50', '2026-10-22T21:55:00')]),
      ),
    );

    // Wide enough for the test font (every glyph is a full em wide).
    await tester.binding.setSurfaceSize(const Size(600, 900));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Saldo después del movimiento'), findsNothing);
  });

  testWidgets('shows an empty message when there are no purchases', (
    tester,
  ) async {
    await _pump(tester, _FakePos(history: _history(const [])));

    expect(find.text('Aún no hay compras'), findsOneWidget);
    expect(find.text('Tus compras a crédito aparecerán aquí.'), findsOneWidget);
  });

  testWidgets('shows an error with a retry button when loading fails', (
    tester,
  ) async {
    await _pump(tester, _FakePos(fail: true));

    expect(find.text('No pudimos cargar tus compras'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
