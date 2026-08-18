import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';

/// Tokenizes card data directly with Kushki — the card number never
/// touches our own backend, only the resulting token does.
class KushkiService {
  static const _baseUrl = 'https://api-uat.kushkipagos.com';

  Future<String> tokenizeCard({
    required String cardNumber,
    required String cvv,
    required String expiryMonth,
    required String expiryYear,
    required String holderName,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/card/v1/tokens'),
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
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 || data['token'] == null) {
      throw Exception(
        data['message'] as String? ?? 'No se pudo procesar la tarjeta.',
      );
    }
    return data['token'] as String;
  }
}
