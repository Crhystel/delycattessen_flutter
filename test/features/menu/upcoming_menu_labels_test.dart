import 'package:delycattessen_flutter/features/menu/utils/upcoming_menu_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 9 November 2026.
  final now = DateTime(2026, 11, 9, 18, 30);

  group('UpcomingMenuLabels', () {
    test('tomorrow is "Mañana en el menú"', () {
      final date = DateTime(2026, 11, 10);

      expect(UpcomingMenuLabels.isTomorrow(date, now), isTrue);
      expect(UpcomingMenuLabels.sectionTitle(date, now), 'Mañana en el menú');
    });

    test('any other day is "Próximo menú"', () {
      expect(
        UpcomingMenuLabels.sectionTitle(DateTime(2026, 11, 13), now),
        'Próximo menú',
      );
      // Today is not "tomorrow" either.
      expect(
        UpcomingMenuLabels.sectionTitle(DateTime(2026, 11, 9), now),
        'Próximo menú',
      );
    });

    test('tomorrow is computed across the end of the month', () {
      final lastDay = DateTime(2026, 11, 30, 23, 59);

      expect(
        UpcomingMenuLabels.isTomorrow(DateTime(2026, 12, 1), lastDay),
        isTrue,
      );
    });

    test('the date line is short when it is tomorrow', () {
      expect(
        UpcomingMenuLabels.dateLine(DateTime(2026, 11, 10), now),
        'Martes 10',
      );
    });

    test('the date line carries the month when it is not tomorrow', () {
      expect(
        UpcomingMenuLabels.dateLine(DateTime(2026, 11, 13), now),
        'Viernes 13 de noviembre',
      );
    });
  });
}
