import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../../children/screens/parent_shell.dart';
import '../screens/student_registration_screen.dart';
import '../../pos/screens/pos_home_screen.dart';
import '../../contingency/screens/student_contingency_screen.dart';

/// Decide a qué pantalla ir tras una autenticación exitosa (login normal o
/// tras completar el cambio obligatorio de contraseña), según el rol y el
/// estado del usuario. Vive aparte de LoginScreen para no duplicar esta
/// lógica en cada lugar que necesite rutear tras autenticar.
void routeAfterAuth(
  BuildContext context,
  MeResponse me, {
  required String usernameFallback,
}) {
  if (me.role == 'OPERATIONS_STAFF') {
    final displayName = me.firstName.isNotEmpty
        ? me.firstName
        : (usernameFallback.isNotEmpty
              ? usernameFallback.split('@').first
              : 'Usuario');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => PosHomeScreen(userName: displayName)),
      (route) => false,
    );
  } else if (me.role == 'STUDENT' || me.role == 'TEACHER') {
    final fallbackName = me.role == 'TEACHER' ? 'Docente' : 'Estudiante';
    final displayName = me.firstName.isNotEmpty
        ? '${me.firstName} ${me.lastName}'.trim()
        : (usernameFallback.isNotEmpty ? usernameFallback : fallbackName);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentContingencyScreen(initialUserName: displayName),
      ),
      (route) => false,
    );
  } else if (me.hasChildren) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ParentShell()),
      (route) => false,
    );
  } else {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
      (route) => false,
    );
  }
}
