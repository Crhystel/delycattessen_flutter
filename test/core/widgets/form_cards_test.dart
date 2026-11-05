import 'package:delycattessen_flutter/core/widgets/form_section_card.dart';
import 'package:delycattessen_flutter/core/widgets/profile_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('FormSectionCard shows title, subtitle and children', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FormSectionCard(
          title: 'Acceso',
          subtitle: 'Tu correo es tu usuario.',
          children: [Text('campo uno'), Text('campo dos')],
        ),
      ),
    );

    expect(find.text('Acceso'), findsOneWidget);
    expect(find.text('Tu correo es tu usuario.'), findsOneWidget);
    expect(find.text('campo uno'), findsOneWidget);
    expect(find.text('campo dos'), findsOneWidget);
  });

  testWidgets('FormSectionCard omits the subtitle when it is not given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const FormSectionCard(title: 'Datos', children: [Text('campo')])),
    );

    expect(find.text('Datos'), findsOneWidget);
    expect(find.text('campo'), findsOneWidget);
  });

  testWidgets('ProfileSummaryCard shows avatar, name and detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ProfileSummaryCard(
          leading: Icon(Icons.person),
          title: 'Ana Pérez',
          subtitle: 'ana@mail.com',
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana@mail.com'), findsOneWidget);
  });

  testWidgets('ProfileSummaryCard skips an empty detail line', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileSummaryCard(
          leading: Icon(Icons.person),
          title: 'Ana',
          subtitle: '',
        ),
      ),
    );

    expect(find.byType(Text), findsOneWidget); // only the title
  });
}
