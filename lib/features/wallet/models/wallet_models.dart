import '../../../core/utils/date_formatter.dart';

class RechargeRequest {
  final int walletId;
  final double amount;
  final String? kushkiToken;
  final String? documentType;
  final String? documentNumber;
  final String? phoneNumber;

  RechargeRequest({
    required this.walletId,
    required this.amount,
    this.kushkiToken,
    this.documentNumber,
    this.phoneNumber,
    this.documentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'amount': amount,
      if (kushkiToken != null) 'kushki_token': kushkiToken,
      if (documentType != null) 'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }
}

class RechargeResponse {
  final int? transactionId;
  final String? paymentUrl;
  final String? detail;

  RechargeResponse({this.transactionId, this.paymentUrl, this.detail});

  factory RechargeResponse.fromJson(Map<String, dynamic> json) {
    return RechargeResponse(
      transactionId: json['transaction_id'] as int?,
      paymentUrl: json['payment_url'] as String?,
      detail: json['detail'] as String?,
    );
  }

  bool get isProcessingAsync => paymentUrl == null;
}

class TransactionItemDetail {
  final String dishName;
  final int quantity;
  final double priceAtPurchase;

  TransactionItemDetail({
    required this.dishName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  String get menuItemName => dishName;

  factory TransactionItemDetail.fromJson(Map<String, dynamic> json) {
    return TransactionItemDetail(
      dishName: (json['dish_name'] ?? json['menu_item_name'] ?? 'Platillo')
          .toString(),
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase:
          double.tryParse((json['price_at_purchase'] ?? '0.00').toString()) ??
          0.0,
    );
  }
}

/// Naturaleza de un movimiento: entra saldo (recarga) o sale (consumo).
enum TransactionKind { recharge, consumption }

class TransactionModel {
  final int id;
  final String displayName;
  final double amount;
  final String gateway;
  final String status;
  final String type;
  final String time;
  final DateTime createdAt;
  final List<TransactionItemDetail> items;

  TransactionModel({
    required this.id,
    required this.displayName,
    required this.amount,
    required this.gateway,
    required this.status,
    required this.type,
    required this.time,
    required this.createdAt,
    required this.items,
  });

  TransactionKind get kind => type == 'recharge'
      ? TransactionKind.recharge
      : TransactionKind.consumption;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return TransactionModel(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      amount: double.parse(json['amount'].toString()),
      gateway: json['gateway'] as String? ?? '',
      status: json['status'] as String,
      type: json['type'] as String,
      time: json['time'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsList
          .map((i) => TransactionItemDetail.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Adapta una venta del POS (p. ej. a crédito) al formato de movimientos.
  /// [time] es la hora que envía el backend; se antepone la fecha porque el
  /// historial de crédito abarca varios días.
  factory TransactionModel.fromSale({
    required int id,
    required String displayName,
    required String time,
    required double amount,
    required DateTime createdAt,
    required List<TransactionItemDetail> items,
  }) {
    final local = createdAt.toLocal();
    final date = DateFormatter.formatShort(local);
    return TransactionModel(
      id: id,
      displayName: displayName,
      amount: amount,
      gateway: '',
      status: 'success',
      type: 'consumption',
      time: time.isEmpty ? date : '$date · $time',
      createdAt: local,
      items: items,
    );
  }
}
