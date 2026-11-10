import '../models/auth_models.dart';
import 'password_check.dart';

/// Check for changing the email of a signed-in user: a valid address that is
/// different from [currentEmail], plus the current password (the backend asks
/// for it too, because the email is also the login). Returns null when valid.
PasswordIssue? checkEmailChange({
  required String currentEmail,
  required String newEmail,
  required String currentPassword,
}) {
  if (!ProfileUpdate.isValidEmail(newEmail)) {
    return const PasswordIssue(
      title: 'Correo inválido',
      message: 'Ingresa un correo válido.',
    );
  }
  if (newEmail.trim().toLowerCase() == currentEmail.trim().toLowerCase()) {
    return const PasswordIssue(
      title: 'Es el mismo correo',
      message: 'Escribe un correo distinto al actual.',
    );
  }
  if (currentPassword.isEmpty) {
    return const PasswordIssue(
      title: 'Datos incompletos',
      message: 'Ingresa tu contraseña actual para cambiar el correo.',
    );
  }
  return null;
}
