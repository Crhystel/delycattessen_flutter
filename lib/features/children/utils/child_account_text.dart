import '../../auth/models/auth_models.dart';

/// Textos de resumen de la cuenta del hijo para las filas de "Datos del hijo".
extension ChildAccountText on Child {
  /// Los cuatro nombres juntos, sin huecos: "Pepito Alejandro Pérez Pérez".
  String get fullName => [
    firstName,
    secondName,
    lastName,
    secondLastName,
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

  /// "pepito123 · con este inicia sesión" (o solo la explicación si aún no
  /// tiene usuario).
  String get usernameSummary => username.trim().isEmpty
      ? 'Con este usuario inicia sesión'
      : '${username.trim()} · con este inicia sesión';
}
