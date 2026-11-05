import 'package:delycattessen_flutter/features/auth/utils/email_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const current = 'docente@mail.com';

  /// Title of the issue found, or null when the change is valid.
  String? titleOf({
    String newEmail = 'nuevo@mail.com',
    String password = 'Old-Passw0rd!',
  }) => checkEmailChange(
    currentEmail: current,
    newEmail: newEmail,
    currentPassword: password,
  )?.title;

  test('accepts a different valid email with the password', () {
    expect(titleOf(), isNull);
  });

  test('rejects an invalid email', () {
    expect(titleOf(newEmail: 'sin-arroba'), 'Correo inválido');
    expect(titleOf(newEmail: ''), 'Correo inválido');
  });

  test('rejects the same email, ignoring case and spaces', () {
    expect(titleOf(newEmail: ' DOCENTE@mail.com '), 'Es el mismo correo');
  });

  test('requires the current password', () {
    expect(titleOf(password: ''), 'Datos incompletos');
  });
}
