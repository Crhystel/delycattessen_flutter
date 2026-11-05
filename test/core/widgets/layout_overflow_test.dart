import 'package:delycattessen_flutter/core/widgets/header_actions.dart';
import 'package:delycattessen_flutter/core/widgets/initials_avatar.dart';
import 'package:delycattessen_flutter/core/widgets/profile_summary_card.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_profile_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phones from small to large, landscape and a tablet (logical dp).
const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x640': Size(360, 640),
  'large phone 411x891': Size(411, 891),
  'landscape phone 740x360': Size(740, 360),
  'tablet 800x1280': Size(800, 1280),
};

const _textScales = [1.0, 2.0];

const _longName =
    'Maria Fernanda Alexandra de los Angeles Villavicencio Zambrano';
const _longEmail =
    'maria.fernanda.villavicencio.zambrano.de.los.angeles@institucion-educativa.edu.ec';

final _me = MeResponse(
  id: 1,
  email: _longEmail,
  firstName: 'Maria Fernanda Alexandra',
  secondName: 'de los Angeles',
  lastName: 'Villavicencio',
  secondLastName: 'Zambrano',
  role: 'TEACHER',
  hasChildren: false,
  hasPaymentPin: false,
  mustChangePassword: false,
);

final _child = Child(
  id: 2,
  firstName: 'Maria Fernanda Alexandra',
  lastName: 'Villavicencio Zambrano',
  username: 'maria.fernanda.villavicencio.zambrano',
  institutionName: 'Unidad Educativa Particular Bilingue Martim Cerere Norte',
);

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget home,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // An overflow ("RenderFlex overflowed") is reported as a framework
  // exception, so a clean takeException means nothing was cut or overflowed.
  for (final entry in _sizes.entries) {
    for (final scale in _textScales) {
      final label = '${entry.key}, text x$scale';

      testWidgets('home header with a long greeting: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Hola $_longName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    HeaderActions(
                      actions: [
                        HeaderAction(
                          icon: Icons.manage_accounts_outlined,
                          tooltip: 'Mi perfil',
                          onPressed: () {},
                        ),
                        HeaderAction(
                          icon: Icons.logout,
                          tooltip: 'Cerrar sesión',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
      });

      testWidgets('summary card with long texts: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: ProfileSummaryCard(
                leading: InitialsAvatar(name: _longName),
                title: _longName,
                subtitle: _longEmail,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('profile form with password section: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          EditProfileScreen(me: _me, canChangePassword: true),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Guardar cambios'), findsOneWidget);
      });

      testWidgets('child form: $label', (tester) async {
        await _pump(tester, entry.value, scale, EditChildScreen(child: _child));

        expect(tester.takeException(), isNull);
        expect(find.text('Guardar cambios'), findsOneWidget);
      });
    }
  }
}
