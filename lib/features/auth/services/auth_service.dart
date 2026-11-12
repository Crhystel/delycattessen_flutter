import '../../../core/network/api_config.dart';
import '../../../core/network/base_api_service.dart';
import '../../../core/session/session_manager.dart';
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

  /// Updates the names and email of the logged-in parent or teacher.
  Future<MeResponse> updateProfile(ProfileUpdate data) async {
    final response = await performPatchRequest(
      ApiConfig.meProfile,
      data.toJson(),
    );
    return MeResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Updates the names and username of one of the parent's children.
  Future<Child> updateChildProfile(
    int studentId,
    ChildProfileUpdate data,
  ) async {
    final response = await performPatchRequest(
      ApiConfig.childProfile(studentId),
      data.toJson(),
    );
    return Child.fromJson(response as Map<String, dynamic>);
  }

  /// Sets a child's password. The parent confirms with their own; the
  /// backend closes the child's sessions and keeps the parent's, so no token
  /// is touched here.
  Future<void> changeChildPassword(
    int studentId,
    ChildPasswordChange data,
  ) async {
    await performPostRequest(ApiConfig.childPassword(studentId), data.toJson());
  }

  Future<List<Child>> getChildren() async {
    final response = await performGetRequest(ApiConfig.children);
    return (response as List)
        .map((item) => Child.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Child> updateChildPhoto(int studentId, String photoPath) async {
    final response = await performMultipartPatchRequest(
      ApiConfig.childPhoto(studentId),
      {},
      'profile_picture',
      photoPath,
    );
    return Child.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Allergen>> getAllergens() async {
    final response = await performGetRequest(ApiConfig.allergens);
    return (response as List)
        .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Allergen>> getStudentAllergies(int studentId) =>
      _fetchAllergies(ApiConfig.studentAllergies(studentId));

  Future<List<String>> saveStudentAllergies(
    int studentId,
    List<int> allergenIds,
  ) => _saveAllergies(ApiConfig.studentAllergies(studentId), allergenIds);

  /// Alergias del docente autenticado.
  Future<List<Allergen>> getMyAllergies() =>
      _fetchAllergies(ApiConfig.allergies);

  Future<List<String>> saveMyAllergies(List<int> allergenIds) =>
      _saveAllergies(ApiConfig.allergies, allergenIds);

  /// Alergias del estudiante autenticado. Solo lectura: las edita su padre.
  Future<List<Allergen>> getOwnStudentAllergies() =>
      _fetchAllergies(ApiConfig.ownAllergies);

  Future<List<Allergen>> _fetchAllergies(String url) async {
    final response = await performGetRequest(url);
    return (response as List)
        .map((item) => Allergen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve los alérgenos guardados que aún no tienen productos marcados.
  Future<List<String>> _saveAllergies(String url, List<int> allergenIds) async {
    final response = await performPutRequest(url, {
      'allergen_ids': allergenIds,
    });
    final map = response as Map<String, dynamic>;
    return (map['unprotected_allergens'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
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
    SessionManager.notifySessionEnded();
  }

  Future<Allergen> createAllergen(String name) async {
    final response = await performPostRequest(ApiConfig.allergenCreate, {
      'name': name,
    });
    return Allergen.fromJson(response as Map<String, dynamic>);
  }

  Future<void> changePassword(ChangePasswordRequest data) async {
    final response = await performPostRequest(
      ApiConfig.changePassword,
      data.toJson(),
    );
    // El backend cierra las demás sesiones al cambiar la contraseña y entrega
    // tokens nuevos para que este dispositivo conserve la suya.
    if (response is Map<String, dynamic>) {
      final access = response['access'];
      final refresh = response['refresh'];
      if (access is String && refresh is String) {
        await TokenStorage.saveTokens(access: access, refresh: refresh);
      }
    }
  }
}
