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

class TransactionModel {
  final int id;
  final String displayName;
  final double amount;
  final String gateway;
  final String status;
  final String type;
  final String time;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.displayName,
    required this.amount,
    required this.gateway,
    required this.status,
    required this.type,
    required this.time,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      amount: double.parse(json['amount'].toString()),
      gateway: json['gateway'] as String? ?? '',
      status: json['status'] as String,
      type: json['type'] as String,
      time: json['time'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
