class PasswordRule {
  const PasswordRule(this.label, this.test);

  final String label;
  final bool Function(String password) test;
}

/// Política única de contraseñas. Debe coincidir con
/// `users.validators.PasswordPolicyValidator` del backend.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static final List<PasswordRule> rules = [
    PasswordRule(
      'Mínimo $minLength caracteres',
      (p) => p.runes.length >= minLength,
    ),
    PasswordRule(
      'Al menos una letra mayúscula',
      (p) => p.contains(RegExp(r'[A-Z]')),
    ),
    PasswordRule(
      'Al menos una letra minúscula',
      (p) => p.contains(RegExp(r'[a-z]')),
    ),
    PasswordRule('Al menos un número', (p) => p.contains(RegExp(r'[0-9]'))),
    PasswordRule(
      r'Al menos un carácter especial (ej. ! @ # $ %)',
      (p) => p.contains(RegExp(r'[^A-Za-z0-9]')),
    ),
  ];

  /// Etiquetas de los requisitos que la contraseña NO cumple.
  static List<String> missing(String password) =>
      rules.where((r) => !r.test(password)).map((r) => r.label).toList();

  static bool isValid(String password) => missing(password).isEmpty;

  /// Lista con viñetas de los requisitos faltantes, para mostrar al usuario.
  static String missingSummary(String password) =>
      missing(password).map((label) => '• $label').join('\n');
}
