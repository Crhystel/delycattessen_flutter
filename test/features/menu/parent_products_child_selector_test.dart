import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/widgets/child_switch_bar.dart';
import 'package:delycattessen_flutter/features/menu/screens/parent_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Child _child(int id, String name, double balance) => Child(
  id: id,
  firstName: name,
  lastName: 'Pérez',
  institutionName: 'Martín Cerere',
  balance: balance,
);

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._children);

  final List<Child> _children;

  @override
  Future<List<Child>> getChildren() async => _children;
}

Future<ChildrenProvider> _pump(
  WidgetTester tester,
  List<Child> children,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = ChildrenProvider(authService: _FakeAuthService(children));
  await provider.ensureLoaded();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: ParentProductsScreen(
          headerAccessory: Text('selector menu-productos'),
        ),
      ),
    ),
  );
  // The header measures its content after each frame (the selector appears once
  // the child is known), so a few frames are needed before it settles.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return provider;
}

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.hitTestable()).dy;

void main() {
  // The catalog asks the backend for its items (it fails fast in tests); the
  // mocked storage lets the token read finish so no request stays pending.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('shows the same child selector as the monthly menu, between the '
      'switch and the search', (tester) async {
    await _pump(tester, [_child(1, 'Pepito', 50.01), _child(2, 'Julieta', 9)]);

    expect(find.byType(ChildSwitchBar), findsOneWidget);
    expect(find.text('Pidiendo para'), findsOneWidget);
    expect(find.text('Pepito Pérez'), findsOneWidget);
    expect(find.text('\$50.01'), findsOneWidget);

    final switchTop = _top(tester, find.text('selector menu-productos'));
    final barTop = _top(tester, find.byType(ChildSwitchBar));
    final searchTop = _top(tester, find.byType(TextField));
    expect(switchTop, lessThan(barTop));
    expect(barTop, lessThan(searchTop));
  });

  testWidgets('picking another child changes the selected one', (tester) async {
    final provider = await _pump(tester, [
      _child(1, 'Pepito', 50.01),
      _child(2, 'Julieta', 9),
    ]);

    await tester.tap(find.byType(ChildSwitchBar));
    await tester.pumpAndSettle();
    expect(find.text('¿Para quién estás pidiendo?'), findsOneWidget);
    await tester.tap(find.text('Julieta Pérez').last);
    await tester.pumpAndSettle();

    expect(provider.selectedChild?.id, 2);
    expect(find.text('Julieta Pérez'), findsOneWidget);
  });
}
