import '../../menu/models/menu_models.dart';
import '../../menu/utils/allergen_advisory.dart';
import '../models/pos_identification_model.dart';

/// Checks products and combos against the allergies of the customer identified
/// at the POS, by name. Without a customer nothing conflicts and the notices
/// only list the allergens.
///
/// The backend's own `conflicting_allergens` are not used here: they refer to
/// whoever is logged in (the cashier), not to the customer being served.
class CustomerAllergenCheck {
  final AllergenAudience audience;
  final Set<String> _registered;

  CustomerAllergenCheck({
    String? customerName,
    Iterable<String> allergies = const [],
  }) : audience = customerName == null
           ? AllergenAudience.unknown
           : AllergenAudience.named(customerName),
       _registered = {for (final a in allergies) _normalize(a)}..remove('');

  factory CustomerAllergenCheck.forUser(IdentifiedUser? user) =>
      CustomerAllergenCheck(
        customerName: user?.fullName,
        allergies: user?.allergies ?? const [],
      );

  static String _normalize(String name) => name.trim().toLowerCase();

  /// Allergens of [item] that the customer has registered.
  List<String> productConflicts(MenuItem item) =>
      _matching([for (final allergen in item.allergens) allergen.name]);

  /// Allergens of the customer found in [combo].
  List<String> comboConflicts(Combo combo, Map<int, MenuItem> itemsById) =>
      _matching(_comboAllergens(combo, itemsById));

  AllergenAdvisory productAdvisory(MenuItem item) => AllergenAdvisory.of(
    allergens: [for (final allergen in item.allergens) allergen.name],
    conflicts: productConflicts(item),
    audience: audience,
  );

  AllergenAdvisory comboAdvisory(Combo combo, Map<int, MenuItem> itemsById) =>
      AllergenAdvisory.of(
        allergens: _comboAllergens(combo, itemsById),
        conflicts: comboConflicts(combo, itemsById),
        audience: audience,
      );

  /// What the combo lists for its dishes plus the catalog products' allergens
  /// (a sold out dish is not in the catalog but is in the combo).
  List<String> _comboAllergens(Combo combo, Map<int, MenuItem> itemsById) => [
    ...combo.allergenNames,
    for (final dish in combo.items)
      if (itemsById[dish.productId] case final item?)
        for (final allergen in item.allergens) allergen.name,
  ];

  List<String> _matching(Iterable<String> names) {
    if (_registered.isEmpty) return const [];
    final seen = <String>{};
    return [
      for (final name in names)
        if (_registered.contains(_normalize(name)) &&
            seen.add(_normalize(name)))
          name.trim(),
    ];
  }
}
