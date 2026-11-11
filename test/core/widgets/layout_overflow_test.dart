import 'package:delycattessen_flutter/core/widgets/header_actions.dart';
import 'package:delycattessen_flutter/core/widgets/profile_summary_card.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/change_email_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_names_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_password_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/widgets/initials_avatar.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:delycattessen_flutter/features/children/providers/child_settings_controller.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_names_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_password_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_username_screen.dart';
import 'package:delycattessen_flutter/features/children/services/parental_control_service.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
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

/// Services that answer right away so the child menu does not hit the network.
class _FakeAuthService extends AuthService {
  @override
  Future<List<Allergen>> getStudentAllergies(int studentId) async => [
    Allergen(id: 1, name: 'Sulfitos'),
  ];
}

class _FakeParentalService extends ParentalControlService {
  @override
  Future<ParentalControl> getParentalControl(int studentId) async =>
      ParentalControl(
        dailyLimitEnabled: true,
        dailyLimitAmount: 1,
        allowedDaysEnabled: false,
        allowedDays: const [],
        lowBalanceAlertEnabled: true,
      );
}

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

      testWidgets('profile menu: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          ProfileScreen(me: _me, onOpenAllergies: () {}),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Alergias'), findsOneWidget);
      });

      for (final screen in <String, Widget Function()>{
        'names form': () => EditNamesScreen(me: _me),
        'email form': () => ChangeEmailScreen(me: _me),
        'password form': () => const ProfilePasswordScreen(),
      }.entries) {
        testWidgets('${screen.key}: $label', (tester) async {
          await _pump(tester, entry.value, scale, screen.value());

          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('child menu: $label', (tester) async {
        final settings = ChildSettingsController(
          studentId: _child.id,
          authService: _FakeAuthService(),
          parentalService: _FakeParentalService(),
        );
        addTearDown(settings.dispose);
        await _pump(
          tester,
          entry.value,
          scale,
          EditChildScreen(child: _child, settings: settings),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Nombres'), findsOneWidget);
      });

      for (final form in {
        'names': EditChildNamesScreen(child: _child),
        'username': EditChildUsernameScreen(child: _child),
        'password': EditChildPasswordScreen(child: _child),
      }.entries) {
        testWidgets('child ${form.key} form: $label', (tester) async {
          await _pump(tester, entry.value, scale, form.value);

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
