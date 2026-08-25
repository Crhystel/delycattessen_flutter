class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LoginResponse {
  final String access;
  final String refresh;

  LoginResponse({required this.access, required this.refresh});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }
}

class ParentRegistration {
  final String email;
  final String password;
  final String passwordConfirm;

  ParentRegistration({
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'password_confirm': passwordConfirm,
  };
}

class Institution {
  final int id;
  final String name;

  Institution({required this.id, required this.name});

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(id: json['id'] as int, name: json['name'] as String);
  }
}

class StudentRegistration {
  final String firstName;
  final String secondName;
  final String firstLastName;
  final String secondLastName;
  final int institutionId;
  final String username;
  final String password;
  final String profilePicturePath;

  StudentRegistration({
    required this.firstName,
    this.secondName = '',
    required this.firstLastName,
    this.secondLastName = '',
    required this.institutionId,
    required this.username,
    required this.password,
    required this.profilePicturePath,
  });

  Map<String, String> toFields() => {
    'first_name': firstName,
    'second_name': secondName,
    'first_last_name': firstLastName,
    'second_last_name': secondLastName,
    'institution_id': institutionId.toString(),
    'username': username,
    'password': password,
  };
}

class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class PasswordResetConfirm {
  final String email;
  final String token;
  final String newPassword;

  PasswordResetConfirm({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'token': token,
    'new_password': newPassword,
  };
}

class MeResponse {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool hasChildren;
  final bool hasPaymentPin;

  MeResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.hasChildren,
    required this.hasPaymentPin,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String,
      hasChildren: json['has_children'] as bool,
      hasPaymentPin: json['has_payment_pin'] as bool,
    );
  }
}

class Child {
  final int id;
  final String firstName;
  final String lastName;
  final String institutionName;
  final String? profilePictureUrl;
  final double? balance;
  final int? walletId;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.institutionName,
    this.profilePictureUrl,
    this.balance,
    this.walletId,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      institutionName: json['institution_name'] as String? ?? '',
      profilePictureUrl: json['profile_picture'] as String?,
      balance: json['balance'] != null
          ? double.tryParse(json['balance'].toString())
          : null,
      walletId: json['wallet_id'] as int?,
    );
  }
}
