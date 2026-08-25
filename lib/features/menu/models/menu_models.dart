class Allergen {
  final int id;
  final String name;

  Allergen({required this.id, required this.name});

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(id: json['id'], name: json['name']);
  }
}

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final List<Allergen> allergens;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.allergens,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    var allergensList = json['allergens'] as List? ?? [];
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image'] as String?,
      allergens: allergensList.map((a) => Allergen.fromJson(a)).toList(),
    );
  }
}

class PreOrderItem {
  final int menuItemId;
  final int quantity;

  PreOrderItem({required this.menuItemId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'menu_item_id': menuItemId, 'quantity': quantity};
  }
}

class PreOrder {
  final int studentId;
  final List<PreOrderItem> items;

  PreOrder({required this.studentId, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
