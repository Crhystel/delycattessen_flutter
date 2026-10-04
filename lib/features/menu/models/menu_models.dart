class Ingredient {
  final int id;
  final String name;

  Ingredient({required this.id, required this.name});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(id: json['id'], name: json['name']);
  }
}

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
  final String category;
  final List<Ingredient> ingredients;
  final List<Allergen> allergens;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.ingredients,
    required this.allergens,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    var allergensList = json['allergens'] as List? ?? [];
    var ingredientsList = json['ingredients'] as List? ?? [];
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image'] as String?,
      category: json['category'] as String? ?? '',
      ingredients: ingredientsList.map((i) => Ingredient.fromJson(i)).toList(),
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

class PreOrderItemDetail {
  final int id;
  final int menuItemId;
  final String menuItemName;
  final int quantity;
  final double priceAtPurchase;

  PreOrderItemDetail({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory PreOrderItemDetail.fromJson(Map<String, dynamic> json) {
    return PreOrderItemDetail(
      id: json['id'],
      menuItemId: json['menu_item'],
      menuItemName: json['menu_item_name'] ?? '',
      quantity: json['quantity'],
      priceAtPurchase: double.parse(json['price_at_purchase'].toString()),
    );
  }
}

enum PreOrderStatus { pending, delivered, canceled }

PreOrderStatus _preOrderStatusFromString(String value) {
  switch (value) {
    case 'DELIVERED':
      return PreOrderStatus.delivered;
    case 'CANCELED':
      return PreOrderStatus.canceled;
    case 'PENDING':
    default:
      return PreOrderStatus.pending;
  }
}

class PreOrderSummary {
  final int id;
  final int studentId;
  final String studentName;
  final PreOrderStatus status;
  final String statusDisplay;
  final double totalAmount;
  final DateTime createdAt;
  final List<PreOrderItemDetail> items;

  PreOrderSummary({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.statusDisplay,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory PreOrderSummary.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return PreOrderSummary(
      id: json['id'],
      studentId: json['student'],
      studentName: json['student_name'] ?? '',
      status: _preOrderStatusFromString(json['status']),
      statusDisplay: json['status_display'] ?? json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList.map((i) => PreOrderItemDetail.fromJson(i)).toList(),
    );
  }
}
