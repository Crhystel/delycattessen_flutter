class IdentifiedUser {
  final int userId;
  final int? studentId;
  final String username;
  final String fullName;
  final String role;
  final String? institution;
  final double balance;
  final List<String> allergies;
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
    required this.identificationMethod,
  });

  factory IdentifiedUser.fromJson(Map<String, dynamic> json) {
    var rawAllergies = json['allergies'] as List? ?? [];
    return IdentifiedUser(
      userId: json['user_id'] ?? 0,
      studentId: json['student_id'] as int?,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? '',
      institution: json['institution'] as String?,
      balance: double.tryParse((json['balance'] ?? '0.00').toString()) ?? 0.0,
      allergies: rawAllergies.map((a) => a.toString()).toList(),
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
