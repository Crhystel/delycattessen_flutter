import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/widgets/child_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child(int id, String name, String school, double balance) => Child(
  id: id,
  firstName: name,
  lastName: 'Pérez',
  institutionName: school,
  balance: balance,
);

class _FakeAuthService extends AuthService {
  _FakeAuthService({List<Child>? children})
    : _children =
          children ??
          [
            _child(1, 'Pepito', 'Martín Cerere', 50.01),
            _child(2, 'Julieta', 'Martín Cerere', 9),
            _child(3, 'Jaja', 'El Sauce School', 0),
          ];

  final List<Child> _children;

  @override
  Future<List<Child>> getChildren() async => _children;
}

Future<ChildrenProvider> _open(
  WidgetTester tester, {
  VoidCallback? onAddChild,
  List<Child>? children,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = ChildrenProvider(
    authService: _FakeAuthService(children: children),
  );
  await provider.ensureLoaded();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => ChildPickerSheet.show(
              context,
              provider,
              onAddChild: onAddChild,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  testWidgets('lists the children with balance and the low balance mark', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('¿Para quién?'), findsOneWidget);
    expect(find.text('3 hijos registrados'), findsOneWidget);
    expect(find.text('Pepito Pérez'), findsOneWidget);
    expect(find.text('\$50.01'), findsOneWidget);
    expect(find.text('Saldo bajo'), findsOneWidget); // solo el de $0.00
    expect(find.byTooltip('Cerrar'), findsNothing);
    expect(find.bySemanticsLabel('Cerrar'), findsOneWidget);
    expect(find.text('Añadir hijo/a'), findsNothing); // sin onAddChild
  });

  testWidgets('filters by name and shows an empty message', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'juli');
    await tester.pump();
    expect(find.text('Julieta Pérez'), findsOneWidget);
    expect(find.text('Pepito Pérez'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No encontramos a nadie con ese nombre.'), findsOneWidget);
  });

  testWidgets('selecting a child updates the provider and closes the sheet', (
    tester,
  ) async {
    final provider = await _open(tester);
    expect(provider.selectedChild?.id, 1);

    await tester.tap(find.text('Julieta Pérez'));
    await tester.pumpAndSettle();

    expect(provider.selectedChild?.id, 2);
    expect(find.text('¿Para quién?'), findsNothing);
  });

  testWidgets('the add button closes the sheet and runs the callback', (
    tester,
  ) async {
    var added = 0;
    await _open(tester, onAddChild: () => added++);

    await tester.tap(find.text('Añadir hijo/a'));
    await tester.pumpAndSettle();

    expect(added, 1);
    expect(find.text('¿Para quién?'), findsNothing);
  });

  testWidgets('the close button dismisses the sheet', (tester) async {
    await _open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('¿Para quién?'), findsNothing);
  });

  testWidgets('long names fit on a small screen with a large font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = ChildrenProvider(
      authService: _FakeAuthService(
        children: [
          for (var i = 1; i <= 8; i++)
            _child(
              i,
              'Maria Fernanda Alexandra $i',
              'Unidad Educativa Particular Bilingue Martim Cerere',
              0,
            ),
        ],
      ),
    );
    await provider.ensureLoaded();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  ChildPickerSheet.show(context, provider, onAddChild: () {}),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Añadir hijo/a'), findsOneWidget);
  });

  group('balance column alignment', () {
    // Very different name lengths, with and without the low balance mark.
    final children = [
      _child(1, 'Ana', 'Martín Cerere', 50.01),
      _child(
        2,
        'María Fernanda de los Ángeles',
        'Unidad Educativa Particular Bilingüe',
        9,
      ),
      _child(3, 'Jaja', 'El Sauce School', 0),
      _child(
        4,
        'Juan Sebastián Alejandro Montenegro',
        'Colegio con un nombre larguísimo',
        0.5,
      ),
    ];

    Future<void> expectAligned(WidgetTester tester) async {
      final amounts = [
        for (final text in ['\$50.01', '\$9.00', '\$0.00', '\$0.50'])
          tester.getTopRight(find.text(text)).dx,
      ];
      // Every amount ends at the same x, whatever the name length is.
      expect(amounts.every((x) => (x - amounts.first).abs() < 0.5), isTrue);

      // "Saldo bajo" is right-aligned under its amount (same right edge).
      final lowRights = [
        for (final e in tester.widgetList(find.text('Saldo bajo')))
          tester.getTopRight(find.byWidget(e)).dx,
      ];
      expect(lowRights.every((x) => (x - amounts.first).abs() < 0.5), isTrue);

      // The amount sits on the same line as the name in every row, with or
      // without the "Saldo bajo" line below it.
      const pairs = {
        'Ana Pérez': '\$50.01',
        'María Fernanda de los Ángeles Pérez': '\$9.00',
        'Jaja Pérez': '\$0.00',
        'Juan Sebastián Alejandro Montenegro Pérez': '\$0.50',
      };
      for (final entry in pairs.entries) {
        final nameBox = tester.getRect(find.text(entry.key));
        final amountBox = tester.getRect(find.text(entry.value));
        expect(
          (amountBox.center.dy - nameBox.center.dy).abs(),
          lessThan(4),
          reason: '${entry.key} and ${entry.value} on different lines',
        );
      }
    }

    testWidgets('amounts and the low balance mark line up at 390', (
      tester,
    ) async {
      await _open(tester, children: children);
      await expectAligned(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('still line up on a 340 phone with text x2', (tester) async {
      await _open(
        tester,
        children: children,
        size: const Size(340, 740),
        textScale: 2,
      );
      await expectAligned(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
