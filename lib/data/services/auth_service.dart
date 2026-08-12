import '../../core/network/api_config.dart';
import '../../core/network/base_api_service.dart';
import '../models/auth_models.dart';

/// Service specialized in Authentication.
/// Extends [BaseApiService] to leverage the Template Method for clean,
/// typed requests, letting the base class handle errors.
class AuthService extends BaseApiService {

  /// Registers a new Parent (HU-02.1)
  Future<Map<String, dynamic>> registerParent(ParentRegistration data) async {
    final response = await performPostRequest(
      ApiConfig.registerParent,
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Registers an associated Student profile (HU-02.1)
  /// Requires the JWT token to be configured in [BaseApiService.defaultHeaders]
  Future<Map<String, dynamic>> registerStudent(StudentRegistration data) async {
    final response = await performPostRequest(
      ApiConfig.registerStudent,
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Requests the recovery token to be sent by email (HU-02.4)
  Future<Map<String, dynamic>> requestPasswordReset(PasswordResetRequest data) async {
    final response = await performPostRequest(
      ApiConfig.requestPasswordReset,
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Confirms the new password using the token (HU-02.4)
  Future<Map<String, dynamic>> confirmPasswordReset(PasswordResetConfirm data) async {
    final response = await performPostRequest(
      ApiConfig.confirmPasswordReset, 
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }
}
