import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nunito va empaquetada en `assets/fonts`: con la descarga desactivada la app
/// debe poder dibujar todos los pesos que usa sin tocar la red.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('every Nunito weight used by the app loads from the assets', (
    tester,
  ) async {
    const weights = [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final weight in weights)
              Text('Nunito', style: GoogleFonts.nunito(fontWeight: weight)),
          ],
        ),
      ),
    );
    await GoogleFonts.pendingFonts();
    await tester.pump();

    // Si faltara un archivo, google_fonts lanzaría una excepción al cargarlo.
    expect(tester.takeException(), isNull);
  });
}
