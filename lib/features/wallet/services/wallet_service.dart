import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
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
}
