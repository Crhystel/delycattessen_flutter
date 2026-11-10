import 'package:delycattessen_flutter/features/pos/models/pos_identification_model.dart';
import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/utils/payment_method_policy.dart';
import 'package:flutter_test/flutter_test.dart';

IdentifiedUser _user(String role) => IdentifiedUser(
  userId: 1,
  username: 'user',
  fullName: 'Test User',
  role: role,
  roleDisplay: role,
  balance: 0,
  allergies: const [],
  pendingOrders: const [],
  identificationMethod: 'QR',
);

List<PaymentMethod> _methods(IdentifiedUser? user) => [
  for (final option in PaymentMethodPolicy.availableFor(user)) option.method,
];

void main() {
  group('PaymentMethodPolicy.availableFor', () {
    test('quick sale (no user) offers only cash', () {
      expect(_methods(null), [PaymentMethod.cash]);
    });

    test('student can pay with wallet or cash, not credit', () {
      final methods = _methods(_user('STUDENT'));
      expect(methods, contains(PaymentMethod.wallet));
      expect(methods, contains(PaymentMethod.cash));
      expect(methods, isNot(contains(PaymentMethod.credit)));
    });

    test('teacher can pay with credit or cash, not wallet', () {
      final methods = _methods(_user('TEACHER'));
      expect(methods, contains(PaymentMethod.credit));
      expect(methods, contains(PaymentMethod.cash));
      expect(methods, isNot(contains(PaymentMethod.wallet)));
    });

    test('unknown role falls back to cash only', () {
      expect(_methods(_user('OPERATIONS_STAFF')), [PaymentMethod.cash]);
    });
  });

  group('PaymentMethodPolicy.defaultFor', () {
    test('defaults to cash for quick sale', () {
      expect(PaymentMethodPolicy.defaultFor(null), PaymentMethod.cash);
    });

    test('defaults to the customer own method when they have one', () {
      expect(
        PaymentMethodPolicy.defaultFor(_user('STUDENT')),
        PaymentMethod.wallet,
      );
      expect(
        PaymentMethodPolicy.defaultFor(_user('TEACHER')),
        PaymentMethod.credit,
      );
    });
  });

  test('optionFor returns presentation data for every payment method', () {
    for (final method in PaymentMethod.values) {
      expect(PaymentMethodPolicy.optionFor(method), isNotNull);
    }
  });
}
