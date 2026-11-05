import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MeResponse testMe({
  String firstName = 'Ana',
  String lastName = 'Pérez',
  String email = 'docente@mail.com',
  String role = 'TEACHER',
}) => MeResponse(
  id: 7,
  email: email,
  firstName: firstName,
  secondName: 'Lucía',
  lastName: lastName,
  secondLastName: 'Mora',
  role: role,
  hasChildren: false,
  hasPaymentPin: false,
  mustChangePassword: false,
);

/// Records the calls in order and can fail either step.
class FakeAuthService extends AuthService {
  final List<String> calls = [];
  ProfileUpdate? lastProfile;
  ChangePasswordRequest? lastPassword;
  ApiException? profileError;
  ApiException? passwordError;

  @override
  Future<MeResponse> updateProfile(ProfileUpdate data) async {
    calls.add('profile');
    lastProfile = data;
    if (profileError != null) throw profileError!;
    return MeResponse(
      id: 7,
      email: data.email.trim().toLowerCase(),
      firstName: data.names.firstName.trim(),
      secondName: data.names.secondName.trim(),
      lastName: data.names.lastName.trim(),
      secondLastName: data.names.secondLastName.trim(),
      role: 'TEACHER',
      hasChildren: false,
      hasPaymentPin: false,
      mustChangePassword: false,
    );
  }

  @override
  Future<void> changePassword(ChangePasswordRequest data) async {
    calls.add('password');
    lastPassword = data;
    if (passwordError != null) throw passwordError!;
  }
}

/// Opens [screen] from a button so the pop result can be observed.
class ResultHost extends StatefulWidget {
  const ResultHost({super.key, required this.screen});

  final Widget screen;

  @override
  State<ResultHost> createState() => ResultHostState();
}

class ResultHostState extends State<ResultHost> {
  Object? result;
  bool popped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final value = await Navigator.of(
              context,
            ).push<Object?>(MaterialPageRoute(builder: (_) => widget.screen));
            setState(() {
              result = value;
              popped = true;
            });
          },
          child: const Text('abrir'),
        ),
      ),
    );
  }
}

Future<void> openScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: ResultHost(screen: screen)));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Types into the field that sits under [label].
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, text);
  await tester.pump();
}

/// Taps [label] once any previous notification is gone: it can cover buttons.
Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ResultHostState hostOf(WidgetTester tester) =>
    tester.state<ResultHostState>(find.byType(ResultHost));
