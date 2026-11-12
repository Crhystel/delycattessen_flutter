import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/base_api_service.dart';
import '../../../core/network/error_handler_mixin.dart';
import 'card_tokenizer.dart';

/// Tokenizes card data directly with Kushki — the card number never
/// touches our own backend, only the resulting token does.
///
/// No extiende `BaseApiService` a propósito: ese servicio agrega el JWT del
/// backend y sus headers, y aquí la llamada va a un tercero con otros
/// headers. Reutiliza [ErrorHandlerMixin] para el error de conexión.
class KushkiService with ErrorHandlerMixin implements CardTokenizer {
  KushkiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> tokenizeCard({
    required String cardNumber,
    required String cvv,
    required String expiryMonth,
    required String expiryYear,
    required String holderName,
    required double amount,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.kushkiCardTokens),
            headers: {
              'Public-Merchant-Id': Env.kushkiPublicMerchantId,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'card': {
                'name': holderName,
                'number': cardNumber.replaceAll(' ', ''),
                'cvv': cvv,
                'expiryMonth': expiryMonth,
                'expiryYear': expiryYear,
              },
              'totalAmount': amount,
              'currency': 'USD',
            }),
          )
          .timeout(BaseApiService.requestTimeout);
    } catch (e) {
      if (isNetworkFailure(e)) throw handleNetworkError(e);
      rethrow;
    }

    final data = _decodeBody(response.body);
    if (response.statusCode != 201 || data['token'] == null) {
      throw ApiException(
        data['message'] as String? ?? 'No se pudo procesar la tarjeta.',
        statusCode: response.statusCode,
      );
    }
    return data['token'] as String;
  }

  /// Kushki can answer with a non-JSON body (gateway errors, HTML pages).
  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Falls through to the empty map: the caller reports a readable error.
    }
    return const {};
  }
}
