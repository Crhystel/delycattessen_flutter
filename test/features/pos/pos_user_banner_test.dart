import 'package:delycattessen_flutter/features/pos/models/pos_identification_model.dart';
import 'package:delycattessen_flutter/features/pos/widgets/pos_user_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

IdentifiedUser _user({
  String role = 'STUDENT',
  double balance = 12.5,
  double? credit,
  List<String> allergies = const [],
}) => IdentifiedUser(
  userId: 1,
  username: 'ana',
  fullName: 'Ana Pérez',
  role: role,
  roleDisplay: role,
  balance: balance,
  creditAccumulated: credit,
  allergies: allergies,
  pendingOrders: const [],
  identificationMethod: 'QR',
);

Future<void> _pump(WidgetTester tester, IdentifiedUser user) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PosUserBanner(user: user)),
      ),
    );

void main() {
  testWidgets('shows who the cashier is selling to and the balance', (
    tester,
  ) async {
    await _pump(tester, _user());

    expect(find.text('Vendiendo a Ana Pérez'), findsOneWidget);
    expect(find.text('Saldo a favor: \$12.50'), findsOneWidget);
    expect(find.textContaining('Alergias'), findsNothing);
  });

  testWidgets('shows the month consumption of a teacher', (tester) async {
    await _pump(tester, _user(role: 'TEACHER', credit: 8.25));

    expect(find.text('Consumido este mes: \$8.25'), findsOneWidget);
  });

  testWidgets('shows the allergies of the customer', (tester) async {
    await _pump(tester, _user(allergies: ['Gluten', 'Maní']));

    expect(find.text('Alergias: Gluten, Maní'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
