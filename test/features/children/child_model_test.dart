import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child({
  double? balance,
  double? alert,
  String first = 'Pepito',
  String last = 'Pérez',
}) => Child(
  id: 1,
  firstName: first,
  lastName: last,
  institutionName: 'Martín Cerere',
  balance: balance,
  lowBalanceAlertAmount: alert,
);

void main() {
  group('Child names', () {
    test('shows name and first surname, and their initials', () {
      final child = _child();

      expect(child.displayName, 'Pepito Pérez');
      expect(child.initials, 'PP');
    });

    test('initials survive a missing surname', () {
      expect(_child(last: '').initials, 'P');
    });
  });

  group('Child.hasLowBalance', () {
    test('uses the fixed threshold when the parent set no alert', () {
      expect(_child(balance: 4.99).hasLowBalance, isTrue);
      expect(_child(balance: 5).hasLowBalance, isFalse);
    });

    test('uses the amount the parent configured', () {
      expect(_child(balance: 1.5, alert: 2).hasLowBalance, isTrue);
      expect(_child(balance: 2.5, alert: 2).hasLowBalance, isFalse);
    });

    test('a child without a wallet balance is not flagged', () {
      expect(_child().hasLowBalance, isFalse);
    });
  });

  test('fromJson reads the low balance alert and tolerates its absence', () {
    final base = {
      'id': 3,
      'first_name': 'Ana',
      'last_name': 'Mora',
      'institution_name': 'Sauce',
      'balance': '9.00',
    };

    expect(Child.fromJson(base).lowBalanceAlertAmount, isNull);
    expect(
      Child.fromJson({
        ...base,
        'low_balance_alert_amount': '3.00',
      }).lowBalanceAlertAmount,
      3.0,
    );
  });
}
