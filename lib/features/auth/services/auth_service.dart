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

  Future<List<int>> getUserAllergyIds(int targetUserId) async {
    final response = await performGetRequest(
      '${ApiConfig.allergies}?target_user_id=$targetUserId',
    );
    return (response as List).map((item) => item['allergen'] as int).toList();
  }

  Future<void> saveUserAllergies(
    int targetUserId,
    List<int> allergenIds,
  ) async {
    await performPutRequest(ApiConfig.allergies, {
      'target_user_id': targetUserId,
      'allergen_ids': allergenIds,
    });
  }
}
