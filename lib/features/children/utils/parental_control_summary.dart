import '../models/parental_control_model.dart';
import 'parental_weekdays.dart';

/// Resúmenes de una línea del control parental para la ficha y para el menú de
/// "Datos del hijo". Reglas puras: la pantalla solo las pinta.
class ParentalControlSummary {
  ParentalControlSummary._();

  /// Texto mientras el control aún no se carga (o no está disponible).
  static const String placeholder = 'Límite diario y días permitidos';

  static const String noRestrictions = 'Sin restricciones';

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  /// Lo que está activo, p. ej. "Límite $5.00/día · Lun, Mié · Aviso bajo $2.00".
  static String detailed(ParentalControl? control) {
    if (control == null) return placeholder;

    final parts = <String>[];
    if (control.dailyLimitEnabled) {
      parts.add('Límite ${_money(control.dailyLimitAmount)}/día');
    }
    if (control.allowedDaysEnabled) {
      final days = ([...control.allowedDays]..sort())
          .where((d) => d >= 0 && d < ParentalWeekday.all.length)
          .map((d) => ParentalWeekday.all[d].short)
          .toList();
      parts.add(days.isEmpty ? 'Ningún día permitido' : days.join(', '));
    }
    if (control.lowBalanceAlertEnabled) {
      parts.add('Aviso bajo ${_money(control.lowBalanceAlertAmount)}');
    }
    return parts.isEmpty ? noRestrictions : parts.join(' · ');
  }

  /// Versión corta de "Datos del hijo": "Límite $1.00/día · aviso bajo $2.00".
  /// Si no hay límite ni aviso, cae en los días permitidos o en "Sin
  /// restricciones".
  static String brief(ParentalControl? control) {
    if (control == null) return placeholder;

    final parts = <String>[];
    if (control.dailyLimitEnabled) {
      parts.add('Límite ${_money(control.dailyLimitAmount)}/día');
    }
    if (control.lowBalanceAlertEnabled) {
      parts.add('aviso bajo ${_money(control.lowBalanceAlertAmount)}');
    }
    if (parts.isEmpty && control.allowedDaysEnabled) {
      return detailed(control);
    }
    return parts.isEmpty ? noRestrictions : parts.join(' · ');
  }
}
