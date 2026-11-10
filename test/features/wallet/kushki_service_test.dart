import 'dart:convert';

import 'package:delycattessen_flutter/features/wallet/services/card_tokenizer.dart';
import 'package:delycattessen_flutter/features/wallet/services/kushki_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<String> _tokenize(CardTokenizer tokenizer) => tokenizer.tokenizeCard(
  cardNumber: '4111 1111 1111 1111',
  cvv: '123',
  expiryMonth: '12',
  expiryYear: '30',
  holderName: 'Test User',
  amount: 5,
);

void main() {
  group('KushkiService.tokenizeCard', () {
    test('returns the token and sends the card without spaces', () async {
      late Map<String, dynamic> sentBody;
      final service = KushkiService(
        client: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'token': 'tok_123'}), 201);
        }),
      );

      expect(await _tokenize(service), 'tok_123');
      expect(sentBody['card']['number'], '4111111111111111');
      expect(sentBody['totalAmount'], 5);
    });

    test('throws the gateway message when the card is rejected', () async {
      final service = KushkiService(
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Tarjeta inválida'}), 400),
        ),
      );

      expect(
        _tokenize(service),
        throwsA(predicate((e) => e.toString().contains('Tarjeta inválida'))),
      );
    });

    test('maps a network failure to a connection error', () async {
      final service = KushkiService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(
        _tokenize(service),
        throwsA(predicate((e) => e.toString().contains('Error de conexión'))),
      );
    });
  });
}
