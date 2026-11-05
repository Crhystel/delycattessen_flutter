import 'package:delycattessen_flutter/features/auth/widgets/initials_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, InitialsAvatar avatar) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: avatar)));

void main() {
  group('InitialsAvatar.initialsOf', () {
    test('takes the first letter of the first two words', () {
      expect(InitialsAvatar.initialsOf('ana pérez'), 'AP');
      expect(InitialsAvatar.initialsOf('  Luis   Miguel  Torres '), 'LM');
    });

    test('works with one word and is empty when there is nothing', () {
      expect(InitialsAvatar.initialsOf('Ana'), 'A');
      expect(InitialsAvatar.initialsOf(''), '');
      expect(InitialsAvatar.initialsOf('   '), '');
    });
  });

  testWidgets('shows the initials of the name', (tester) async {
    await _show(tester, const InitialsAvatar(name: 'Ana Pérez'));

    expect(find.text('AP'), findsOneWidget);
  });

  testWidgets('a parent without names shows one letter of the email', (
    tester,
  ) async {
    await _show(
      tester,
      const InitialsAvatar(name: '', fallback: 'maria.lopez@mail.com'),
    );

    expect(find.text('M'), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('shows a person icon, never a question mark, with no data', (
    tester,
  ) async {
    await _show(tester, const InitialsAvatar(name: ' ', fallback: ''));

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });
}
