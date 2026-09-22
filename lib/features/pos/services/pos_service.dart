import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/pos_identification_model.dart';

class PosService extends BaseApiService {
  /// Identifies a user in POS via facial biometric frame.
  Future<IdentifiedUser> identifyByFace(String imagePath) async {
    final response = await performMultipartPostRequest(
      ApiConfig.posIdentifyFace,
      {},
      'photo',
      imagePath,
      requiresAuth: true,
    );
    return IdentifiedUser.fromJson(response as Map<String, dynamic>);
  }

  /// Identifies a user in POS via dynamic QR token.
  Future<IdentifiedUser> identifyByQr(String qrToken) async {
    final response = await performPostRequest(
      ApiConfig.posIdentifyQr,
      {'token': qrToken},
      requiresAuth: true,
    );
    return IdentifiedUser.fromJson(response as Map<String, dynamic>);
  }
}
