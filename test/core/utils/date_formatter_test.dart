import 'package:delycattessen_flutter/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter.formatGreetingDate', () {
    test('has a comma and a capital letter: "Martes, 10 de noviembre"', () {
      expect(
        DateFormatter.formatGreetingDate(DateTime(2026, 11, 10)),
        'Martes, 10 de noviembre',
      );
    });

    test('works for the first day of the month and for Sunday', () {
      expect(
        DateFormatter.formatGreetingDate(DateTime(2026, 11, 1)),
        'Domingo, 1 de noviembre',
      );
    });

    test('formatLongCapitalized keeps its format (no comma)', () {
      expect(
        DateFormatter.formatLongCapitalized(DateTime(2026, 11, 10)),
        'Martes 10 de noviembre',
      );
    });
  });

  group('detail page dates', () {
    test('formatWeekdayShortMonth: "Martes 10 nov"', () {
      expect(
        DateFormatter.formatWeekdayShortMonth(DateTime(2026, 11, 10)),
        'Martes 10 nov',
      );
    });

    test('formatWeekdayShortMonth: accents and month change', () {
      expect(
        DateFormatter.formatWeekdayShortMonth(DateTime(2026, 12, 2)),
        'Miércoles 2 dic',
      );
      expect(
        DateFormatter.formatWeekdayShortMonth(DateTime(2026, 8, 1)),
        'Sábado 1 ago',
      );
    });

    test('formatChip is the short form: "Lun 9 nov"', () {
      expect(DateFormatter.formatChip(DateTime(2026, 11, 9)), 'Lun 9 nov');
    });

    test('the day before a service day crosses the month', () {
      final served = DateTime(2026, 12, 1);
      expect(
        DateFormatter.formatChip(served.subtract(const Duration(days: 1))),
        'Lun 30 nov',
      );
    });
  });
}
