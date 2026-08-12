import 'dart:convert';
import 'package:http/http.dart' as http;

/// Mixin pattern: centralizes HTTP error handling and response decoding.
/// Service classes will use `with ErrorHandlerMixin`.
mixin ErrorHandlerMixin {
  /// Processes the HTTP response. Returns the decoded body if successful (200-299),
  /// or throws a detailed exception otherwise.
  dynamic handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      // Try to decode the error message coming from Django
      String errorMessage = 'Error desconocido en el servidor';
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError is Map && decodedError.containsKey('mensaje')) {
          errorMessage = decodedError['mensaje'];
        } else if (decodedError is Map && decodedError.containsKey('non_field_errors')) {
          errorMessage = decodedError['non_field_errors'][0];
        } else if (decodedError is Map) {
          // If Django returns per-field errors (e.g.: {"email": ["Ya existe"]})
          errorMessage = decodedError.values.first.toString();
        }
      } catch (e) {
        // Fallback if the response is not valid JSON
        errorMessage = 'Error $statusCode: ${response.reasonPhrase}';
      }

      throw Exception(errorMessage);
    }
  }

  /// Processes network errors (SocketException, etc.) or internal errors during the request.
  Exception handleNetworkError(dynamic error) {
    return Exception('Error de conexión: Por favor revisa tu internet o la configuración del servidor. Detalles: $error');
  }
}
