import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/password_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../../core/widgets/password_requirements.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../utils/auth_routing.dart';

class ChangePasswordScreen extends StatefulWidget {
  final MeResponse me;
  final String usernameFallback;

  const ChangePasswordScreen({
    super.key,
    required this.me,
    required this.usernameFallback,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with NotificationMixin {
  final _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // Repinta la guía de requisitos mientras el usuario escribe.
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() => setState(() {});

  bool get _meetsPasswordPolicy => PasswordPolicy.rules.every(
    (rule) => rule.test(_newPasswordController.text),
  );

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      showWarningSnackBar(
        'Completa todos los campos.',
        title: 'Datos incompletos',
      );
      return;
    }
    if (!_meetsPasswordPolicy) {
      showWarningSnackBar(
        'La nueva contraseña no cumple los requisitos de seguridad.',
        title: 'Contraseña insegura',
      );
      return;
    }
    if (newPassword != confirm) {
      showWarningSnackBar(
        'Las contraseñas nuevas no coinciden.',
        title: 'No coinciden',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.changePassword(
        ChangePasswordRequest(
          currentPassword: current,
          newPassword: newPassword,
          confirmPassword: confirm,
        ),
      );
      if (!mounted) return;
      routeAfterAuth(
        context,
        widget.me,
        usernameFallback: widget.usernameFallback,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo actualizar la contraseña',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const FloatingBubbles(corner: BubbleCorner.topLeft),
            const FloatingBubbles(corner: BubbleCorner.bottomRight),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.lock_reset,
                        size: 48,
                        color: AppColors.brand500,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cambia tu contraseña',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Por seguridad, debes establecer una contraseña propia antes de continuar.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.ink900.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.teal500,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _buildField(
                              _currentPasswordController,
                              'Contraseña temporal',
                              obscure: _obscureCurrent,
                              onToggleObscure: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              _newPasswordController,
                              'Nueva contraseña',
                              obscure: _obscureNew,
                              onToggleObscure: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            PasswordRequirements(
                              password: _newPasswordController.text,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              _confirmPasswordController,
                              'Confirmar nueva contraseña',
                              obscure: _obscureConfirm,
                              onToggleObscure: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Guardar y continuar',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.nunito(color: AppColors.ink900),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.ink50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.ink900,
                ),
                onPressed: onToggleObscure,
              ),
      ),
    );
  }
}
