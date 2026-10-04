import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/menu_models.dart';

class MenuService extends BaseApiService {
  /// Obtiene el catálogo de productos activos
  Future<List<MenuItem>> getMenu() async {
    final response = await performGetRequest(
      '${ApiConfig.baseUrl}/catalog/menu/', // Asumiendo esta ruta
    );
    final data = response as List;
    return data.map((json) => MenuItem.fromJson(json)).toList();
  }

  /// Crea una preorden (aplica validación de saldo y alérgenos en el backend)
  Future<Map<String, dynamic>> createPreOrder(PreOrder order) async {
    final response = await performPostRequest(
      '${ApiConfig.baseUrl}/pos/preorder/', // Asumiendo esta ruta
      order.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Lista las preórdenes de los hijos del padre autenticado.
  /// [studentId] es opcional: si se pasa, filtra solo ese hijo.
  Future<List<PreOrderSummary>> getPreOrders({int? studentId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pos/preorders/').replace(
      queryParameters: studentId != null
          ? {'student_id': studentId.toString()}
          : null,
    );
    final response = await performGetRequest(uri.toString());
    final data = response as List;
    return data.map((json) => PreOrderSummary.fromJson(json)).toList();
  }
}
