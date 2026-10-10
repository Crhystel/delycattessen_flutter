import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../models/qr_token_model.dart';
import '../services/qr_service.dart';

class StudentContingencyScreen extends StatefulWidget {
  final String? initialUserName;
  const StudentContingencyScreen({super.key, this.initialUserName});

  @override
  State<StudentContingencyScreen> createState() =>
      _StudentContingencyScreenState();
}

class _StudentContingencyScreenState extends State<StudentContingencyScreen> {
  final QrService _qrService = QrService();
  QrTokenModel? _qrData;
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _secondsLeft = 300;

  @override
  void initState() {
    super.initState();
    _loadQrToken();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')} min';
    }
    return '${s}s';
  }

  void _startTimer(int totalSeconds) {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = totalSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        _loadQrToken(silent: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _loadQrToken({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _qrService.getDynamicQrToken();
      if (mounted) {
        setState(() {
          _qrData = data;
          _isLoading = false;
        });
        _startTimer(data.expiresIn > 0 ? data.expiresIn : 300);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _getCurrentDayFormatted() {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final now = DateTime.now();
    final dayName = days[now.weekday - 1];
    return 'Hoy es $dayName';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: Icons.logout,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas salir de tu cuenta de estudiante?',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
    );
    if (confirmed) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = _qrData?.fullName.isNotEmpty == true
        ? _qrData!.fullName
        : (widget.initialUserName ?? 'Usuario');
    final balanceText = _qrData != null
        ? '\$${_qrData!.balance.toStringAsFixed(2)}'
        : '\$0.00';

    return AppScaffold(
      bubbleCorner: BubbleCorner.topRight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola $displayName',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCurrentDayFormatted(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.teal700),
                  tooltip: 'Cerrar sesión',
                  onPressed: _confirmLogout,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl - 4),
              decoration: BoxDecoration(
                color: AppColors.teal500,
                borderRadius: AppRadius.mdAll,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal500.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Saldo actual',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    balanceText,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Center(
              child: Text(
                'Tu código QR',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // White card with the dynamic QR (always black on white to scan)
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl - 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdAll,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildQrContent(textTheme),
              ),
            ),
            const SizedBox(height: AppSpacing.xl - 4),

            // Security badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md - 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.warning500.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.warning700,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Este código es único y personal.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.warning700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent(TextTheme textTheme) {
    if (_isLoading) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger500,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _loadQrToken(),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        QrImageView(
          data: _qrData!.token,
          version: QrVersions.auto,
          size: 190.0,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Se actualiza en ${_formatTimer(_secondsLeft)}',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink900.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
