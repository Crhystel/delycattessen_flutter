import 'package:http/http.dart' as http;
import 'dart:convert';
import 'error_handler_mixin.dart';

/// Patrón Template Method: Esta clase abstracta define el esqueleto de las peticiones HTTP.
/// Implementa [ErrorHandlerMixin] para obtener el manejo robusto de errores de forma automática.
abstract class BaseApiService with ErrorHandlerMixin {
  /// Retorna los headers por defecto (Permission Class equivalente conceptual para inyección).
  /// En el futuro, aquí se puede inyectar el token JWT recuperado de SecureStorage.
  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'Authorization': 'Bearer $_token', // Future implementation
      };

  /// Template Method: Define el esqueleto de una petición POST.
  /// Toma la URL y el body (convertido a JSON), realiza la petición,
  /// y delega el manejo de éxito/error al Mixin.
  Future<dynamic> performPostRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );
      
      // El Mixin se encarga de lanzar excepción o devolver los datos decodificados
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow; // Re-lanzar si es una excepción de la API (ya parseada por el mixin)
      }
      throw handleNetworkError(e); // Manejar fallos de conexión pura (sin internet, servidor caído)
    }
  }
}
