class Allergen {
  final int id;
  final String name;

  Allergen({required this.id, required this.name});

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(id: json['id'] as int, name: json['name'] as String);
  }
}
