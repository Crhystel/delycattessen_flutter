import 'dart:convert';

import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/core/storage/token_storage.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _request = ChangePasswordRequest(
  currentPassword: 'Old-Passw0rd!',
  newPassword: 'New-Passw0rd!',
  confirmPassword: 'New-Passw0rd!',
);

Future<void> _change(http.Response Function(http.Request) answer) {
  return http.runWithClient(
    () => AuthService().changePassword(_request),
    () => MockClient((request) async => answer(request)),
  );
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
    });
  });

  group('AuthService.changePassword', () {
    test('keeps the session of this device with the new tokens', () async {
      await _change(
        (_) => http.Response(
          jsonEncode({
            'message': 'ok',
            'access': 'new-access',
            'refresh': 'new-refresh',
          }),
          200,
        ),
      );

      expect(await TokenStorage.getAccessToken(), 'new-access');
      expect(await TokenStorage.getRefreshToken(), 'new-refresh');
    });

    test('keeps the stored tokens when the response has none', () async {
      await _change((_) => http.Response(jsonEncode({'message': 'ok'}), 200));

      expect(await TokenStorage.getAccessToken(), 'old-access');
      expect(await TokenStorage.getRefreshToken(), 'old-refresh');
    });

    test('does not touch the tokens when the backend rejects it', () async {
      await expectLater(
        _change(
          (_) => http.Response(
            jsonEncode({'detail': 'La contraseña actual es incorrecta.'}),
            400,
          ),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(await TokenStorage.getAccessToken(), 'old-access');
    });
  });
}
