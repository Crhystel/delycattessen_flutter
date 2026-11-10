class Env {
  /// Base de la API del backend. Sin definirla apunta al servidor local;
  /// para otro entorno: `--dart-define=API_BASE_URL=https://.../api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const String kushkiPublicMerchantId = String.fromEnvironment(
    'KUSHKI_PUBLIC_MERCHANT_ID',
  );

  /// Base de la API de tokenización de Kushki (UAT o producción según el build).
  static const String kushkiBaseUrl = String.fromEnvironment('KUSHKI_BASE_URL');
}
