import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../../users/models/allergy_models.dart';

class AuthService extends BaseApiService {
  Future<LoginResponse> login(LoginRequest data) async {
    final response = await performPostRequest(
      ApiConfig.login,
      data.toJson(),
      requiresAuth: false,
    );
    final loginResponse = LoginResponse.fromJson(
      response as Map<String, dynamic>,
    );
    await TokenStorage.saveTokens(
      access: loginResponse.access,
      refresh: loginResponse.refresh,
    );
    return loginResponse;
  }

  Future<bool> tryRefreshToken() async {
    final refresh = await TokenStorage.getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await performPostRequest(ApiConfig.tokenRefresh, {
        'refresh': refresh,
      }, requiresAuth: false).timeout(const Duration(seconds: 8));
      final newAccess = (response as Map<String, dynamic>)['access'] as String;
      await TokenStorage.saveTokens(access: newAccess, refresh: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerParent(ParentRegistration data) async {
    final response = await performPostRequest(
      ApiConfig.registerParent,
      data.toJson(),
      requiresAuth: false,
    );
    final map = response as Map<String, dynamic>;
    // El backend deja al padre autenticado para que siga directo al registro del hijo.
    await TokenStorage.saveTokens(
      access: map['access'] as String,
      refresh: map['refresh'] as String,
    );
  }

  Future<List<Institution>> getInstitutions() async {
    final response = await performGetRequest(ApiConfig.institutions);
    return (response as List)
        .map((item) => Institution.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> registerStudent(StudentRegistration data) async {
    final response = await performMultipartPostRequest(
      ApiConfig.registerStudent,
      data.toFields(),
      'profile_picture',
      data.profilePicturePath,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestPasswordReset(
    PasswordResetRequest data,
  ) async {
    final response = await performPostRequest(
      ApiConfig.requestPasswordReset,
      data.toJson(),
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmPasswordReset(
    PasswordResetConfirm data,
  ) async {
    final response = await performPostRequest(
      ApiConfig.confirmPasswordReset,
      data.toJson(),
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  Future<MeResponse> getMe() async {
    final response = await performGetRequest(ApiConfig.me);
    return MeResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Child>> getChildren() async {
    final response = await performGetRequest(ApiConfig.children);
    return (response as List)
        .map((item) => Child.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Allergen>> getAllergens() async {
    final response = await performGetRequest(ApiConfig.allergens);
    return (response as List)
        .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Allergen>> getStudentAllergies(int studentId) async {
    final response = await performGetRequest(
      ApiConfig.studentAllergies(studentId),
    );
    return (response as List)
        .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveStudentAllergies(
    int studentId,
    List<int> allergenIds,
  ) async {
    await performPutRequest(ApiConfig.studentAllergies(studentId), {
      'allergen_ids': allergenIds,
    });
  }

  Future<void> setPaymentPin(String pin) async {
    await performPostRequest(ApiConfig.setPaymentPin, {'pin': pin});
  }

  Future<bool> verifyPaymentPin(String pin) async {
    final response = await performPostRequest(ApiConfig.verifyPaymentPin, {
      'pin': pin,
    });
    return (response as Map<String, dynamic>)['valid'] as bool;
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }
}
