/// Error de una llamada al backend con un mensaje ya legible para el usuario.
/// Se distingue de otras excepciones para no depender del texto del mensaje.
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
