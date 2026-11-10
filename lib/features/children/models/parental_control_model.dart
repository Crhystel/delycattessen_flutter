class ParentalControl {
  /// Monto por defecto del aviso de saldo bajo (el mismo que el backend).
  static const double defaultLowBalanceAlertAmount = 2.0;

  final bool dailyLimitEnabled;
  final double dailyLimitAmount;
  final bool allowedDaysEnabled;
  final List<int> allowedDays;

  /// Aviso de saldo bajo: se avisa al padre cuando el saldo baja de este monto.
  final bool lowBalanceAlertEnabled;
  final double lowBalanceAlertAmount;

  ParentalControl({
    required this.dailyLimitEnabled,
    required this.dailyLimitAmount,
    required this.allowedDaysEnabled,
    required this.allowedDays,
    this.lowBalanceAlertEnabled = false,
    this.lowBalanceAlertAmount = defaultLowBalanceAlertAmount,
  });

  /// Tolera que el backend aún no envíe los campos del aviso de saldo bajo.
  factory ParentalControl.fromJson(Map<String, dynamic> json) {
    return ParentalControl(
      dailyLimitEnabled: json['daily_limit_enabled'] ?? false,
      dailyLimitAmount: double.parse(
        (json['daily_limit_amount'] ?? 0.0).toString(),
      ),
      allowedDaysEnabled: json['allowed_days_enabled'] ?? false,
      allowedDays: List<int>.from(json['allowed_days'] ?? []),
      lowBalanceAlertEnabled: json['low_balance_alert_enabled'] ?? false,
      lowBalanceAlertAmount:
          double.tryParse(
            (json['low_balance_alert_amount'] ?? '').toString(),
          ) ??
          defaultLowBalanceAlertAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit_enabled': dailyLimitEnabled,
      'daily_limit_amount': dailyLimitAmount,
      'allowed_days_enabled': allowedDaysEnabled,
      'allowed_days': allowedDays,
      'low_balance_alert_enabled': lowBalanceAlertEnabled,
      'low_balance_alert_amount': lowBalanceAlertAmount,
    };
  }
}
