import 'package:delycattessen_flutter/features/auth/widgets/initials_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InitialsAvatar.initialsOf', () {
    test('takes the first letter of the first two words', () {
      expect(InitialsAvatar.initialsOf('ana pérez'), 'AP');
      expect(InitialsAvatar.initialsOf('  Luis   Miguel  Torres '), 'LM');
    });

    test('works with one word and falls back when empty', () {
      expect(InitialsAvatar.initialsOf('Ana'), 'A');
      expect(InitialsAvatar.initialsOf(''), '?');
      expect(InitialsAvatar.initialsOf('   '), '?');
    });
  });

  testWidgets('shows the initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InitialsAvatar(name: 'Ana Pérez')),
      ),
    );

    expect(find.text('AP'), findsOneWidget);
  });
}
