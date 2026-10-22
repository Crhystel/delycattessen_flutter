import '../config/env.dart';

class ApiConfig {
  // Por defecto es el servidor local (ver Env.apiBaseUrl). En un celular
  // conectado por USB requiere:
  //   adb reverse tcp:8000 tcp:8000
  // Se usa localhost en vez de la IP de Wi-Fi porque el router bloquea la
  // comunicación directa celular-PC en esta red (aislamiento de clientes).
  static const String baseUrl = Env.apiBaseUrl;

  static const String tokenRefresh = '$baseUrl/token/refresh/';
  static const String login = '$baseUrl/users/login/';
  static const String institutions = '$baseUrl/users/institutions/';
  static const String requestPasswordReset =
      '$baseUrl/users/password-reset/request/';
  static const String confirmPasswordReset =
      '$baseUrl/users/password-reset/confirm/';
  static const String registerParent = '$baseUrl/users/parent-registration/';
  static const String registerStudent = '$baseUrl/users/student-registration/';

  static const String walletRecharge = '$baseUrl/wallet/recharge/';
  static const String rechargeGateway = '$baseUrl/wallet/recharge/gateway/';
  static String walletTransactions(int walletId) =>
      '$baseUrl/wallet/$walletId/transactions/';
  static const String me = '$baseUrl/users/me/';
  static const String children = '$baseUrl/users/children/';
  static String childPhoto(int studentId) =>
      '$baseUrl/users/children/$studentId/photo/';
  static const String allergens = '$baseUrl/users/allergens/';
  static const String allergies = '$baseUrl/users/allergies/';
  static String studentAllergies(int studentId) =>
      '$baseUrl/users/students/$studentId/allergies/';
  static const String setPaymentPin = '$baseUrl/users/set-payment-pin/';
  static const String verifyPaymentPin = '$baseUrl/users/verify-payment-pin/';
  static const String allergenCreate = '$baseUrl/catalog/allergens/create/';

  // POS & Biometrics & Dynamic QR
  static const String posIdentifyFace = '$baseUrl/pos/identify/face/';
  static const String posIdentifyQr = '$baseUrl/pos/identify/qr/';
  static const String userQrToken = '$baseUrl/users/qr/token/';
  static const String registerBiometric = '$baseUrl/users/biometrics/register/';
  static const String changePassword = '$baseUrl/users/change-password/';
  static const String preOrderCreate = '$baseUrl/pos/preorder/';
  static const String preOrders = '$baseUrl/pos/preorders/';
  static const String posSales = '$baseUrl/pos/sales/';
  static const String posPurchases = '$baseUrl/pos/sales/history/';
  static const String creditHistory = '$baseUrl/pos/credit/history/';
  static String preOrderDeliver(int preOrderId) =>
      '$baseUrl/pos/preorders/$preOrderId/deliver/';

  // Kushki: tokenización de tarjeta directa con la pasarela (no pasa por el
  // backend). La base viene del entorno de compilación (UAT o producción).
  static const String kushkiCardTokens = '${Env.kushkiBaseUrl}/card/v1/tokens';

  // Catalog: productos de la sede del usuario (padres: ?student_id=)
  static const String catalogMenu = '$baseUrl/catalog/menu/';

  // Promotions in force for the user's institution (parents: ?student_id=)
  static const String activePromotions = '$baseUrl/catalog/promotions/active/';

  // Monthly Menu & Dishes
  static String studentMonthlyMenu(int studentId) =>
      '$baseUrl/catalog/students/$studentId/monthly_menu/';
}
