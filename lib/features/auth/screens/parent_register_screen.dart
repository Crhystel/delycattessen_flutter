import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'student_registration_screen.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.registerParent(
        ParentRegistration(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirm: _confirmController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
      );
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildFloatingBubbles(alignTop: true),
          _buildFloatingBubbles(alignTop: false),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Registrarse',
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.teal700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _field(_emailController, 'E-mail'),
                          const SizedBox(height: 12),
                          _field(
                            _passwordController,
                            'Contraseña',
                            obscure: _obscurePassword,
                            onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _confirmController,
                            'Confirmar Contraseña',
                            obscure: _obscureConfirm,
                            onToggleObscure: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _next,
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
                                      'Siguiente',
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
    );
  }

  Widget _field(
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

  Widget _buildFloatingBubbles({required bool alignTop}) {
    return Positioned(
      top: alignTop ? -100 : null,
      bottom: alignTop ? null : -100,
      left: alignTop ? -70 : null,
      right: alignTop ? null : -70,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final offset =
              14 * (_floatController.value - 0.5) * (alignTop ? 1 : -1);
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: [
              Positioned(
                left: alignTop ? 0 : null,
                right: alignTop ? null : 0,
                top: alignTop ? 0 : null,
                bottom: alignTop ? null : 0,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    color: AppColors.teal700,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: alignTop ? 110 : null,
                right: alignTop ? null : 110,
                top: alignTop ? 0 : null,
                bottom: alignTop ? null : 0,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    color: AppColors.brand500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
