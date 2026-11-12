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

  /// Only built after the terms checkbox was ticked; the backend records the
  /// accepted version and date as legal evidence.
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'password_confirm': passwordConfirm,
    'accept_terms': true,
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
    'accept_terms': 'true',
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

  PersonNames get names => PersonNames(
    firstName: firstName,
    secondName: secondName,
    lastName: lastName,
    secondLastName: secondLastName,
  );

  /// First name and first surname, for greetings and summaries.
  String get displayName => _joinWords([firstName, lastName]);

  /// The four name parts, for the profile list.
  String get fullName =>
      _joinWords([firstName, secondName, lastName, secondLastName]);

  static String _joinWords(List<String> parts) =>
      parts.where((part) => part.trim().isNotEmpty).join(' ');

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

  /// Monto bajo el cual el padre quiere que se le avise de saldo bajo
  /// (control parental). Nulo si no activó el aviso o el backend aún no lo envía.
  final double? lowBalanceAlertAmount;

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
    this.lowBalanceAlertAmount,
  });

  /// Umbral de saldo bajo cuando el padre no configuró uno propio.
  static const double defaultLowBalanceAmount = 5;

  /// Saldo bajo según el aviso del padre o, si no lo activó, el umbral fijo.
  bool get hasLowBalance =>
      balance != null &&
      balance! < (lowBalanceAlertAmount ?? defaultLowBalanceAmount);

  /// Nombre y primer apellido, para tarjetas y listas.
  String get displayName => '$firstName $lastName'.trim();

  /// Primera letra del nombre y del primer apellido ("Pepito Pérez" -> "PP").
  String get initials {
    final letters = [firstName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.trim().substring(0, 1));
    return letters.join().toUpperCase();
  }

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
      lowBalanceAlertAmount: json['low_balance_alert_amount'] != null
          ? double.tryParse(json['low_balance_alert_amount'].toString())
          : null,
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

/// Body of `PATCH /api/users/me/profile/` (parent or teacher). Changing the
/// email also needs [currentPassword]: the backend rejects it otherwise.
class ProfileUpdate {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final PersonNames names;
  final String email;
  final String? currentPassword;

  const ProfileUpdate({
    required this.names,
    required this.email,
    this.currentPassword,
  });

  static bool isValidEmail(String email) =>
      _emailPattern.hasMatch(email.trim());

  String? validate() {
    final namesError = names.validate();
    if (namesError != null) return namesError;
    if (!isValidEmail(email)) return 'Ingresa un correo válido.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    ...names.toJson(),
    'email': email.trim().toLowerCase(),
    if (currentPassword != null) 'current_password': currentPassword,
  };
}

/// Body of `PATCH /api/users/children/<id>/` (the parent edits a child). The
/// names and the username have their own screens, so each one sends only what
/// it changes (the backend applies a partial update).
class ChildProfileUpdate {
  final PersonNames? names;
  final String? username;

  const ChildProfileUpdate.names(PersonNames this.names) : username = null;

  const ChildProfileUpdate.username(String this.username) : names = null;

  String? validate() {
    final names = this.names;
    if (names != null) return names.validate();
    final name = username?.trim() ?? '';
    if (name.isEmpty) return 'Ingresa el nombre de usuario.';
    if (name.contains(' ')) {
      return 'El nombre de usuario no puede tener espacios.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (names != null) ...names!.toJson(),
    if (username != null) 'username': username!.trim(),
  };
}

/// Body of `POST /api/users/children/<id>/password/`: the parent sets the
/// password of their child and confirms with their own (the child's current
/// one is not known to the parent).
class ChildPasswordChange {
  final String parentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChildPasswordChange({
    required this.parentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'parent_password': parentPassword,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}
