import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      debugPrint(
        '--- HTTP ERROR ---\n'
        'URL: ${response.request?.url}\n'
        'Status: $statusCode\n'
        'Headers: ${response.headers}\n'
        'Body: ${response.body}\n'
        '------------------',
      );

      String errorMessage = 'Error desconocido en el servidor';
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError is List && decodedError.isNotEmpty) {
          // DRF envuelve un ValidationError('texto') lanzado directo en una
          // vista (no desde un serializer) como un array JSON plano.
          errorMessage = decodedError.first.toString();
        } else if (decodedError is Map && decodedError.containsKey('mensaje')) {
          errorMessage = decodedError['mensaje'];
        } else if (decodedError is Map && decodedError.containsKey('detail')) {
          errorMessage = decodedError['detail'].toString();
        } else if (decodedError is Map &&
            decodedError.containsKey('non_field_errors')) {
          final nfe = decodedError['non_field_errors'];
          errorMessage = (nfe is List && nfe.isNotEmpty)
              ? nfe.first.toString()
              : nfe.toString();
        } else if (decodedError is Map && decodedError.isNotEmpty) {
          // Errores por campo, ej. {"ingredients": ["mensaje"]}
          final firstValue = decodedError.values.first;
          errorMessage = (firstValue is List && firstValue.isNotEmpty)
              ? firstValue.first.toString()
              : firstValue.toString();
        }
      } catch (e) {
        errorMessage = 'Error $statusCode: ${response.reasonPhrase}';
      }

      throw Exception(errorMessage);
    }
  }

  /// Processes network errors (SocketException, etc.) or internal errors during the request.
  Exception handleNetworkError(dynamic error) {
    return Exception(
      'Error de conexión: Por favor revisa tu internet o la configuración del servidor. Detalles: $error',
    );
  }
}
