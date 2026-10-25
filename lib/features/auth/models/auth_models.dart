import 'user_role.dart';

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
  final String code;
  final String newPassword;
  final String confirmPassword;

  PasswordResetConfirm({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}

class MeResponse {
  final int id;
  final String? email;
  final String firstName;
  final String secondName;
  final String lastName;
  final String secondLastName;
  final String role;
  final bool hasChildren;
  final bool hasPaymentPin;
  final bool mustChangePassword;

  MeResponse({
    required this.id,
    this.email,
    required this.firstName,
    this.secondName = '',
    required this.lastName,
    this.secondLastName = '',
    required this.role,
    required this.hasChildren,
    required this.hasPaymentPin,
    required this.mustChangePassword,
  });

  UserRole? get userRole => UserRole.fromApi(role);

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] as int,
      email: json['email'] as String?,
      firstName: json['first_name'] as String? ?? '',
      secondName: json['second_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      secondLastName: json['second_last_name'] as String? ?? '',
      role: json['role'] as String? ?? UserRole.student.apiValue,
      hasChildren: json['has_children'] as bool? ?? false,
      hasPaymentPin: json['has_payment_pin'] as bool? ?? false,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }
}

class Child {
  final int id;
  final String firstName;
  final String secondName;
  final String lastName;
  final String secondLastName;
  final String username;
  final String institutionName;
  final String? profilePictureUrl;
  final double? balance;
  final int? walletId;

  Child({
    required this.id,
    required this.firstName,
    this.secondName = '',
    required this.lastName,
    this.secondLastName = '',
    this.username = '',
    required this.institutionName,
    this.profilePictureUrl,
    this.balance,
    this.walletId,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      secondName: json['second_name'] as String? ?? '',
      lastName: json['last_name'] as String,
      secondLastName: json['second_last_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      institutionName: json['institution_name'] as String? ?? '',
      profilePictureUrl: json['profile_picture'] as String?,
      balance: json['balance'] != null
          ? double.tryParse(json['balance'].toString())
          : null,
      walletId: json['wallet_id'] as int?,
    );
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}

/// Four name parts as the backend stores them (`last_name` is the first
/// surname). Shared by the profile edits of parents, teachers and children.
class PersonNames {
  final String firstName;
  final String secondName;
  final String lastName;
  final String secondLastName;

  const PersonNames({
    required this.firstName,
    required this.lastName,
    this.secondName = '',
    this.secondLastName = '',
  });

  /// Error message for the user, or null when the names are valid.
  String? validate() {
    if (firstName.trim().isEmpty) return 'Ingresa el primer nombre.';
    if (lastName.trim().isEmpty) return 'Ingresa el primer apellido.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName.trim(),
    'second_name': secondName.trim(),
    'last_name': lastName.trim(),
    'second_last_name': secondLastName.trim(),
  };
}

/// Body of `PATCH /api/users/me/profile/` (parent or teacher).
class ProfileUpdate {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final PersonNames names;
  final String email;

  const ProfileUpdate({required this.names, required this.email});

  String? validate() {
    final namesError = names.validate();
    if (namesError != null) return namesError;
    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    ...names.toJson(),
    'email': email.trim().toLowerCase(),
  };
}

/// Body of `PATCH /api/users/children/<id>/` (the parent edits a child).
class ChildProfileUpdate {
  final PersonNames names;
  final String username;

  const ChildProfileUpdate({required this.names, required this.username});

  String? validate() {
    final namesError = names.validate();
    if (namesError != null) return namesError;
    if (username.trim().isEmpty) return 'Ingresa el nombre de usuario.';
    if (username.trim().contains(' ')) {
      return 'El nombre de usuario no puede tener espacios.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    ...names.toJson(),
    'username': username.trim(),
  };
}
