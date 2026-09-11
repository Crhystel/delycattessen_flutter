class ParentalControl {
  final bool dailyLimitEnabled;
  final double dailyLimitAmount;
  final bool allowedDaysEnabled;
  final List<int> allowedDays;

  ParentalControl({
    required this.dailyLimitEnabled,
    required this.dailyLimitAmount,
    required this.allowedDaysEnabled,
    required this.allowedDays,
  });

  factory ParentalControl.fromJson(Map<String, dynamic> json) {
    return ParentalControl(
      dailyLimitEnabled: json['daily_limit_enabled'] ?? false,
      dailyLimitAmount: double.parse((json['daily_limit_amount'] ?? 0.0).toString()),
      allowedDaysEnabled: json['allowed_days_enabled'] ?? false,
      allowedDays: List<int>.from(json['allowed_days'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit_enabled': dailyLimitEnabled,
      'daily_limit_amount': dailyLimitAmount,
      'allowed_days_enabled': allowedDaysEnabled,
      'allowed_days': allowedDays,
    };
  }
}
