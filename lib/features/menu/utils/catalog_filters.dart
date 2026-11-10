import '../models/menu_models.dart';

/// Categorías distintas de [items], ordenadas alfabéticamente.
List<String> categoriesOf(List<MenuItem> items) {
  return items
      .map((i) => i.category.trim())
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

/// Filtra por categoría ([category] nula = todas) y por texto de búsqueda.
/// [query] debe llegar ya normalizado (trim + minúsculas).
List<MenuItem> filterItems(
  List<MenuItem> items, {
  String? category,
  String query = '',
}) {
  return items.where((item) {
    final matchesCategory =
        category == null || item.category.trim() == category;
    final matchesSearch =
        query.isEmpty || item.name.toLowerCase().contains(query);
    return matchesCategory && matchesSearch;
  }).toList();
}
