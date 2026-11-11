import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/core/widgets/profile_bubble.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/screens/children_list_screen.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/menu_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/orders_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/parent_products_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Status bar / camera zone simulated on top of the screen.
const _cameraInset = 30.0;

/// Distance from the top edge of the screen to the top of the profile bubble:
/// the camera zone plus the fixed 16 margin, the same on every tab.
const _expectedBubbleTop = _cameraInset + 16;

final _child = Child(
  id: 5,
  firstName: 'Ana',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 20,
);

class _FakeAuth extends AuthService {
  @override
  Future<List<Child>> getChildren() async => [_child];
}

class _FakeMenu extends MenuService {
  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async => const [];

  @override
  Future<CatalogOffers> getActiveOffers({int? studentId}) async =>
      CatalogOffers.empty;

  @override
  Future<List<PreOrderSummary>> getPreOrders({int? studentId}) async => [];

  @override
  Future<List<OrderEntry>> getPurchases({int? studentId}) async => [];
}

enum _View { home, menu, products, orders, ordersWithBack }

/// Greeting long enough to take two lines at 340 px wide.
const _longName = 'Crhystel Alejandra María del Carmen';

Widget _screenFor(_View view) {
  final bubble = ProfileBubble(initial: 'C', onTap: () {});
  switch (view) {
    case _View.home:
      return ChildrenListScreen(
        userName: _longName,
        menuService: _FakeMenu(),
        profileAction: bubble,
      );
    case _View.menu:
      return MenuScreen(
        embedded: true,
        headerAccessory: const Text('selector menu-productos'),
        profileAction: bubble,
        menuController: ParentMenuController(menuService: _FakeMenu()),
      );
    case _View.products:
      return ParentProductsScreen(
        headerAccessory: const Text('selector menu-productos'),
        profileAction: bubble,
      );
    case _View.orders:
      return OrdersScreen(
        embedded: true,
        menuService: _FakeMenu(),
        profileAction: bubble,
      );
    case _View.ordersWithBack:
      return OrdersScreen(
        studentId: _child.id,
        menuService: _FakeMenu(),
        profileAction: bubble,
      );
  }
}

Future<double> _bubbleTop(
  WidgetTester tester,
  _View view, {
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = ChildrenProvider(authService: _FakeAuth());
  addTearDown(provider.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewPadding: const EdgeInsets.only(top: _cameraInset),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: _screenFor(view),
      ),
    ),
  );
  // The collapsing header measures its content after each frame, and the
  // children and the lists load asynchronously.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(ProfileBubble), findsOneWidget);
  return tester.getTopLeft(find.byType(ProfileBubble)).dy;
}

void main() {
  // Some screens ask the backend for data (it fails fast in tests); the mocked
  // storage lets the token read finish so no request stays pending.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final width in [390.0, 340.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'the profile bubble is at the same height on every parent tab '
        '(width $width, text x$scale)',
        (tester) async {
          for (final view in _View.values) {
            final top = await _bubbleTop(
              tester,
              view,
              width: width,
              textScale: scale,
            );
            expect(
              top,
              _expectedBubbleTop,
              reason: '${view.name} puts the bubble at $top',
            );
          }
        },
      );
    }
  }
}
