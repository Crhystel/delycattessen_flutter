import '../../../core/services/base_api_service.dart';
import '../models/parental_control_model.dart';

class ParentalControlService extends BaseApiService {
  Future<ParentalControl> getParentalControl(int studentId) async {
    final response = await performGetRequest(
      '/api/users/students/$studentId/parental-control/',
    );
    return ParentalControl.fromJson(response);
  }

  Future<ParentalControl> updateParentalControl(int studentId, ParentalControl control) async {
    final response = await performPutRequest(
      '/api/users/students/$studentId/parental-control/',
      body: control.toJson(),
    );
    return ParentalControl.fromJson(response);
  }
}
