import '../network/api_exception.dart';

/// Mensaje de [error] listo para mostrar al usuario. Las excepciones del
/// backend ya traen su mensaje; en el resto se quita el prefijo "Exception: ".
String errorMessageOf(Object error) {
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
