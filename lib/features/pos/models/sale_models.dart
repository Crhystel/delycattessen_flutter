import '../../wallet/models/wallet_models.dart';

/// Métodos de pago que acepta `POST /api/pos/sales/`.
enum PaymentMethod {
  cash('CASH'),
  credit('CREDIT'),
  wallet('WALLET');

  final String apiValue;
  const PaymentMethod(this.apiValue);

  /// Resuelve el valor del backend; null si es desconocido (sin lanzar).
  static PaymentMethod? fromApi(String? value) {
    for (final method in PaymentMethod.values) {
      if (method.apiValue == value) return method;
    }
    return null;
  }
}

class SaleItemInput {
  final int menuItemId;
  final int quantity;

  const SaleItemInput({required this.menuItemId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'menu_item_id': menuItemId,
    'quantity': quantity,
  };
}

/// Combo sold as one line at its fixed price.
class SaleComboInput {
  final int comboId;
  final int quantity;

  const SaleComboInput({required this.comboId, required this.quantity});

  Map<String, dynamic> toJson() => {'combo_id': comboId, 'quantity': quantity};
}

/// Payload de `POST /api/pos/sales/`. Sin [userId] es una venta rápida
/// (solo efectivo); el precio lo calcula el servidor.
class SaleRequest {
  final PaymentMethod paymentMethod;
  final int? userId;
  final List<SaleItemInput> items;
  final List<SaleComboInput> combos;

  const SaleRequest({
    required this.paymentMethod,
    required this.items,
    this.combos = const [],
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'payment_method': paymentMethod.apiValue,
    if (userId != null) 'user_id': userId,
    'items': items.map((i) => i.toJson()).toList(),
    if (combos.isNotEmpty) 'combos': combos.map((c) => c.toJson()).toList(),
  };
}

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

double _parseAmount(Object? value) =>
    double.tryParse((value ?? '0.00').toString()) ?? 0.0;

/// Venta registrada (respuesta de `/pos/sales/` y filas de crédito).
/// Las líneas reutilizan [TransactionItemDetail], que ya lee `menu_item_name`.
class Sale {
  final int id;
  final PaymentMethod? paymentMethod;
  final double totalAmount;
  final DateTime createdAt;

  /// Resumen y hora calculados por el backend (`LineSummaryMixin`).
  final String displayName;
  final String time;
  final List<TransactionItemDetail> items;

  const Sale({
    required this.id,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.displayName,
    required this.time,
    required this.items,
  });

  static const String _fallbackName = 'Compra a crédito';

  factory Sale.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return Sale(
      id: json['id'] as int? ?? 0,
      paymentMethod: PaymentMethod.fromApi(json['payment_method'] as String?),
      totalAmount: _parseAmount(json['total_amount']),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      displayName: _nonEmpty(json['display_name']) ?? _fallbackName,
      time: _nonEmpty(json['time']) ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(TransactionItemDetail.fromJson)
          .toList(),
    );
  }

  /// Adaptador al formato de movimientos para reutilizar el historial.
  TransactionModel toTransaction() => TransactionModel.fromSale(
    id: id,
    displayName: displayName,
    time: time,
    amount: totalAmount,
    createdAt: createdAt,
    items: items,
  );
}

/// Respuesta de `GET /api/pos/credit/history/`.
class CreditHistory {
  final String month; // "YYYY-MM"
  final double accumulatedTotal;
  final List<Sale> sales;

  const CreditHistory({
    required this.month,
    required this.accumulatedTotal,
    required this.sales,
  });

  factory CreditHistory.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List? ?? [];
    return CreditHistory(
      month: json['month'] as String? ?? '',
      accumulatedTotal: _parseAmount(json['accumulated_total']),
      sales: results
          .whereType<Map<String, dynamic>>()
          .map(Sale.fromJson)
          .toList(),
    );
  }
}
