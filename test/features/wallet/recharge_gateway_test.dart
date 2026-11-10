import 'package:delycattessen_flutter/features/wallet/models/recharge_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RechargeGateway.fromApi', () {
    test('resolves every known gateway by its api value', () {
      for (final gateway in RechargeGateway.values) {
        expect(RechargeGateway.fromApi(gateway.apiValue), gateway);
      }
    });

    test('returns null for an unknown gateway', () {
      expect(RechargeGateway.fromApi('stripe'), isNull);
    });

    test('returns null when the server sends nothing', () {
      expect(RechargeGateway.fromApi(null), isNull);
      expect(RechargeGateway.fromApi(''), isNull);
    });
  });
}
