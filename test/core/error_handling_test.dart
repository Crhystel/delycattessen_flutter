import 'dart:async';
import 'dart:convert';

import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/core/network/error_handler_mixin.dart';
import 'package:delycattessen_flutter/core/utils/error_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _Handler with ErrorHandlerMixin {}

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status);

String _messageOf(http.Response response) {
  try {
    _Handler().handleResponse(response);
  } on ApiException catch (e) {
    return e.message;
  }
  fail('handleResponse should have thrown');
}

void main() {
  final handler = _Handler();

  group('ErrorHandlerMixin.handleResponse', () {
    test('returns the decoded body on success', () {
      expect(handler.handleResponse(_json({'ok': true}, 200)), {'ok': true});
    });

    test('returns null for an empty successful body', () {
      expect(handler.handleResponse(http.Response('', 204)), isNull);
    });

    test('reads the backend error message in each supported shape', () {
      expect(_messageOf(_json({'mensaje': 'Uno'}, 400)), 'Uno');
      expect(_messageOf(_json({'detail': 'Dos'}, 403)), 'Dos');
      expect(
        _messageOf(
          _json({
            'non_field_errors': ['Tres'],
          }, 400),
        ),
        'Tres',
      );
      expect(_messageOf(_json(['Cuatro'], 400)), 'Cuatro');
      expect(
        _messageOf(
          _json({
            'campo': ['Cinco'],
          }, 400),
        ),
        'Cinco',
      );
    });

    test('falls back to the status when the body is not JSON', () {
      expect(
        _messageOf(http.Response('<html>', 502, reasonPhrase: 'Bad Gateway')),
        'Error 502: Bad Gateway',
      );
    });
  });

  group('ErrorHandlerMixin.isNetworkFailure', () {
    test('detects connection problems', () {
      expect(handler.isNetworkFailure(http.ClientException('offline')), isTrue);
      expect(handler.isNetworkFailure(TimeoutException('slow')), isTrue);
    });

    test('does not treat backend or programming errors as network ones', () {
      expect(handler.isNetworkFailure(const ApiException('Error')), isFalse);
      expect(handler.isNetworkFailure(const FormatException('bad')), isFalse);
      expect(handler.isNetworkFailure(StateError('bug')), isFalse);
    });

    test('handleNetworkError builds a connection error message', () {
      final error = handler.handleNetworkError('boom');

      expect(error, isA<NetworkException>());
      expect(error.message, startsWith('Error de conexión'));
    });
  });

  group('errorMessageOf', () {
    test('uses the message of an ApiException', () {
      expect(errorMessageOf(const ApiException('Sin saldo')), 'Sin saldo');
    });

    test('removes the Exception prefix from plain exceptions', () {
      expect(errorMessageOf(Exception('Fallo')), 'Fallo');
    });
  });
}
