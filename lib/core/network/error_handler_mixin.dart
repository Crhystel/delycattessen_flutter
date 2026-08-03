import 'dart:convert';
import 'package:http/http.dart' as http;

/// Patrón Mixin: Centraliza el manejo de errores HTTP y la decodificación de respuestas.
/// Las clases de servicio (Services) utilizarán `with ErrorHandlerMixin`.
mixin ErrorHandlerMixin {
  /// Procesa la respuesta HTTP. Retorna el cuerpo decodificado si es exitosa (200-299),
  /// o lanza una excepción detallada en caso contrario.
  dynamic handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      // Intenta decodificar el mensaje de error que viene desde Django
      String errorMessage = 'Error desconocido en el servidor';
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError is Map && decodedError.containsKey('mensaje')) {
          errorMessage = decodedError['mensaje'];
        } else if (decodedError is Map && decodedError.containsKey('non_field_errors')) {
          errorMessage = decodedError['non_field_errors'][0];
        } else if (decodedError is Map) {
          // Si Django devuelve errores por campo (ej: {"email": ["Ya existe"]})
          errorMessage = decodedError.values.first.toString();
        }
      } catch (e) {
        // Fallback si la respuesta no es JSON válido
        errorMessage = 'Error $statusCode: ${response.reasonPhrase}';
      }

      throw Exception(errorMessage);
    }
  }

  /// Procesa errores de red (SocketException, etc.) o errores internos durante la petición.
  Exception handleNetworkError(dynamic error) {
    return Exception('Error de conexión: Por favor revisa tu internet o la configuración del servidor. Detalles: $error');
  }
}
