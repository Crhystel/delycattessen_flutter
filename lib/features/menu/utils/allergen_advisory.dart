/// Kind of item an allergen notice talks about; fills "este {plato}" in texts.
enum AllergenSubject {
  dish('plato'),
  product('producto'),
  combo('combo');

  const AllergenSubject(this.noun);

  /// Spanish word for the item ("plato", "producto", "combo").
  final String noun;
}

/// Whose allergies an [AllergenAdvisory] is checked against.
class AllergenAudience {
  const AllergenAudience._(this.name);

  /// The person looking at the screen (student, teacher): "Tienes registrada...".
  static const self = AllergenAudience._(null);

  /// Nobody identified (POS without a customer): only the allergens are shown.
  static const unknown = AllergenAudience._('');

  /// Someone else, by name (a child, the customer at the POS).
  const AllergenAudience.named(String this.name);

  /// Null for [self]; empty for [unknown].
  final String? name;

  bool get isSelf => name == null;
  bool get isUnknown => name != null && name!.trim().isEmpty;

  @override
  bool operator ==(Object other) =>
      other is AllergenAudience && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// What a detail screen says about the allergens of an item for the person it
/// is checked against: the Spanish texts of the warning and of the blocked
/// purchase bar. Pure, so every screen words it the same way.
class AllergenAdvisory {
  /// Every allergen of the item.
  final List<String> allergens;

  /// The allergens of the item that the audience has registered.
  final List<String> conflicts;

  final AllergenAudience audience;

  const AllergenAdvisory({
    this.allergens = const [],
    this.conflicts = const [],
    this.audience = AllergenAudience.unknown,
  });

  /// Cleans the lists (trims, drops blanks and repeats, keeps the order) and
  /// makes sure every conflict is also listed in [allergens].
  factory AllergenAdvisory.of({
    required Iterable<String> allergens,
    Iterable<String> conflicts = const [],
    AllergenAudience audience = AllergenAudience.unknown,
  }) {
    final cleanConflicts = _clean(conflicts);
    return AllergenAdvisory(
      allergens: _clean([...allergens, ...cleanConflicts]),
      conflicts: cleanConflicts,
      audience: audience,
    );
  }

  bool get hasConflict => conflicts.isNotEmpty;

  /// The red and green boxes need to know whose allergies were checked.
  bool get showsBoxes => !audience.isUnknown;

  bool get _manyConflicts => conflicts.length > 1;

  /// "Contiene sulfitos", "Contiene gluten y lácteos".
  String get conflictTitle => 'Contiene ${_joinNames(conflicts)}';

  /// Why the item cannot be sold to the audience.
  String conflictBody(AllergenSubject subject) {
    final noun = subject.noun;
    final registered = _manyConflicts
        ? 'registradas estas alergias'
        : 'registrada esta alergia';
    if (audience.isSelf) {
      return 'Tienes $registered, por eso este $noun no se te puede vender.';
    }
    if (audience.isUnknown) {
      return 'Este $noun contiene alérgenos que el cliente tiene $registered.';
    }
    final verb = _manyConflicts
        ? 'tiene registradas estas alergias'
        : 'tiene registrada esta alergia';
    return '${audience.name} $verb, por eso este $noun no se le puede vender.';
  }

  /// Green box: none of the item's allergens is registered for the audience.
  String get safeMessage {
    final registered = allergens.length > 1
        ? 'registradas estas alergias'
        : 'registrada esta alergia';
    if (audience.isSelf) return 'No tienes $registered.';
    if (audience.isUnknown) return '';
    final name = audience.name;
    final verb = allergens.length > 1
        ? 'no tiene registradas estas alergias'
        : 'no tiene registrada esta alergia';
    return '$name $verb.';
  }

  /// Label of the disabled purchase button.
  String get blockedLabel {
    if (audience.isSelf) return 'No disponible para ti';
    if (audience.isUnknown) return 'No disponible';
    return 'No disponible para ${audience.name}';
  }

  static List<String> _clean(Iterable<String> names) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in names) {
      final name = raw.trim();
      if (name.isNotEmpty && seen.add(name.toLowerCase())) result.add(name);
    }
    return result;
  }

  /// "a", "a y b", "a, b y c" (lowercase, as in a sentence).
  static String _joinNames(List<String> names) {
    final lower = [for (final n in names) n.toLowerCase()];
    if (lower.length <= 1) return lower.join();
    return '${lower.sublist(0, lower.length - 1).join(', ')} y ${lower.last}';
  }
}
