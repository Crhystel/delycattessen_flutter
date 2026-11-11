import '../../users/services/allergy_owner.dart';
import '../models/menu_models.dart';
import '../utils/allergen_advisory.dart';
import 'menu_service.dart';

/// Productos de la sede visibles para un usuario y los alérgenos de esa
/// persona. La vista del catálogo solo depende de esta abstracción
/// (Dependency Inversion): un rol nuevo es otra implementación, sin tocar la UI.
abstract class ProductCatalogSource {
  /// Identifica la fuente; si cambia, la vista recarga.
  String get id;

  /// Texto para los avisos de alérgenos ("tus alergias", "las alergias de Ana").
  String get allergyOwnerLabel;

  /// Whose allergies the detail screens check an item against.
  AllergenAudience get allergenAudience;

  Future<List<MenuItem>> loadItems();

  /// Combos in force today in the same institution as the products.
  Future<CatalogOffers> loadOffers();

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
  AllergenAudience get allergenAudience => AllergenAudience.named(studentName);

  @override
  Future<List<MenuItem>> loadItems() =>
      _menuService.getMenu(studentId: studentId);

  @override
  Future<CatalogOffers> loadOffers() =>
      _menuService.getActiveOffers(studentId: studentId);

  @override
  Future<Set<int>> loadAllergenIds() async =>
      (await _allergyOwner.load()).map((a) => a.id).toSet();
}

/// Catálogo de la propia sede de quien consulta (docente o estudiante): no
/// lleva `student_id`, el backend usa la institución del usuario. Las alergias
/// las aporta [allergyOwner]: las propias del docente o las del estudiante
/// ([StudentSelfAllergyOwner], solo lectura). Si no se pueden cargar el catálogo
/// falla y ofrece reintentar, en vez de mostrarse sin marcar alérgenos.
class OwnCatalogSource implements ProductCatalogSource {
  final MenuService _menuService;
  final AllergyOwner allergyOwner;

  @override
  final String id;

  OwnCatalogSource({
    required this.id,
    required this.allergyOwner,
    MenuService? menuService,
  }) : _menuService = menuService ?? MenuService();

  /// Docente: sus propias alergias.
  factory OwnCatalogSource.teacher({
    MenuService? menuService,
    AllergyOwner? allergyOwner,
  }) => OwnCatalogSource(
    id: 'teacher',
    allergyOwner: allergyOwner ?? TeacherAllergyOwner(),
    menuService: menuService,
  );

  /// Estudiante: sus propias alergias (solo lectura).
  factory OwnCatalogSource.student({
    MenuService? menuService,
    AllergyOwner? allergyOwner,
  }) => OwnCatalogSource(
    id: 'student',
    allergyOwner: allergyOwner ?? StudentSelfAllergyOwner(),
    menuService: menuService,
  );

  @override
  String get allergyOwnerLabel => 'tus alergias';

  @override
  AllergenAudience get allergenAudience => AllergenAudience.self;

  @override
  Future<List<MenuItem>> loadItems() => _menuService.getMenu();

  @override
  Future<CatalogOffers> loadOffers() => _menuService.getActiveOffers();

  @override
  Future<Set<int>> loadAllergenIds() async =>
      (await allergyOwner.load()).map((a) => a.id).toSet();
}
