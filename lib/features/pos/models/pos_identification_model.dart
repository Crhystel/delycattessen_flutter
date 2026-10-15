class PendingPreOrderItem {
  final String dishName;
  final int quantity;
  final double priceAtPurchase;

  PendingPreOrderItem({
    required this.dishName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  // Compatibilidad hacia atrás
  String get menuItemName => dishName;

  factory PendingPreOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingPreOrderItem(
      dishName: json['dish_name'] ?? (json['menu_item_name'] ?? 'Platillo'),
      quantity: json['quantity'] ?? 1,
      priceAtPurchase:
          double.tryParse((json['price_at_purchase'] ?? '0.00').toString()) ??
          0.0,
    );
  }
}

class PendingPreOrder {
  final int preOrderId;
  final double totalAmount;
  final String createdAt;
  final String deliveryDate;
  final List<PendingPreOrderItem> items;

  PendingPreOrder({
    required this.preOrderId,
    required this.totalAmount,
    required this.createdAt,
    this.deliveryDate = '',
    required this.items,
  });

  factory PendingPreOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PendingPreOrder(
      preOrderId: json['pre_order_id'] ?? 0,
      totalAmount:
          double.tryParse((json['total_amount'] ?? '0.00').toString()) ?? 0.0,
      createdAt: json['created_at'] ?? '',
      deliveryDate: json['delivery_date'] ?? '',
      items: rawItems
          .map((i) => PendingPreOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IdentifiedUser {
  final int userId;
  final int? studentId;
  final String username;
  final String fullName;
  final String role;

  /// Rol en español ya traducido por el backend ("Docente", "Estudiante").
  final String roleDisplay;
  final String? institution;
  final double balance;

  /// Crédito del mes acumulado; solo viene para docentes.
  final double? creditAccumulated;
  final List<String> allergies;
  final List<PendingPreOrder> pendingOrders;
  final String identificationMethod;

  IdentifiedUser({
    required this.userId,
    this.studentId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.roleDisplay,
    this.institution,
    required this.balance,
    this.creditAccumulated,
    required this.allergies,
    required this.pendingOrders,
    required this.identificationMethod,
  });

  factory IdentifiedUser.fromJson(Map<String, dynamic> json) {
    final rawAllergies = json['allergies'] as List? ?? [];
    final rawPendingOrders = json['pending_orders'] as List? ?? [];
    return IdentifiedUser(
      userId: json['user_id'] ?? 0,
      studentId: json['student_id'] as int?,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? '',
      roleDisplay: _nonEmptyOr(json['role_display'], json['role']),
      institution: json['institution'] as String?,
      balance: double.tryParse((json['balance'] ?? '0.00').toString()) ?? 0.0,
      creditAccumulated: json['credit_accumulated'] == null
          ? null
          : double.tryParse(json['credit_accumulated'].toString()),
      allergies: rawAllergies.map((a) => a.toString()).toList(),
      pendingOrders: rawPendingOrders
          .map((o) => PendingPreOrder.fromJson(o as Map<String, dynamic>))
          .toList(),
      identificationMethod: json['identification_method'] ?? 'UNKNOWN',
    );
  }

  bool get isTeacher => role == 'TEACHER';

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'student_id': studentId,
      'username': username,
      'full_name': fullName,
      'role': role,
      'role_display': roleDisplay,
      'institution': institution,
      'balance': balance.toStringAsFixed(2),
      if (creditAccumulated != null)
        'credit_accumulated': creditAccumulated!.toStringAsFixed(2),
      'allergies': allergies,
      'identification_method': identificationMethod,
    };
  }
}

/// Texto del backend si viene con contenido; si no, [fallback] (o vacío).
String _nonEmptyOr(Object? value, Object? fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isNotEmpty ? text : (fallback?.toString() ?? '');
}
