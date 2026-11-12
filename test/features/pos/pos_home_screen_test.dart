import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/core/widgets/greeting_text.dart';
import 'package:delycattessen_flutter/features/pos/screens/pos_home_screen.dart';
import 'package:delycattessen_flutter/features/pos/widgets/pos_option_card.dart';
import 'package:delycattessen_flutter/features/pos/widgets/pos_quick_sale_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const PosHomeScreen(userName: 'Roberto'),
    ),
  );
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

final _face = find.widgetWithText(PosOptionCard, 'Reconocimiento facial');
final _qr = find.widgetWithText(PosOptionCard, 'Escanear código QR');
final _label = find.text('¿Sin identificar al cliente?');
final _quickSale = find.byType(PosQuickSaleButton);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('phone', () {
    const size = Size(390, 844);

    testWidgets('shows the greeting, the question and both options', (
      tester,
    ) async {
      await _pump(tester, size);

      expect(find.byType(GreetingText), findsOneWidget);
      expect(find.text('¡Hola, Roberto!'), findsOneWidget);
      expect(find.text('¿Cómo identificas al cliente?'), findsOneWidget);
      expect(
        find.text('Toca una opción para empezar a cobrar.'),
        findsOneWidget,
      );
      expect(_face, findsOneWidget);
      expect(_qr, findsOneWidget);
      expect(find.text('Identifica por rostro'), findsOneWidget);
      expect(find.text('Escanea el código QR del usuario'), findsOneWidget);
      expect(find.text('Venta rápida'), findsOneWidget);
      expect(_label, findsOneWidget);
    });

    testWidgets('puts the options one under the other, then the quick sale', (
      tester,
    ) async {
      await _pump(tester, size);

      final face = _rect(tester, _face);
      final qr = _rect(tester, _qr);
      expect(qr.top, greaterThan(face.bottom));
      expect(qr.left, face.left);
      expect(qr.width, face.width);
      expect(face.height, greaterThanOrEqualTo(132));
      expect(_rect(tester, _label).top, greaterThan(qr.bottom));
      expect(
        _rect(tester, _quickSale).top,
        greaterThan(_rect(tester, _label).bottom),
      );
      // Cards keep the 20 dp page margin of the design.
      expect(face.left, 20);
      expect(size.width - face.right, 20);
    });

    testWidgets('has a chevron on each option', (tester) async {
      await _pump(tester, size);

      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });
  });

  group('landscape tablet', () {
    const size = Size(1024, 768);

    testWidgets('puts the options side by side with the same size', (
      tester,
    ) async {
      await _pump(tester, size);

      final face = _rect(tester, _face);
      final qr = _rect(tester, _qr);
      expect(qr.left, greaterThan(face.right));
      expect(qr.top, face.top);
      expect(qr.size, face.size);
      expect(face.height, 300);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('centers the question and the cards on the screen', (
      tester,
    ) async {
      await _pump(tester, size);

      final title = _rect(tester, find.text('¿Cómo identificas al cliente?'));
      expect(title.center.dx, closeTo(size.width / 2, 1));
      final cards = _rect(tester, _face).expandToInclude(_rect(tester, _qr));
      expect(cards.center.dx, closeTo(size.width / 2, 1));
      expect(cards.width, lessThanOrEqualTo(760));
    });

    testWidgets('puts the quick sale button next to its label', (tester) async {
      await _pump(tester, size);

      final label = _rect(tester, _label);
      final button = _rect(tester, _quickSale);
      expect(button.left, greaterThan(label.right));
      expect(button.center.dy, closeTo(label.center.dy, 2));
    });
  });

  group('portrait tablet', () {
    const size = Size(768, 1024);

    testWidgets('puts the options side by side, taller than in landscape', (
      tester,
    ) async {
      await _pump(tester, size);

      final face = _rect(tester, _face);
      final qr = _rect(tester, _qr);
      expect(qr.left, greaterThan(face.right));
      expect(qr.top, face.top);
      expect(face.height, 360);
      expect(face.left, 48);
      expect(size.width - qr.right, 48);
    });

    testWidgets('puts the quick sale button below its label', (tester) async {
      await _pump(tester, size);

      final label = _rect(tester, _label);
      final button = _rect(tester, _quickSale);
      expect(button.top, greaterThan(label.bottom));
      expect(button.center.dx, closeTo(size.width / 2, 1));
    });
  });

  group('without overflow', () {
    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(411, 891),
      Size(768, 1024),
      Size(800, 1280),
      Size(1024, 768),
      Size(1280, 800),
    ];
    for (final size in sizes) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} with text x$scale',
          (tester) async {
            await _pump(tester, size, textScale: scale);

            expect(tester.takeException(), isNull);
            expect(_face, findsOneWidget);
            expect(_qr, findsOneWidget);
            expect(_quickSale, findsOneWidget);
          },
        );
      }
    }
  });

  testWidgets('the logout button asks for confirmation', (tester) async {
    await _pump(tester, const Size(390, 844));

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('¿Estás seguro de que deseas cerrar sesión en el POS?'),
      findsOneWidget,
    );
  });
}
