import 'package:delycattessen_flutter/core/theme/app_colors.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/children/widgets/child_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child(int id) =>
    Child(id: id, firstName: 'Pepito', lastName: 'Pérez', institutionName: 'X');

Color? _background(WidgetTester tester) =>
    tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor;

Future<void> _pump(WidgetTester tester, ChildAvatar avatar) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: avatar)),
      ),
    );

void main() {
  testWidgets('rotates its tint by child id by default', (tester) async {
    await _pump(tester, ChildAvatar(child: _child(1)));

    expect(_background(tester), AppColors.brand50);
    expect(find.text('PP'), findsOneWidget);
  });

  testWidgets('fixedTint always uses the blue tint', (tester) async {
    await _pump(tester, ChildAvatar(child: _child(1), fixedTint: true));

    expect(_background(tester), AppColors.teal50);
  });
}
