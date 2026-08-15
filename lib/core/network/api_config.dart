class ApiConfig {
  // Requiere celular conectado por USB con:
  //   adb reverse tcp:8000 tcp:8000
  // Se usa localhost en vez de la IP de Wi-Fi porque el router bloquea la
  // comunicación directa celular-PC en esta red (aislamiento de clientes).
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const String login = '$baseUrl/users/login/';
  static const String institutions = '$baseUrl/users/institutions/';
  static const String requestPasswordReset =
      '$baseUrl/users/password-reset/request/';
  static const String confirmPasswordReset =
      '$baseUrl/users/password-reset/confirm/';
  static const String registerParent = '$baseUrl/users/parent-registration/';
  static const String registerStudent = '$baseUrl/users/student-registration/';

  static const String walletRecharge = '$baseUrl/wallet/recharge/';
  static String walletTransactions(int walletId) =>
      '$baseUrl/wallet/$walletId/transactions/';
  static const String me = '$baseUrl/users/me/';
}
