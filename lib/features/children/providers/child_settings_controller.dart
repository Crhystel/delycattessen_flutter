import 'package:flutter/foundation.dart';

import '../../auth/services/auth_service.dart';
import '../../users/models/allergy_models.dart';
import '../models/parental_control_model.dart';
import '../services/parental_control_service.dart';

/// Resumen de lo que el padre configuró para un hijo: sus alergias y su control
/// parental. Lo usan la ficha y "Datos del hijo" para pintar los resúmenes de
/// las filas. Es informativo: si una carga falla, el dato queda en `null` y la
/// fila muestra su texto genérico (el detalle de cada pantalla ya informa los
/// errores reales cuando el padre entra a editar).
class ChildSettingsController extends ChangeNotifier {
  ChildSettingsController({
    required this.studentId,
    AuthService? authService,
    ParentalControlService? parentalService,
  }) : _authService = authService ?? AuthService(),
       _parentalService = parentalService ?? ParentalControlService();

  final int studentId;
  final AuthService _authService;
  final ParentalControlService _parentalService;

  List<Allergen>? _allergies;
  ParentalControl? _parentalControl;
  bool _disposed = false;

  /// Alergias del hijo; `null` mientras carga o si no están disponibles.
  List<Allergen>? get allergies => _allergies;

  /// Control parental; `null` mientras carga o si no está disponible.
  ParentalControl? get parentalControl => _parentalControl;

  /// Carga (o recarga) alergias y control parental en paralelo.
  Future<void> load() => Future.wait([loadAllergies(), loadParentalControl()]);

  Future<void> loadAllergies() async {
    try {
      final allergies = await _authService.getStudentAllergies(studentId);
      if (_disposed) return;
      _allergies = allergies;
      notifyListeners();
    } catch (_) {
      // Resumen informativo: se queda el texto genérico de la fila.
    }
  }

  Future<void> loadParentalControl() async {
    try {
      final control = await _parentalService.getParentalControl(studentId);
      if (_disposed) return;
      _parentalControl = control;
      notifyListeners();
    } catch (_) {
      // Resumen informativo: se queda el texto genérico de la fila.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
