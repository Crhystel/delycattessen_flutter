/// Error de una llamada al backend con un mensaje ya legible para el usuario.
/// Se distingue de otras excepciones para no depender del texto del mensaje.
class ApiException implements Exception {
  final String message;

  /// Código HTTP de la respuesta (null en fallos de red).
  final int? statusCode;

  /// Código de error del backend (p. ej. `user_inactive`), si lo envía.
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  bool get isUnauthorized => statusCode == 401;
  bool get isUserInactive =>
      code == 'user_inactive' || code == 'no_active_account';

  @override
  String toString() => message;
}
