import '../models/menu_models.dart';
import 'allergen_advisory.dart';

/// Names of the allergens of [item] that are in [userAllergenIds].
List<String> conflictingAllergensOf(MenuItem item, Set<int> userAllergenIds) =>
    [
      for (final a in item.allergens)
        if (userAllergenIds.contains(a.id)) a.name,
    ];

/// What the detail of a product says about its allergens for [audience].
AllergenAdvisory productAdvisory(
  MenuItem item, {
  required Set<int> userAllergenIds,
  required AllergenAudience audience,
}) => AllergenAdvisory.of(
  allergens: item.allergens.map((a) => a.name),
  conflicts: conflictingAllergensOf(item, userAllergenIds),
  audience: audience,
);

/// Same for a combo: the allergens the backend sent for its items plus the ones
/// of the catalog products it includes. Conflicts come from the backend and are
/// completed by id from [itemsById], so a product the user has registered is
/// caught even when the combo did not flag it.
AllergenAdvisory comboAdvisory(
  Combo combo, {
  required Map<int, MenuItem> itemsById,
  required Set<int> userAllergenIds,
  required AllergenAudience audience,
}) {
  final products = [
    for (final line in combo.items)
      if (itemsById[line.productId] != null) itemsById[line.productId]!,
  ];
  return AllergenAdvisory.of(
    allergens: [
      ...combo.allergenNames,
      for (final p in products) ...p.allergens.map((a) => a.name),
    ],
    conflicts: [
      ...combo.conflictingAllergens,
      for (final p in products) ...conflictingAllergensOf(p, userAllergenIds),
    ],
    audience: audience,
  );
}

/// Combos that include the product [productId], in the order given.
List<Combo> combosIncluding(int productId, Iterable<Combo> combos) => [
  for (final combo in combos)
    if (combo.items.any((line) => line.productId == productId)) combo,
];
