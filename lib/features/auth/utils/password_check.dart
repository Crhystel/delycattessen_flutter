import 'password_policy.dart';

/// Problem found in a new password, with the texts ready to show the user.
class PasswordIssue {
  const PasswordIssue({required this.title, required this.message});

  final String title;
  final String message;
}

/// Single check for every place where the user sets a password (change,
/// recovery, registration). Returns null when [password] is valid and, if
/// [confirmation] is given, both match.
PasswordIssue? checkNewPassword(String password, {String? confirmation}) {
  if (!PasswordPolicy.isValid(password)) {
    return PasswordIssue(
      title: 'Contraseña insegura',
      message:
          'A tu contraseña le falta:\n${PasswordPolicy.missingSummary(password)}',
    );
  }
  if (confirmation != null && confirmation != password) {
    return const PasswordIssue(
      title: 'Las contraseñas no coinciden',
      message: 'Verifica que ambas contraseñas sean iguales.',
    );
  }
  return null;
}
