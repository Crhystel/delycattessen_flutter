class Env {
  static const String kushkiPublicMerchantId = String.fromEnvironment(
    'KUSHKI_PUBLIC_MERCHANT_ID',
  );

  /// Base de la API de tokenización de Kushki (UAT o producción según el build).
  static const String kushkiBaseUrl = String.fromEnvironment('KUSHKI_BASE_URL');
}
