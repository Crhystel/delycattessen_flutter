import '../models/menu_models.dart';
import 'allergen_advisory.dart';

/// Allergen notice of [dish] for [audience]. The backend lists the conflicts in
/// `conflicting_allergens`; older responses only carry the
/// `has_student_allergens` flag, in which case every allergen is a conflict.
AllergenAdvisory dishAdvisory(
  MenuDish dish, {
  AllergenAudience audience = AllergenAudience.unknown,
}) {
  final conflicts = dish.conflictingAllergens.isNotEmpty
      ? dish.conflictingAllergens
      : (dish.hasStudentAllergens ? dish.allergens : const <String>[]);
  return AllergenAdvisory.of(
    allergens: dish.allergens,
    conflicts: conflicts,
    audience: audience,
  );
}
