import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/auth_routing.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

/// Shown on app start. Checks whether a valid session already exists
/// (refreshing the access token if needed) and routes accordingly, so the
/// user isn't sent back to login every time the app process is killed
/// and reopened (e.g. from Android's recent apps list).
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final refreshed = await _authService.tryRefreshToken();
    if (!mounted) return;

    if (!refreshed) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      final usernameFallback = me.email ?? '';

      // Mismo criterio que el login: una sesión con contraseña temporal
      // debe pasar por el cambio obligatorio antes de entrar a la app.
      if (me.mustChangePassword) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
              me: me,
              usernameFallback: usernameFallback,
            ),
          ),
          (route) => false,
        );
        return;
      }

      routeAfterAuth(context, me, usernameFallback: usernameFallback);
    } catch (_) {
      if (!mounted) return;
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink50,
      body: Center(child: CircularProgressIndicator(color: AppColors.teal500)),
    );
  }
}
