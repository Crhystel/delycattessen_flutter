import '../../users/services/allergy_owner.dart';
import '../models/menu_models.dart';
import 'menu_service.dart';

/// Productos de la sede visibles para un usuario y los alérgenos de esa
/// persona. La vista del catálogo solo depende de esta abstracción
/// (Dependency Inversion): un rol nuevo es otra implementación, sin tocar la UI.
abstract class ProductCatalogSource {
  /// Identifica la fuente; si cambia, la vista recarga.
  String get id;

  /// Texto para los avisos de alérgenos ("tus alergias", "las alergias de Ana").
  String get allergyOwnerLabel;

  Future<List<MenuItem>> loadItems();

  /// Promotions in force today in the same institution as the products.
  Future<List<Promotion>> loadPromotions();

  /// Ids de los alérgenos registrados de la persona.
  Future<Set<int>> loadAllergenIds();
}

/// Catálogo para un padre: productos de la sede del hijo y alergias del hijo.
class StudentCatalogSource implements ProductCatalogSource {
  final int studentId;
  final String studentName;
  final MenuService _menuService;
  final AllergyOwner _allergyOwner;

  StudentCatalogSource({
    required this.studentId,
    required this.studentName,
    MenuService? menuService,
    AllergyOwner? allergyOwner,
  }) : _menuService = menuService ?? MenuService(),
       _allergyOwner = allergyOwner ?? StudentAllergyOwner(studentId);

  @override
  String get id => 'student-$studentId';

  @override
  String get allergyOwnerLabel => 'las alergias de $studentName';

  @override
  Future<List<MenuItem>> loadItems() =>
      _menuService.getMenu(studentId: studentId);

  @override
  Future<List<Promotion>> loadPromotions() =>
      _menuService.getActivePromotions(studentId: studentId);

  @override
  Future<Set<int>> loadAllergenIds() async =>
      (await _allergyOwner.load()).map((a) => a.id).toSet();
}

/// Catálogo para el docente: productos de su propia sede y sus alergias.
class TeacherCatalogSource implements ProductCatalogSource {
  final MenuService _menuService;
  final AllergyOwner _allergyOwner;

  TeacherCatalogSource({MenuService? menuService, AllergyOwner? allergyOwner})
    : _menuService = menuService ?? MenuService(),
      _allergyOwner = allergyOwner ?? TeacherAllergyOwner();

  @override
  String get id => 'teacher';

  @override
  String get allergyOwnerLabel => 'tus alergias';

  @override
  Future<List<MenuItem>> loadItems() => _menuService.getMenu();

  @override
  Future<List<Promotion>> loadPromotions() =>
      _menuService.getActivePromotions();

  @override
  Future<Set<int>> loadAllergenIds() async =>
      (await _allergyOwner.load()).map((a) => a.id).toSet();
}
