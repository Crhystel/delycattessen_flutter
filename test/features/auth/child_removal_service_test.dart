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

Future<T> _with<T>(
  http.Response Function(http.Request) answer,
  Future<T> Function(AuthService) call, {
  void Function(http.Request)? onRequest,
}) async {
  final original = BaseApiService.httpClient;
  BaseApiService.httpClient = MockClient((request) async {
    onRequest?.call(request);
    return answer(request);
  });
  try {
    return await call(AuthService());
  } finally {
    BaseApiService.httpClient = original;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'parent-access',
      'refresh_token': 'parent-refresh',
    });
  });

  group('ChildRemovalCheck.fromJson', () {
    test('reads the reasons that block the removal', () {
      final check = ChildRemovalCheck.fromJson({
        'can_remove': false,
        'blockers': {
          'balance': '2.50',
          'pending_pre_orders': 2,
          'pending_recharges': 1,
        },
      });

      expect(check.canRemove, isFalse);
      expect(check.balance, 2.5);
      expect(check.pendingPreOrders, 2);
      expect(check.pendingRecharges, 1);
    });

    test('no blockers means it can be removed', () {
      final check = ChildRemovalCheck.fromJson({
        'can_remove': true,
        'blockers': <String, dynamic>{},
      });

      expect(check.canRemove, isTrue);
      expect(check.balance, isNull);
      expect(check.pendingPreOrders, 0);
      expect(check.pendingRecharges, 0);
    });
  });

  group('AuthService.getChildRemovalCheck', () {
    test('asks the backend about that child', () async {
      http.Request? seen;
      final check = await _with(
        (_) => http.Response(
          jsonEncode({
            'can_remove': false,
            'blockers': {'balance': '1.00'},
          }),
          200,
        ),
        (service) => service.getChildRemovalCheck(3),
        onRequest: (request) => seen = request,
      );

      expect(seen!.method, 'GET');
      expect(seen!.url.path, endsWith('/users/children/3/removal-check/'));
      expect(check.balance, 1.0);
    });
  });

  group('AuthService.removeChild', () {
    test('posts the parent password to the child', () async {
      http.Request? seen;
      await _with(
        (_) => http.Response(jsonEncode({'message': 'ok'}), 200),
        (service) => service.removeChild(3, 'Parent-Passw0rd!'),
        onRequest: (request) => seen = request,
      );

      expect(seen!.method, 'POST');
      expect(seen!.url.path, endsWith('/users/children/3/remove/'));
      expect(jsonDecode(seen!.body), {'parent_password': 'Parent-Passw0rd!'});
    });

    test('a blocked removal keeps the reason and its code', () async {
      await expectLater(
        _with(
          (_) => http.Response(
            jsonEncode({
              'detail':
                  'No se puede dar de baja a tu hijo/a: todavía tiene saldo.',
              'code': 'child_removal_blocked',
              'blockers': {'balance': '1.00'},
            }),
            409,
          ),
          (service) => service.removeChild(3, 'Parent-Passw0rd!'),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.code, 'code', 'child_removal_blocked')
              .having((e) => e.message, 'message', contains('saldo')),
        ),
      );
    });

    test('a wrong password keeps the parent session', () async {
      await expectLater(
        _with(
          (_) => http.Response(
            jsonEncode({
              'parent_password': ['Tu contraseña es incorrecta.'],
            }),
            400,
          ),
          (service) => service.removeChild(3, 'mala'),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(await TokenStorage.getAccessToken(), 'parent-access');
      expect(await TokenStorage.getRefreshToken(), 'parent-refresh');
    });
  });
}
