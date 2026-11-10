import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';
import 'error_handler_mixin.dart';
import '../session/session_manager.dart';
import '../storage/token_storage.dart';

abstract class BaseApiService with ErrorHandlerMixin {
  static const _sessionExpiredMessage =
      'Tu sesión expiró. Inicia sesión de nuevo.';

  /// Tiempo máximo de una petición: sin esto una red colgada deja la pantalla
  /// cargando para siempre. El mensaje de error es el de conexión habitual.
  static const requestTimeout = Duration(seconds: 20);

  /// Las subidas de fotos tardan más en redes lentas.
  static const uploadTimeout = Duration(seconds: 60);

  /// Cliente compartido: reutiliza la conexión (y el TLS) entre peticiones en
  /// vez de abrir una nueva en cada llamada. Es sustituible en pruebas.
  static http.Client httpClient = http.Client();

  /// Renovación en curso, compartida entre peticiones simultáneas.
  static Future<void>? _refreshInFlight;

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final token = requiresAuth ? await TokenStorage.getAccessToken() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Renueva el access token con el refresh guardado. Lanza [ApiException]
  /// si el servidor lo rechaza, o un fallo de red si no hay conexión.
  Future<void> refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<void> _doRefresh() async {
    final refresh = await TokenStorage.getRefreshToken();
    if (refresh == null) {
      throw const ApiException(_sessionExpiredMessage, statusCode: 401);
    }
    final response = await performPostRequest(ApiConfig.tokenRefresh, {
      'refresh': refresh,
    }, requiresAuth: false).timeout(const Duration(seconds: 8));
    final map = response as Map<String, dynamic>;
    await TokenStorage.saveTokens(
      access: map['access'] as String,
      refresh: (map['refresh'] as String?) ?? refresh,
    );
  }

  /// Template Method: ejecuta [call] traduciendo los fallos de red; ante un
  /// 401 con sesión intenta renovar el token y reenvía UNA sola vez (el 401
  /// ocurre antes de ejecutar la vista, así que no duplica efectos). Si la
  /// cuenta está desactivada o el refresh es rechazado, cierra la sesión.
  /// Un error de red o 5xx nunca borra la sesión ni se reintenta.
  Future<dynamic> _send(
    bool requiresAuth,
    Future<dynamic> Function() call, {
    Duration timeout = requestTimeout,
  }) async {
    try {
      return await _guarded(call, timeout);
    } on ApiException catch (e) {
      if (!requiresAuth || !e.isUnauthorized) rethrow;
      return _recoverFromUnauthorized(e, call, timeout);
    }
  }

  Future<dynamic> _guarded(
    Future<dynamic> Function() call,
    Duration timeout,
  ) async {
    try {
      return await call().timeout(timeout);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      throw handleNetworkError(e);
    }
  }

  Future<dynamic> _recoverFromUnauthorized(
    ApiException original,
    Future<dynamic> Function() call,
    Duration timeout,
  ) async {
    if (original.isUserInactive) {
      await SessionManager.expire(original.message, title: 'Cuenta desactivada');
      throw original;
    }

    try {
      await refreshAccessToken();
    } on ApiException catch (refreshError) {
      await _expireFor(refreshError);
      throw original;
    } catch (e) {
      if (isNetworkFailure(e)) throw handleNetworkError(e);
      rethrow;
    }

    try {
      return await _guarded(call, timeout);
    } on ApiException catch (retryError) {
      if (retryError.isUnauthorized) await _expireFor(retryError);
      rethrow;
    }
  }

  Future<void> _expireFor(ApiException error) {
    if (error.isUserInactive) {
      return SessionManager.expire(error.message, title: 'Cuenta desactivada');
    }
    return SessionManager.expire(_sessionExpiredMessage);
  }

  Future<dynamic> performPostRequest(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _send(requiresAuth, () async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return handleResponse(response);
    });
  }

  Future<dynamic> performPutRequest(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _send(requiresAuth, () async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await httpClient.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return handleResponse(response);
    });
  }

  Future<dynamic> performPatchRequest(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _send(requiresAuth, () async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await httpClient.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return handleResponse(response);
    });
  }

  Future<dynamic> performGetRequest(String url, {bool requiresAuth = true}) {
    return _send(requiresAuth, () async {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await httpClient.get(Uri.parse(url), headers: headers);
      return handleResponse(response);
    });
  }

  Future<dynamic> performMultipartPostRequest(
    String url,
    Map<String, String> fields,
    String fileFieldName,
    String filePath, {
    bool requiresAuth = true,
  }) => _sendMultipart(
    'POST',
    url,
    fields,
    fileFieldName,
    filePath,
    requiresAuth,
  );

  Future<dynamic> performMultipartPatchRequest(
    String url,
    Map<String, String> fields,
    String fileFieldName,
    String filePath, {
    bool requiresAuth = true,
  }) => _sendMultipart(
    'PATCH',
    url,
    fields,
    fileFieldName,
    filePath,
    requiresAuth,
  );

  Future<dynamic> _sendMultipart(
    String method,
    String url,
    Map<String, String> fields,
    String fileFieldName,
    String filePath,
    bool requiresAuth,
  ) {
    return _send(requiresAuth, () async {
      final token = requiresAuth ? await TokenStorage.getAccessToken() : null;
      final request = http.MultipartRequest(method, Uri.parse(url));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );

      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return handleResponse(response);
    }, timeout: uploadTimeout);
  }
}
