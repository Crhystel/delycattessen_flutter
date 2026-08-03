// Data Classes para Autenticación e Historias de Usuario

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

  /// Convierte el modelo a JSON para enviar a Django
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'telefono': phone, // Mapeado al nombre de campo de Django
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

  /// Convierte el modelo a JSON para enviar a Django
  Map<String, dynamic> toJson() {
    return {
      'nombres': firstName, // Mapeado al nombre de campo de Django
      'apellidos': lastName,
      'fecha_nacimiento': dateOfBirth, // Formato YYYY-MM-DD
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
