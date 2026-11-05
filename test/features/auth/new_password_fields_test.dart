import 'package:delycattessen_flutter/features/auth/widgets/new_password_fields.dart';
import 'package:delycattessen_flutter/features/auth/widgets/password_requirements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController password;
  late TextEditingController confirm;

  setUp(() {
    password = TextEditingController();
    confirm = TextEditingController();
  });

  tearDown(() {
    password.dispose();
    confirm.dispose();
  });

  Future<void> pumpFields(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NewPasswordFields(
            passwordController: password,
            confirmController: confirm,
            passwordHint: 'Contraseña',
            confirmHint: 'Confirmar',
          ),
        ),
      ),
    ),
  );

  testWidgets('shows both fields and the requirements guide', (tester) async {
    await pumpFields(tester);

    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.byType(PasswordRequirements), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsNothing);
  });

  testWidgets('repaints the guide while the user types', (tester) async {
    await pumpFields(tester);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));

    await tester.enterText(find.byType(TextField).first, 'Abcdef1!');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('warns only when the confirmation differs', (tester) async {
    await pumpFields(tester);
    await tester.enterText(find.byType(TextField).first, 'Abcdef1!');
    await tester.enterText(find.byType(TextField).last, 'Abcdef1');
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Abcdef1!');
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsNothing);
  });
}
