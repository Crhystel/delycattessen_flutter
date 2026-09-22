class QrTokenModel {
  final String token;
  final int expiresIn;
  final String issuedAt;
  final int userId;
  final String fullName;
  final double balance;
  final String role;

  QrTokenModel({
    required this.token,
    required this.expiresIn,
    required this.issuedAt,
    required this.userId,
    required this.fullName,
    required this.balance,
    required this.role,
  });

  factory QrTokenModel.fromJson(Map<String, dynamic> json) {
    return QrTokenModel(
      token: json['token'] ?? '',
      expiresIn: json['expires_in'] ?? 60,
      issuedAt: json['issued_at'] ?? '',
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      balance: double.tryParse((json['balance'] ?? '0.00').toString()) ?? 0.0,
      role: json['role'] ?? '',
    );
  }
}
