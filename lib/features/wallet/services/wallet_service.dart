import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/recharge_gateway.dart';
import '../models/wallet_models.dart';

class WalletService extends BaseApiService {
  Future<RechargeResponse> recharge(RechargeRequest data) async {
    final response = await performPostRequest(
      ApiConfig.walletRecharge,
      data.toJson(),
    );
    return RechargeResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> getTransactions(int walletId) async {
    final response = await performGetRequest(
      ApiConfig.walletTransactions(walletId),
    );
    return (response as List)
        .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Pasarela que el servidor asigna a [amount]; la app no conoce el umbral.
  /// Un monto inválido (p. ej. bajo el mínimo) llega como error con mensaje.
  Future<RechargeGateway> getRechargeGateway(double amount) async {
    final uri = Uri.parse(
      ApiConfig.rechargeGateway,
    ).replace(queryParameters: {'amount': amount.toStringAsFixed(2)});
    final response = await performGetRequest(uri.toString());
    final gateway = RechargeGateway.fromApi(
      (response as Map<String, dynamic>)['gateway'] as String?,
    );
    if (gateway == null) {
      throw Exception('No se pudo determinar la pasarela de pago.');
    }
    return gateway;
  }
}
