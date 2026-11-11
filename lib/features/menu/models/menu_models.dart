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

/// Platillo del menú mensual (`MenuDish`)
class MenuDish {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final List<String> allergens;
  final bool hasStudentAllergens;

  MenuDish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.allergens = const [],
    this.hasStudentAllergens = false,
  });

  factory MenuDish.fromJson(Map<String, dynamic> json) {
    final allergensList = (json['allergens'] as List? ?? [])
        .map((a) => a.toString())
        .toList();

    return MenuDish(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse((json['price'] ?? '0.00').toString()) ?? 0.0,
      imageUrl: json['image'] as String?,
      allergens: allergensList,
      hasStudentAllergens: json['has_student_allergens'] as bool? ?? false,
    );
  }
}

/// Día del menú mensual (`DailyMenu`)
class MenuDay {
  final int id;
  final String date; // "YYYY-MM-DD"
  final bool isBlockedByParentalControl;
  final String? blockedReason;
  final List<MenuDish> dishes;

  MenuDay({
    required this.id,
    required this.date,
    required this.isBlockedByParentalControl,
    this.blockedReason,
    required this.dishes,
  });

  factory MenuDay.fromJson(Map<String, dynamic> json) {
    final dishesRaw = json['dishes'] as List? ?? [];
    return MenuDay(
      id: json['id'] as int,
      date: json['date'] as String,
      isBlockedByParentalControl:
          json['is_blocked_by_parental_control'] as bool? ?? false,
      blockedReason: json['blocked_reason'] as String?,
      dishes: dishesRaw
          .map((d) => MenuDish.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Item para enviar en `POST /api/pos/preorder/`
class PreOrderItem {
  final int dishId;
  final int quantity;

  PreOrderItem({required this.dishId, required this.quantity});

  // Compatibilidad hacia atrás
  int get menuItemId => dishId;

  Map<String, dynamic> toJson() {
    return {'dish_id': dishId, 'quantity': quantity};
  }
}

/// Payload para crear preorden: `POST /api/pos/preorder/`
class PreOrder {
  final int studentId;
  final String deliveryDate; // "YYYY-MM-DD"
  final List<PreOrderItem> items;

  PreOrder({
    required this.studentId,
    required this.deliveryDate,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'delivery_date': deliveryDate,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

/// Detalle de ítem recibido en `GET /api/pos/preorders/`
class PreOrderItemDetail {
  final int id;
  final int dishId;
  final String dishName;
  final int quantity;
  final double priceAtPurchase;

  /// Foto del producto; nula si no tiene o si el backend no la envía.
  final String? imageUrl;

  PreOrderItemDetail({
    required this.id,
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.priceAtPurchase,
    this.imageUrl,
  });

  // Compatibilidad hacia atrás
  int get menuItemId => dishId;
  String get menuItemName => dishName;

  factory PreOrderItemDetail.fromJson(Map<String, dynamic> json) {
    return PreOrderItemDetail(
      id: json['id'] as int? ?? 0,
      dishId: json['dish'] as int? ?? (json['menu_item'] as int? ?? 0),
      dishName:
          json['dish_name'] as String? ??
          (json['menu_item_name'] as String? ?? 'Platillo'),
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase:
          double.tryParse((json['price_at_purchase'] ?? '0.00').toString()) ??
          0.0,
      imageUrl: json['image'] as String?,
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

/// Resumen de preorden devuelto por `GET /api/pos/preorders/`
class PreOrderSummary {
  final int id;
  final int studentId;
  final String studentName;
  final String deliveryDate; // "YYYY-MM-DD"
  final PreOrderStatus status;
  final String statusDisplay;
  final double totalAmount;
  final DateTime createdAt;
  final List<PreOrderItemDetail> items;

  PreOrderSummary({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.deliveryDate,
    required this.status,
    required this.statusDisplay,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory PreOrderSummary.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return PreOrderSummary(
      id: json['id'] as int,
      studentId: json['student'] as int? ?? 0,
      studentName: json['student_name'] as String? ?? '',
      deliveryDate: json['delivery_date'] as String? ?? '',
      status: _preOrderStatusFromString(json['status'] as String? ?? 'PENDING'),
      statusDisplay: (json['status_display'] ?? json['status'] ?? 'Pendiente')
          .toString(),
      totalAmount:
          double.tryParse((json['total_amount'] ?? '0.00').toString()) ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      items: itemsList
          .map((i) => PreOrderItemDetail.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// De dónde viene un pedido que ve el padre.
enum OrderOrigin { preorder, pointOfSale }

/// Fila de la lista "Pedidos": una preorden o una compra hecha en caja.
/// Unifica ambos orígenes para que la pantalla no dependa de dos modelos.
class OrderEntry {
  final int id;
  final int studentId;
  final String studentName;
  final DateTime createdAt;
  final PreOrderStatus status;
  final String statusDisplay;
  final String deliveryDate; // "YYYY-MM-DD"; vacío en compras en caja
  final double totalAmount;
  final List<PreOrderItemDetail> items;
  final OrderOrigin origin;

  /// Medio de pago ("Efectivo", "Saldo de billetera"…); solo en compras en caja.
  final String paymentLabel;

  const OrderEntry({
    required this.id,
    this.studentId = 0,
    required this.studentName,
    required this.createdAt,
    required this.status,
    required this.statusDisplay,
    required this.deliveryDate,
    required this.totalAmount,
    required this.items,
    required this.origin,
    this.paymentLabel = '',
  });

  /// Solo las preórdenes pendientes están "por retirar".
  bool get isPendingPickup =>
      origin == OrderOrigin.preorder && status == PreOrderStatus.pending;

  factory OrderEntry.fromPreOrder(PreOrderSummary order) {
    return OrderEntry(
      id: order.id,
      studentId: order.studentId,
      studentName: order.studentName,
      createdAt: order.createdAt,
      status: order.status,
      statusDisplay: order.statusDisplay,
      deliveryDate: order.deliveryDate,
      totalAmount: order.totalAmount,
      items: order.items,
      origin: OrderOrigin.preorder,
    );
  }

  /// Compra de `GET /api/pos/sales/history/`: ya fue entregada en caja.
  factory OrderEntry.fromPurchaseJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OrderEntry(
      id: json['id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      studentName: (json['student_name'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      status: PreOrderStatus.delivered,
      statusDisplay: 'Entregado',
      deliveryDate: '',
      totalAmount:
          double.tryParse((json['total_amount'] ?? '0.00').toString()) ?? 0.0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PreOrderItemDetail.fromJson)
          .toList(),
      origin: OrderOrigin.pointOfSale,
      paymentLabel: (json['payment_method_display'] ?? '').toString(),
    );
  }
}

/// Modelo de catálogo general (mantenido para compatibilidad opcional)
class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final List<Ingredient> ingredients;
  final List<Allergen> allergens;
  final int stock;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.ingredients,
    required this.allergens,
    this.stock = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final allergensList = json['allergens'] as List? ?? [];
    final ingredientsList = json['ingredients'] as List? ?? [];
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      // Only `price`: discounts no longer exist, so any `final_price` or
      // `discount_percentage` an older backend still sends is ignored.
      price: double.tryParse((json['price'] ?? '0.00').toString()) ?? 0.0,
      imageUrl: json['image'] as String?,
      category: json['category'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      ingredients: ingredientsList.map((i) => Ingredient.fromJson(i)).toList(),
      allergens: allergensList.map((a) => Allergen.fromJson(a)).toList(),
    );
  }
}

/// Product of a [Combo] and how many units it includes.
class ComboItem {
  final int productId;
  final String name;
  final int quantity;

  /// Units in stock of the product; null when the backend does not send it
  /// (then the catalog is the only source). Zero means sold out.
  final int? stock;

  const ComboItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.stock,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) => ComboItem(
    productId: (json['product_id'] as num?)?.toInt() ?? 0,
    name: (json['name'] ?? '').toString(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    stock: _intOrNull(json['stock']),
  );
}

/// Fixed-price bundle of products (e.g. sandwich + cola for $3.50) in force
/// today. Shown as a banner; at the POS a tap adds it to the cart.
class Combo {
  final int id;
  final String name;
  final double price;

  /// What the products cost bought separately.
  final double regularPrice;
  final String? imageUrl;
  final DateTime endDate;
  final List<ComboItem> items;

  /// How many combos can still be sold: the least of floor(stock / quantity)
  /// over its products, zero if one is inactive. The combo has no stock of its
  /// own. Null when the backend does not send it (no limit is known).
  final int? availableQuantity;

  const Combo({
    required this.id,
    required this.name,
    required this.price,
    required this.regularPrice,
    required this.endDate,
    this.imageUrl,
    this.items = const [],
    this.availableQuantity,
  });

  /// False only when the backend says no unit can be sold; without the data
  /// the combo is considered available.
  bool get isAvailable => availableQuantity == null || availableQuantity! > 0;

  /// True when the combo costs less than its products bought separately.
  bool get hasSavings => regularPrice > price;

  /// What the customer saves with the combo; zero when there is no saving.
  double get savings => hasSavings ? regularPrice - price : 0.0;

  /// Tolerant: only a missing `id` makes it invalid (the caller skips that
  /// combo); a null name, price, date or image takes a default instead of
  /// failing the whole list of offers.
  factory Combo.fromJson(Map<String, dynamic> json) => Combo(
    id: json['id'] as int,
    name: (json['name'] ?? '').toString(),
    price: double.tryParse((json['price'] ?? '').toString()) ?? 0.0,
    regularPrice:
        double.tryParse((json['regular_price'] ?? '').toString()) ?? 0.0,
    endDate: _dateOrNow(json['end_date']),
    imageUrl: json['image'] as String?,
    items: (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ComboItem.fromJson)
        .toList(),
    availableQuantity: _intOrNull(json['available_quantity']),
  );
}

/// Whole number of an optional count; null when it is missing or unreadable
/// (so the extra stock data can never make a combo invalid).
int? _intOrNull(Object? value) =>
    value is num ? value.toInt() : int.tryParse((value ?? '').toString());

/// Date of an offer; today when the backend sends none or an unreadable one.
DateTime _dateOrNow(Object? value) =>
    DateTime.tryParse((value ?? '').toString()) ?? DateTime.now();

/// Offers in force for an institution: the combos.
class CatalogOffers {
  final List<Combo> combos;

  const CatalogOffers({this.combos = const []});

  static const empty = CatalogOffers();

  bool get isEmpty => combos.isEmpty;

  /// Combos that can still be sold. Informational surfaces (parents, students,
  /// teachers) show only these; the POS shows all of them, dimming the sold out.
  List<Combo> get visibleCombos => [
    for (final combo in combos)
      if (combo.isAvailable) combo,
  ];
}
