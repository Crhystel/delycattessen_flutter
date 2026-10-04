class PendingPreOrderItem {
  final String menuItemName;
  final int quantity;
  final double priceAtPurchase;

  PendingPreOrderItem({
    required this.menuItemName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory PendingPreOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingPreOrderItem(
      menuItemName: json['menu_item_name'] ?? '',
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
  final List<PendingPreOrderItem> items;

  PendingPreOrder({
    required this.preOrderId,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory PendingPreOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PendingPreOrder(
      preOrderId: json['pre_order_id'] ?? 0,
      totalAmount:
          double.tryParse((json['total_amount'] ?? '0.00').toString()) ?? 0.0,
      createdAt: json['created_at'] ?? '',
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
  final String? institution;
  final double balance;
  final List<String> allergies;
  final List<PendingPreOrder> pendingOrders;
  final String identificationMethod;

  IdentifiedUser({
    required this.userId,
    this.studentId,
    required this.username,
    required this.fullName,
    required this.role,
    this.institution,
    required this.balance,
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
      institution: json['institution'] as String?,
      balance: double.tryParse((json['balance'] ?? '0.00').toString()) ?? 0.0,
      allergies: rawAllergies.map((a) => a.toString()).toList(),
      pendingOrders: rawPendingOrders
          .map((o) => PendingPreOrder.fromJson(o as Map<String, dynamic>))
          .toList(),
      identificationMethod: json['identification_method'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'student_id': studentId,
      'username': username,
      'full_name': fullName,
      'role': role,
      'institution': institution,
      'balance': balance.toStringAsFixed(2),
      'allergies': allergies,
      'identification_method': identificationMethod,
    };
  }
}
