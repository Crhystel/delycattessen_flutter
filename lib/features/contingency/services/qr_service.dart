import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/qr_token_model.dart';

class QrService extends BaseApiService {
  /// Fetches a dynamic, single-use QR token for the student or teacher.
  Future<QrTokenModel> getDynamicQrToken() async {
    final response = await performGetRequest(
      ApiConfig.userQrToken,
      requiresAuth: true,
    );
    return QrTokenModel.fromJson(response as Map<String, dynamic>);
  }
}
