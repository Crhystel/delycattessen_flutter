import 'dart:convert';
import 'package:http/http.dart' as http;
import 'error_handler_mixin.dart';
import '../storage/token_storage.dart';

abstract class BaseApiService with ErrorHandlerMixin {
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final token = requiresAuth ? await TokenStorage.getAccessToken() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> performPostRequest(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow;
      }
      throw handleNetworkError(e);
    }
  }

  Future<dynamic> performPutRequest(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow;
      }
      throw handleNetworkError(e);
    }
  }

  Future<dynamic> performGetRequest(
    String url, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow;
      }
      throw handleNetworkError(e);
    }
  }

  Future<dynamic> performMultipartPostRequest(
    String url,
    Map<String, String> fields,
    String fileFieldName,
    String filePath, {
    bool requiresAuth = true,
  }) async {
    try {
      final token = requiresAuth ? await TokenStorage.getAccessToken() : null;
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return handleResponse(response);
    } catch (e) {
      if (e is Exception && !e.toString().contains('Error de conexión')) {
        rethrow;
      }
      throw handleNetworkError(e);
    }
  }
}
