import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const names = PersonNames(
    firstName: ' Ana ',
    secondName: 'Lucía',
    lastName: 'Pérez',
  );

  group('ProfileUpdate', () {
    test('sends the four name parts and a lowercase email', () {
      final json = const ProfileUpdate(
        names: names,
        email: ' Ana@Mail.com ',
      ).toJson();
      expect(json, {
        'first_name': 'Ana',
        'second_name': 'Lucía',
        'last_name': 'Pérez',
        'second_last_name': '',
        'email': 'ana@mail.com',
      });
    });

    test('requires first name, first surname and a valid email', () {
      expect(
        const ProfileUpdate(names: names, email: 'ana@mail.com').validate(),
        isNull,
      );
      expect(
        const ProfileUpdate(
          names: PersonNames(firstName: '', lastName: 'Pérez'),
          email: 'ana@mail.com',
        ).validate(),
        isNotNull,
      );
      expect(
        const ProfileUpdate(
          names: PersonNames(firstName: 'Ana', lastName: ' '),
          email: 'ana@mail.com',
        ).validate(),
        isNotNull,
      );
      expect(
        const ProfileUpdate(names: names, email: 'ana-mail.com').validate(),
        isNotNull,
      );
    });
  });

  group('ChildProfileUpdate', () {
    test('requires a username without spaces', () {
      expect(
        const ChildProfileUpdate(names: names, username: 'ana.p').validate(),
        isNull,
      );
      expect(
        const ChildProfileUpdate(names: names, username: '').validate(),
        isNotNull,
      );
      expect(
        const ChildProfileUpdate(names: names, username: 'ana p').validate(),
        isNotNull,
      );
    });
  });

  test('Me and Child read the four name parts', () {
    final me = MeResponse.fromJson({
      'id': 1,
      'first_name': 'ANA',
      'second_name': 'LUCÍA',
      'last_name': 'PÉREZ',
      'second_last_name': 'GÓMEZ',
      'role': 'PARENT',
    });
    expect((me.secondName, me.secondLastName), ('LUCÍA', 'GÓMEZ'));

    final child = Child.fromJson({
      'id': 2,
      'first_name': 'LUIS',
      'second_name': '',
      'last_name': 'PÉREZ',
      'second_last_name': 'GÓMEZ',
      'username': 'luis.p',
      'institution_name': 'Sede A',
    });
    expect((child.secondLastName, child.username), ('GÓMEZ', 'luis.p'));
  });
}
