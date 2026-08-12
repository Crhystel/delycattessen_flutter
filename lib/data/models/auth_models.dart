// Data classes for Authentication and User Stories

class ParentRegistration {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;

  ParentRegistration({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  /// Converts the model to JSON to send to Django
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'telefono': phone, // Mapped to Django's field name
    };
  }
}

class StudentRegistration {
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final int institutionId;

  StudentRegistration({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.institutionId,
  });

  /// Converts the model to JSON to send to Django
  Map<String, dynamic> toJson() {
    return {
      'nombres': firstName, // Mapped to Django's field name
      'apellidos': lastName,
      'fecha_nacimiento': dateOfBirth, // YYYY-MM-DD format
      'institucion_id': institutionId,
    };
  }
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

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'token': token,
      'new_password': newPassword,
    };
  }
}
