import 'package:delycattessen_flutter/core/theme/app_colors.dart';
import 'package:delycattessen_flutter/core/widgets/header_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<HeaderAction> actions) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topRight,
      child: HeaderActions(actions: actions),
    ),
  ),
);

void main() {
  testWidgets('shows one button per action with its tooltip', (tester) async {
    await tester.pumpWidget(
      _host([
        HeaderAction(
          icon: Icons.person,
          tooltip: 'Mi perfil',
          onPressed: () {},
        ),
        HeaderAction(icon: Icons.logout, tooltip: 'Salir', onPressed: () {}),
      ]),
    );

    expect(find.byType(IconButton), findsNWidgets(2));
    expect(find.byTooltip('Mi perfil'), findsOneWidget);
    expect(find.byTooltip('Salir'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  testWidgets('runs the action that was tapped', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _host([
        HeaderAction(
          icon: Icons.person,
          tooltip: 'Mi perfil',
          onPressed: () => taps.add('perfil'),
        ),
        HeaderAction(
          icon: Icons.logout,
          tooltip: 'Salir',
          onPressed: () => taps.add('salir'),
        ),
      ]),
    );

    await tester.tap(find.byTooltip('Salir'));
    await tester.tap(find.byTooltip('Mi perfil'));

    expect(taps, ['salir', 'perfil']);
  });

  testWidgets('a single action has no divider', (tester) async {
    await tester.pumpWidget(
      _host([
        HeaderAction(icon: Icons.logout, tooltip: 'Salir', onPressed: () {}),
      ]),
    );

    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
  });

  testWidgets('each target is at least 48 dp and sits on a white pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        HeaderAction(
          icon: Icons.person,
          tooltip: 'Mi perfil',
          onPressed: () {},
        ),
        HeaderAction(
          icon: Icons.logout,
          tooltip: 'Salir',
          onPressed: () {},
          color: AppColors.danger700,
        ),
      ]),
    );

    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(button.constraints!.minWidth, greaterThanOrEqualTo(48));
      expect(button.constraints!.minHeight, greaterThanOrEqualTo(48));
    }
    final pill = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(IconButton).first,
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((pill.decoration as BoxDecoration).color, Colors.white);
  });
}
