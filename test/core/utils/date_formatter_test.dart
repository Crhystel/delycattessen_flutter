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
}
