import 'package:delycattessen_flutter/features/auth/utils/password_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const valid = 'Str0ng-Passw0rd!';

  group('checkNewPassword', () {
    test('accepts a valid password with a matching confirmation', () {
      expect(checkNewPassword(valid, confirmation: valid), isNull);
    });

    test('validates only the policy without a confirmation', () {
      expect(checkNewPassword(valid), isNull);
      expect(checkNewPassword('abc'), isNotNull);
    });

    test('lists what a weak password is missing', () {
      final issue = checkNewPassword('abc', confirmation: 'abc');

      expect(issue, isNotNull);
      expect(issue!.title, 'Contraseña insegura');
      expect(issue.message, contains('Mínimo 8 caracteres'));
      expect(issue.message, contains('Al menos una letra mayúscula'));
    });

    test('rejects an empty password as insecure', () {
      expect(checkNewPassword('')!.title, 'Contraseña insegura');
    });

    test('reports a confirmation that does not match', () {
      final issue = checkNewPassword(valid, confirmation: '${valid}x');

      expect(issue!.title, 'Las contraseñas no coinciden');
    });
  });
}
