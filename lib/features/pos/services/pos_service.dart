import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/pos_identification_model.dart';
import '../models/sale_models.dart';

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
    final response = await performPostRequest(ApiConfig.posIdentifyQr, {
      'token': qrToken,
    }, requiresAuth: true);
    return IdentifiedUser.fromJson(response as Map<String, dynamic>);
  }

  /// Marca una preorden pendiente como entregada, una vez que el cajero
  /// identifica al estudiante en el POS y confirma la entrega del producto.
  Future<void> markPreOrderDelivered(int preOrderId) async {
    await performPatchRequest(ApiConfig.preOrderDeliver(preOrderId), {});
  }

  /// Cobra productos del POS. El backend decide quién puede usar cada método
  /// de pago y valida stock, alérgenos, control parental y saldo.
  Future<Sale> createSale(SaleRequest request) async {
    final response = await performPostRequest(
      ApiConfig.posSales,
      request.toJson(),
    );
    return Sale.fromJson(response as Map<String, dynamic>);
  }

  /// Compras a crédito del docente autenticado y su acumulado del mes.
  Future<CreditHistory> getCreditHistory() async {
    final response = await performGetRequest(ApiConfig.creditHistory);
    return CreditHistory.fromJson(response as Map<String, dynamic>);
  }
}
