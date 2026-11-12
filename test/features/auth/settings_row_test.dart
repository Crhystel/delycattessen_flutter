import 'package:delycattessen_flutter/core/theme/app_colors.dart';
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

  testWidgets('a destructive row is red and a normal one is not', (
    tester,
  ) async {
    Color? titleColor(String title) =>
        tester.widget<Text>(find.text(title)).style?.color;
    Color? iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            SettingsRow(
              icon: Icons.person_remove_outlined,
              title: 'Dar de baja',
              destructive: true,
              onTap: () {},
            ),
            SettingsRow(
              icon: Icons.lock_outline,
              title: 'Contraseña',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(titleColor('Dar de baja'), AppColors.danger700);
    expect(iconColor(Icons.person_remove_outlined), AppColors.danger700);
    expect(titleColor('Contraseña'), AppColors.ink900);
    expect(iconColor(Icons.lock_outline), AppColors.secondary500);
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
