import 'package:delycattessen_flutter/core/widgets/terms_checkbox.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('tapping the text toggles the checkbox', (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => TermsCheckbox(
            value: accepted,
            onChanged: (value) => setState(() => accepted = value),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Acepto los términos y condiciones'));
    await tester.pump();

    expect(accepted, isTrue);
    expect(find.byIcon(Icons.open_in_new), findsNothing);
  });

  testWidgets('with a url the terms are a link with the link icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TermsCheckbox(
          value: false,
          onChanged: (_) {},
          termsUrl: 'https://example.com/terminos',
        ),
      ),
    );

    expect(find.text('Términos y condiciones'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  test('the registrations send the acceptance of the terms', () {
    expect(
      ParentRegistration(
        email: 'a@b.co',
        password: 'x',
        passwordConfirm: 'x',
      ).toJson()['accept_terms'],
      isTrue,
    );
    expect(
      StudentRegistration(
        firstName: 'Ana',
        firstLastName: 'Pérez',
        institutionId: 1,
        username: 'ana.p',
        password: 'x',
        profilePicturePath: 'foto.jpg',
      ).toFields()['accept_terms'],
      'true',
    );
  });
}
