import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:delycattessen_flutter/features/children/utils/allergy_summary.dart';
import 'package:delycattessen_flutter/features/children/utils/parental_control_summary.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:flutter_test/flutter_test.dart';

ParentalControl _control({
  bool limit = false,
  double limitAmount = 5,
  bool days = false,
  List<int> allowed = const [],
  bool alert = false,
  double alertAmount = 2,
}) => ParentalControl(
  dailyLimitEnabled: limit,
  dailyLimitAmount: limitAmount,
  allowedDaysEnabled: days,
  allowedDays: allowed,
  lowBalanceAlertEnabled: alert,
  lowBalanceAlertAmount: alertAmount,
);

void main() {
  group('ParentalControlSummary.brief', () {
    test('limit and alert as in the design', () {
      final text = ParentalControlSummary.brief(
        _control(limit: true, limitAmount: 1, alert: true),
      );
      expect(text, 'Límite \$1.00/día · aviso bajo \$2.00');
    });

    test('only the limit', () {
      expect(
        ParentalControlSummary.brief(_control(limit: true, limitAmount: 3.5)),
        'Límite \$3.50/día',
      );
    });

    test('falls back to the allowed days, then to "Sin restricciones"', () {
      expect(
        ParentalControlSummary.brief(_control(days: true, allowed: [2, 0])),
        'Lun, Mié',
      );
      expect(
        ParentalControlSummary.brief(_control()),
        ParentalControlSummary.noRestrictions,
      );
    });

    test('generic text while the control is not loaded', () {
      expect(
        ParentalControlSummary.brief(null),
        ParentalControlSummary.placeholder,
      );
    });
  });

  group('ParentalControlSummary.detailed', () {
    test('lists limit, sorted days and alert', () {
      final text = ParentalControlSummary.detailed(
        _control(
          limit: true,
          days: true,
          allowed: [2, 0],
          alert: true,
          alertAmount: 4,
        ),
      );
      expect(text, 'Límite \$5.00/día · Lun, Mié · Aviso bajo \$4.00');
    });

    test('enabled days with none selected', () {
      expect(
        ParentalControlSummary.detailed(_control(days: true)),
        'Ningún día permitido',
      );
    });
  });

  group('AllergySummary', () {
    test('joins names, or explains the empty and loading states', () {
      expect(
        AllergySummary.of([
          Allergen(id: 1, name: 'Sulfitos'),
          Allergen(id: 2, name: 'Sésamo'),
        ]),
        'Sulfitos, Sésamo',
      );
      expect(AllergySummary.of(const []), AllergySummary.none);
      expect(AllergySummary.of(null), AllergySummary.placeholder);
    });
  });
}
