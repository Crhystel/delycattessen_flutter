import 'package:delycattessen_flutter/features/auth/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows icon, title, value and the arrow', (tester) async {
    await tester.pumpWidget(
      _host(
        SettingsRow(
          icon: Icons.mail_outline,
          title: 'Correo',
          subtitle: 'docente@mail.com',
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('docente@mail.com'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('runs onTap and is at least 64 dp tall', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        SettingsRow(
          icon: Icons.lock_outline,
          title: 'Contraseña',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Contraseña'));

    expect(taps, 1);
    expect(
      tester.getSize(find.byType(SettingsRow)).height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('withDividers puts a divider between rows only', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: withDividers([
            SettingsRow(icon: Icons.person, title: 'Uno', onTap: () {}),
            SettingsRow(icon: Icons.person, title: 'Dos', onTap: () {}),
            SettingsRow(icon: Icons.person, title: 'Tres', onTap: () {}),
          ]),
        ),
      ),
    );

    expect(find.byType(Divider), findsNWidgets(2));
  });
}
