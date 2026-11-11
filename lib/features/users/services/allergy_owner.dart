import '../../auth/services/auth_service.dart';
import '../models/allergy_models.dart';

/// Dueño de un registro de alergias (un estudiante o el docente autenticado).
/// La pantalla de gestión solo depende de esta abstracción (Dependency
/// Inversion): sumar otro tipo de dueño no la modifica.
abstract class AllergyOwner {
  Future<List<Allergen>> load();

  /// Guarda y devuelve los alérgenos sin productos marcados todavía.
  Future<List<String>> save(List<int> allergenIds);
}

class StudentAllergyOwner implements AllergyOwner {
  final int studentId;
  final AuthService _authService;

  StudentAllergyOwner(this.studentId, {AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  Future<List<Allergen>> load() => _authService.getStudentAllergies(studentId);

  @override
  Future<List<String>> save(List<int> allergenIds) =>
      _authService.saveStudentAllergies(studentId, allergenIds);
}

class TeacherAllergyOwner implements AllergyOwner {
  final AuthService _authService;

  TeacherAllergyOwner({AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  Future<List<Allergen>> load() => _authService.getMyAllergies();

  @override
  Future<List<String>> save(List<int> allergenIds) =>
      _authService.saveMyAllergies(allergenIds);
}

/// El propio estudiante autenticado (contingencia). Solo LEE sus alergias para
/// marcar los alérgenos del catálogo: las edita únicamente su padre, así que
/// guardar no está permitido (el servidor tampoco lo permite).
class StudentSelfAllergyOwner implements AllergyOwner {
  final AuthService _authService;

  StudentSelfAllergyOwner({AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  Future<List<Allergen>> load() => _authService.getOwnStudentAllergies();

  @override
  Future<List<String>> save(List<int> allergenIds) =>
      throw UnsupportedError('Las alergias del estudiante las edita su padre.');
}
