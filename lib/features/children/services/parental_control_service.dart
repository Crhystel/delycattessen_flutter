import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../models/parental_control_model.dart';

class ParentalControlService extends BaseApiService {
  String _endpoint(int studentId) =>
      '${ApiConfig.baseUrl}/users/students/$studentId/parental-control/';

  Future<ParentalControl> getParentalControl(int studentId) async {
    final response = await performGetRequest(_endpoint(studentId));
    return ParentalControl.fromJson(response as Map<String, dynamic>);
  }

  Future<ParentalControl> updateParentalControl(
    int studentId,
    ParentalControl control,
  ) async {
    final response = await performPutRequest(
      _endpoint(studentId),
      control.toJson(),
    );
    return ParentalControl.fromJson(response as Map<String, dynamic>);
  }
}
