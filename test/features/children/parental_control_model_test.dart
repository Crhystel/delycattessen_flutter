import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParentalControl', () {
    test('reads the low balance alert when the backend sends it', () {
      final control = ParentalControl.fromJson({
        'daily_limit_enabled': true,
        'daily_limit_amount': '5.00',
        'allowed_days_enabled': true,
        'allowed_days': [0, 2],
        'low_balance_alert_enabled': true,
        'low_balance_alert_amount': '3.50',
      });

      expect(control.dailyLimitAmount, 5.0);
      expect(control.allowedDays, [0, 2]);
      expect(control.lowBalanceAlertEnabled, isTrue);
      expect(control.lowBalanceAlertAmount, 3.5);
    });

    test('works with a backend that does not send the alert yet', () {
      final control = ParentalControl.fromJson({
        'daily_limit_enabled': false,
        'daily_limit_amount': '0.00',
        'allowed_days_enabled': false,
        'allowed_days': <int>[],
      });

      expect(control.lowBalanceAlertEnabled, isFalse);
      expect(
        control.lowBalanceAlertAmount,
        ParentalControl.defaultLowBalanceAlertAmount,
      );
    });

    test('toJson sends every field back', () {
      final json = ParentalControl(
        dailyLimitEnabled: true,
        dailyLimitAmount: 4,
        allowedDaysEnabled: false,
        allowedDays: const [1],
        lowBalanceAlertEnabled: true,
        lowBalanceAlertAmount: 2.5,
      ).toJson();

      expect(json['low_balance_alert_enabled'], isTrue);
      expect(json['low_balance_alert_amount'], 2.5);
      expect(json['daily_limit_amount'], 4);
      expect(json['allowed_days'], [1]);
    });
  });
}
