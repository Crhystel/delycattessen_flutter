import 'package:delycattessen_flutter/core/layout/responsive.dart';
import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/core/utils/date_formatter.dart';
import 'package:delycattessen_flutter/core/widgets/greeting_text.dart';
import 'package:delycattessen_flutter/core/widgets/profile_bubble.dart';
import 'package:delycattessen_flutter/features/contingency/screens/member_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool isTeacher}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MemberHomeScreen(
        initialUserName: 'Ana Docente',
        isTeacher: isTeacher,
      ),
    ),
  );
  // The QR request fails without a backend; the header does not depend on it.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // The home asks for the QR token (it fails fast in tests); the mocked
  // storage lets the token read finish so no request stays pending.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('a teacher gets the profile bubble next to the greeting, and no '
      'icon pill', (tester) async {
    await _pump(tester, isTeacher: true);

    expect(find.byType(ProfileBubble), findsOneWidget);
    expect(find.text('¡Hola, Ana Docente!'), findsOneWidget);
    expect(
      find.text(DateFormatter.formatGreetingDate(DateTime.now())),
      findsOneWidget,
    );
    // The bubble shows the first letter of the name.
    expect(find.text('A'), findsOneWidget);
    // Sign out lives inside "Mi perfil" now, not in the header.
    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.byIcon(Icons.manage_accounts_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a student (no profile) keeps only the sign-out button', (
    tester,
  ) async {
    await _pump(tester, isTeacher: false);

    expect(find.byType(ProfileBubble), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.text('¡Hola, Ana Docente!'), findsOneWidget);
    expect(
      find.text(DateFormatter.formatGreetingDate(DateTime.now())),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the student sign-out button is on the greeting row, to its '
      'right, and the greeting starts at the top like the tabs', (
    tester,
  ) async {
    await _pump(tester, isTeacher: false);

    final greeting = tester.getRect(find.byType(GreetingText));
    final logout = tester.getCenter(find.byIcon(Icons.logout));

    // Same row: the icon's vertical center falls inside the greeting block.
    expect(logout.dy, greaterThan(greeting.top));
    expect(logout.dy, lessThan(greeting.bottom));
    // To the right of the greeting, not above it.
    expect(logout.dx, greaterThan(greeting.center.dx));
    // No big gap: the greeting starts at the same top as the tab titles (no
    // status bar in tests), not ~90 px lower.
    final context = tester.element(find.byType(GreetingText));
    expect(greeting.top, AppLayout.pageTopPadding(context));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a student sees "Menú del mes" and "Catálogo de productos"', (
    tester,
  ) async {
    await _pump(tester, isTeacher: false);

    expect(find.text('Menú del mes'), findsOneWidget);
    expect(find.text('Catálogo de productos'), findsOneWidget);
    expect(find.text('Mi crédito'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a teacher sees the catalog and "Mi crédito", never the monthly '
      'menu', (tester) async {
    await _pump(tester, isTeacher: true);

    expect(find.text('Catálogo de productos'), findsOneWidget);
    expect(find.text('Mi crédito'), findsOneWidget);
    expect(find.text('Menú del mes'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
