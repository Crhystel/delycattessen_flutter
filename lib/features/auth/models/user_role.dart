/// Roles que el backend asigna al usuario. Los demás roles (por ejemplo el
/// padre) no se distinguen en la app y se resuelven como `null`.
enum UserRole {
  student('STUDENT'),
  teacher('TEACHER'),
  operationsStaff('OPERATIONS_STAFF');

  final String apiValue;
  const UserRole(this.apiValue);

  /// null si el servidor devuelve un rol que esta versión no conoce.
  static UserRole? fromApi(String? value) {
    for (final role in UserRole.values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}
