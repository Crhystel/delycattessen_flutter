import 'dart:convert';

import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/core/network/base_api_service.dart';
import 'package:delycattessen_flutter/core/storage/token_storage.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _change = ChildPasswordChange(
  parentPassword: 'Parent-Passw0rd!',
  newPassword: 'New-Passw0rd!',
  confirmPassword: 'New-Passw0rd!',
);

Future<http.Request?> _send(http.Response Function(http.Request) answer) async {
  http.Request? seen;
  final original = BaseApiService.httpClient;
  BaseApiService.httpClient = MockClient((request) async {
    seen = request;
    return answer(request);
  });
  try {
    await AuthService().changeChildPassword(3, _change);
  } finally {
    BaseApiService.httpClient = original;
  }
  return seen;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'parent-access',
      'refresh_token': 'parent-refresh',
    });
  });

  group('AuthService.changeChildPassword', () {
    test('posts the confirmation and the new password to the child', () async {
      final request = await _send(
        (_) => http.Response(jsonEncode({'message': 'ok'}), 200),
      );

      expect(request!.method, 'POST');
      expect(request.url.path, endsWith('/users/children/3/password/'));
      expect(jsonDecode(request.body), {
        'parent_password': 'Parent-Passw0rd!',
        'new_password': 'New-Passw0rd!',
        'confirm_password': 'New-Passw0rd!',
      });
    });

    test('keeps the parent session untouched', () async {
      await _send((_) => http.Response(jsonEncode({'message': 'ok'}), 200));

      expect(await TokenStorage.getAccessToken(), 'parent-access');
      expect(await TokenStorage.getRefreshToken(), 'parent-refresh');
    });

    test('a wrong confirmation is an error and keeps the session', () async {
      await expectLater(
        _send(
          (_) => http.Response(
            jsonEncode({
              'parent_password': ['Tu contraseña es incorrecta.'],
            }),
            400,
          ),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(await TokenStorage.getAccessToken(), 'parent-access');
    });
  });
}
