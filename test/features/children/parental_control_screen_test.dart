import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:delycattessen_flutter/features/children/screens/parental_control_screen.dart';
import 'package:delycattessen_flutter/features/children/services/parental_control_service.dart';
import 'package:delycattessen_flutter/features/children/widgets/parental_switch.dart';
import 'package:delycattessen_flutter/features/children/widgets/weekday_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService extends ParentalControlService {
  _FakeService(this.control);

  final ParentalControl control;
  ParentalControl? saved;

  @override
  Future<ParentalControl> getParentalControl(int studentId) async => control;

  @override
  Future<ParentalControl> updateParentalControl(
    int studentId,
    ParentalControl control,
  ) async {
    saved = control;
    return control;
  }
}

ParentalControl _control({
  bool limit = true,
  bool days = false,
  bool alert = true,
  List<int> allowed = const [0, 1, 2],
}) => ParentalControl(
  dailyLimitEnabled: limit,
  dailyLimitAmount: 1,
  allowedDaysEnabled: days,
  allowedDays: allowed,
  lowBalanceAlertEnabled: alert,
  lowBalanceAlertAmount: 2,
);

Future<_FakeService> _open(WidgetTester tester, ParentalControl control) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = _FakeService(control);
  await tester.pumpWidget(
    MaterialApp(
      home: ParentalControlScreen(
        studentId: 3,
        studentName: 'Pepito Pérez',
        service: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('header shows the child name and no "Gastado hoy" bar', (
    tester,
  ) async {
    await _open(tester, _control());

    expect(find.text('Control parental'), findsOneWidget);
    expect(find.text('Pepito Pérez'), findsOneWidget);
    expect(find.text('Gastado hoy'), findsNothing);
  });

  testWidgets('each switch is labelled Activado/Desactivado', (tester) async {
    // Limit on, days off, alert on.
    await _open(tester, _control());

    expect(find.text('Activado'), findsNWidgets(2));
    expect(find.text('Desactivado'), findsOneWidget);
    expect(find.byType(ParentalSwitch), findsNWidgets(3));
  });

  testWidgets('tapping a switch flips its label and shows the amount', (
    tester,
  ) async {
    await _open(tester, _control(limit: false, alert: false));
    expect(find.text('Desactivado'), findsNWidgets(3));
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(ParentalSwitch).first);
    await tester.pumpAndSettle();

    expect(find.text('Activado'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('allowed days off shows the help text instead of the grid', (
    tester,
  ) async {
    await _open(tester, _control(days: false));

    expect(
      find.text('Puede comprar todos los días. Actívalo para elegir días.'),
      findsOneWidget,
    );
    expect(find.byType(WeekdaySelector), findsNothing);
  });

  testWidgets('days grid has seven cells and Wednesday is "M"', (tester) async {
    await _open(tester, _control(days: true));

    expect(find.byType(WeekdaySelector), findsOneWidget);
    // L, M, M, J, V, S, D: Tuesday and Wednesday both read "M".
    expect(find.text('M'), findsNWidgets(2));
    expect(find.text('X'), findsNothing);
    expect(find.bySemanticsLabel('Miércoles'), findsOneWidget);
  });

  testWidgets('low balance card shows its label and footer', (tester) async {
    await _open(tester, _control());

    expect(find.text('Avisarme cuando el saldo baje de'), findsOneWidget);
    expect(
      find.text('El aviso aparece en Inicio con botones de recarga rápida.'),
      findsOneWidget,
    );
  });

  testWidgets('saves the toggled days', (tester) async {
    final service = await _open(
      tester,
      _control(limit: false, alert: false, days: true, allowed: const [0]),
    );

    // Tap the Friday cell (index 4) through its semantic label.
    await tester.tap(find.bySemanticsLabel('Viernes'));
    await tester.pump();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(service.saved!.allowedDays, [0, 4]);
    expect(service.saved!.allowedDaysEnabled, isTrue);
  });

  for (final (label, size, scale) in [
    ('small phone', const Size(320, 568), 1.0),
    ('small phone, big text', const Size(320, 568), 2.0),
    ('tablet', const Size(768, 1024), 1.0),
  ]) {
    testWidgets('fits without overflow: $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ParentalControlScreen(
            studentId: 3,
            studentName: 'Maria Fernanda Villavicencio Zambrano',
            service: _FakeService(_control(days: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
