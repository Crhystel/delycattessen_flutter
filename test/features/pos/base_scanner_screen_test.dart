import 'package:delycattessen_flutter/features/pos/widgets/base_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeScanner extends BaseScannerScreen {
  const _FakeScanner({this.withPrimary = true});

  final bool withPrimary;

  @override
  State<_FakeScanner> createState() => _FakeScannerState();
}

class _FakeScannerState extends BaseScannerScreenState<_FakeScanner> {
  @override
  String get screenTitle => 'Reconocimiento Facial';

  @override
  String get instructionText =>
      'Coloca el rostro del usuario\ndentro del encuadre';

  @override
  String get helpNoticeText =>
      'Asegúrate de tener\nbuena iluminación y\nque el rostro esté\ncentrado.';

  @override
  Widget? buildPrimaryAction(BuildContext context) => widget.withPrimary
      ? ElevatedButton(onPressed: () {}, child: const Text('Escanear rostro'))
      : null;

  @override
  Widget buildScannerContent(BuildContext context) =>
      const ColoredBox(key: Key('camera'), color: Colors.green);
}

Future<void> _open(
  WidgetTester tester,
  Size size, {
  bool withPrimary = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: _FakeScanner(withPrimary: withPrimary)),
  );
  await tester.pump();
}

/// The scan line animates forever, so pumpAndSettle would never return.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final entry in {
    'phone': const Size(390, 844),
    'small phone': const Size(320, 568),
    'tablet': const Size(1024, 768),
  }.entries) {
    group(entry.key, () {
      testWidgets('the camera fills the whole screen', (tester) async {
        await _open(tester, entry.value);

        expect(tester.getSize(find.byKey(const Key('camera'))), entry.value);
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows the title, the instruction and both actions', (
        tester,
      ) async {
        await _open(tester, entry.value);

        expect(find.text('Reconocimiento Facial'), findsOneWidget);
        expect(
          find.text('Coloca el rostro del usuario dentro del encuadre'),
          findsOneWidget,
        );
        expect(find.text('Escanear rostro'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      });

      testWidgets('the actions stay inside the screen', (tester) async {
        await _open(tester, entry.value);

        for (final label in ['Escanear rostro', 'Cancelar']) {
          final rect = tester.getRect(find.text(label));
          expect(rect.left, greaterThanOrEqualTo(0), reason: label);
          expect(
            rect.right,
            lessThanOrEqualTo(entry.value.width),
            reason: label,
          );
          expect(
            rect.bottom,
            lessThanOrEqualTo(entry.value.height),
            reason: label,
          );
        }
      });

      testWidgets('works without a primary action', (tester) async {
        await _open(tester, entry.value, withPrimary: false);

        expect(find.text('Escanear rostro'), findsNothing);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('on a phone both actions share one row', (tester) async {
    await _open(tester, const Size(390, 844));

    final primary = tester.getRect(find.text('Escanear rostro'));
    final cancel = tester.getRect(find.text('Cancelar'));

    expect((primary.center.dy - cancel.center.dy).abs(), lessThan(8));
    expect(primary.center.dx, lessThan(cancel.center.dx));
  });

  testWidgets('the back button and Cancel close the scanner', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _FakeScanner()),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);
    expect(find.text('Reconocimiento Facial'), findsNothing);

    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Volver'));
    await _settle(tester);
    expect(find.text('Reconocimiento Facial'), findsNothing);
  });
}
