import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../children/screens/children_list_screen.dart';
import '../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/student_registration_screen.dart';

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
      _goTo(
        me.hasChildren
            ? const ChildrenListScreen()
            : const StudentRegistrationScreen(),
      );
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
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.secondary500),
      ),
    );
  }
}
