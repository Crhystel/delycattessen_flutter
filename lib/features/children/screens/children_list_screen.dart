import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../providers/children_provider.dart';
import 'child_detail_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen>
    with NotificationMixin {
  final _authService = AuthService();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChildrenProvider>().ensureLoaded());
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      setState(() {
        _userName = me.firstName.isNotEmpty
            ? me.firstName
            : (me.email != null && me.email!.isNotEmpty
                  ? me.email!.split('@').first
                  : 'Usuario');
      });
    } catch (_) {}
  }

  String _getTodaySpanish() {
    final now = DateTime.now();
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return days[now.weekday - 1];
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: Icons.logout,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que quieres cerrar tu sesión?',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
      confirmColor: AppColors.danger500,
    );
    if (confirmed) {
      _logout();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openChildDetail(Child child) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)),
        )
        .then((_) => context.read<ChildrenProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = context.watch<ChildrenProvider>();
    final children = childrenProvider.children;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const FloatingBubbles(corner: BubbleCorner.topRight),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => childrenProvider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola ${_userName.isNotEmpty ? _userName : "Usuario"}!',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hoy es ${_getTodaySpanish()}',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.ink900.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: AppColors.ink900,
                          ),
                          tooltip: 'Cerrar sesión',
                          onPressed: _confirmLogout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tus hijos',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (childrenProvider.isLoading &&
                        !childrenProvider.hasLoadedOnce)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary500,
                          ),
                        ),
                      )
                    else if (childrenProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          childrenProvider.errorMessage!,
                          style: GoogleFonts.nunito(color: AppColors.danger700),
                        ),
                      )
                    else if (children.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Aún no has registrado ningún hijo.',
                          style: GoogleFonts.nunito(
                            color: AppColors.ink900.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    else
                      ...children.map((c) => _buildChildCard(c)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StudentRegistrationScreen(),
                            ),
                          );
                          if (mounted) {
                            context.read<ChildrenProvider>().refresh();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'Añadir hijo/a',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        studentId: children.isNotEmpty ? children.first.id : null,
        onBeforeNavigate: (index) {
          if (children.isEmpty) {
            showWarningSnackBar(
              'Registra al menos un hijo para continuar.',
              title: 'Sin hijos registrados',
            );
            return false;
          }
          return true;
        },
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    final isLowBalance = child.balance != null && child.balance! < 5;
    return GestureDetector(
      onTap: () => _openChildDetail(child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.ink50,
              backgroundImage: child.profilePictureUrl != null
                  ? NetworkImage(child.profilePictureUrl!)
                  : null,
              child: child.profilePictureUrl == null
                  ? const Icon(Icons.person, color: AppColors.secondary500)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${child.firstName} ${child.lastName}',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.institutionName,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: isLowBalance
                            ? AppColors.danger500
                            : AppColors.success500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLowBalance ? 'Saldo bajo' : 'Activo',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLowBalance
                              ? AppColors.danger700
                              : AppColors.success700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLowBalance ? AppColors.dangerBg : AppColors.brand50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                child.balance != null
                    ? '\$${child.balance!.toStringAsFixed(2)}'
                    : '—',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isLowBalance
                      ? AppColors.danger700
                      : AppColors.brand700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }
}
