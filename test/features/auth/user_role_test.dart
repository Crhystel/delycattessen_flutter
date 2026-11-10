import 'package:delycattessen_flutter/features/auth/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.fromApi', () {
    test('resolves every known role by its api value', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromApi(role.apiValue), role);
      }
    });

    test('returns null for roles the app does not distinguish', () {
      expect(UserRole.fromApi('PARENT'), isNull);
      expect(UserRole.fromApi(null), isNull);
    });
  });
}
