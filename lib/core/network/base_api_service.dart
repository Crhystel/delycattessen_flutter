import 'package:http/http.dart' as http;
import 'dart:convert';
import 'error_handler_mixin.dart';

/// Template Method pattern: this abstract class defines the skeleton of HTTP requests.
/// Implements [ErrorHandlerMixin] to get robust error handling automatically.
abstract class BaseApiService with ErrorHandlerMixin {
  /// Returns the default headers (conceptual Permission Class equivalent for injection).
  /// In the future, the JWT token retrieved from SecureStorage can be injected here.
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer $_token', // Future implementation
  };

  /// Template Method: defines the skeleton of a POST request.
  /// Takes the URL and body (converted to JSON), performs the request,
  /// and delegates success/error handling to the Mixin.
  Future<dynamic> performPostRequest(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );

      // The Mixin is responsible for throwing an exception or returning the decoded data
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow; // Re-throw if it's an API exception (already parsed by the mixin)
      }
      throw handleNetworkError(
        e,
      ); // Handle pure connection failures (no internet, server down)
    }
  }

  Future<dynamic> performGetRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: defaultHeaders);
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow;
      }
      throw handleNetworkError(e);
    }
  }
}
