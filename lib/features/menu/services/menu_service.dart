import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/menu_models.dart';

class MenuService extends BaseApiService {
  /// Obtiene los días del menú mensual publicado para el estudiante.
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async {
    final response = await performGetRequest(
      ApiConfig.studentMonthlyMenu(studentId),
    );
    final data = response as List;
    return data
        .map((json) => MenuDay.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crea una preorden para un estudiante en una fecha determinada.
  /// (Aplica validaciones de saldo, controles parentales y alérgenos en el backend)
  Future<Map<String, dynamic>> createPreOrder(PreOrder order) async {
    final response = await performPostRequest(
      ApiConfig.preOrderCreate,
      order.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Lista las preórdenes de los hijos del padre autenticado.
  /// [studentId] es opcional: si se pasa, filtra solo ese hijo.
  Future<List<PreOrderSummary>> getPreOrders({int? studentId}) async {
    final uri = Uri.parse(ApiConfig.preOrders).replace(
      queryParameters: studentId != null
          ? {'student_id': studentId.toString()}
          : null,
    );
    final response = await performGetRequest(uri.toString());
    final data = response as List;
    return data
        .map((json) => PreOrderSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Catálogo general de productos (por compatibilidad)
  Future<List<MenuItem>> getMenu() async {
    final response = await performGetRequest('${ApiConfig.baseUrl}/catalog/menu/');
    final data = response as List;
    return data.map((json) => MenuItem.fromJson(json)).toList();
  }
}
