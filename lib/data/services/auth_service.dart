import '../../core/network/api_config.dart';
import '../../core/network/base_api_service.dart';
import '../models/auth_models.dart';

/// Servicio especializado en Autenticación.
/// Hereda de [BaseApiService] aprovechando el Template Method para realizar 
/// peticiones limpias y tipadas (Type Hints), dejando que la clase base maneje errores.
class AuthService extends BaseApiService {
  
  /// Registra un nuevo Padre de Familia (HU-02.1)
  Future<Map<String, dynamic>> registerParent(ParentRegistration data) async {
    final response = await performPostRequest(
      ApiConfig.registerParent, 
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Registra un perfil de Estudiante asociado (HU-02.1)
  /// Requiere que el Token JWT esté configurado en [BaseApiService.defaultHeaders]
  Future<Map<String, dynamic>> registerStudent(StudentRegistration data) async {
    final response = await performPostRequest(
      ApiConfig.registerStudent, 
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Solicita el envío del token de recuperación por correo (HU-02.4)
  Future<Map<String, dynamic>> requestPasswordReset(PasswordResetRequest data) async {
    final response = await performPostRequest(
      ApiConfig.requestPasswordReset, 
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }

  /// Confirma la nueva contraseña usando el token (HU-02.4)
  Future<Map<String, dynamic>> confirmPasswordReset(PasswordResetConfirm data) async {
    final response = await performPostRequest(
      ApiConfig.confirmPasswordReset, 
      data.toJson(),
    );
    return response as Map<String, dynamic>;
  }
}
