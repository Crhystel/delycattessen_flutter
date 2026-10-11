import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../providers/children_provider.dart';
import 'child_detail_screen.dart';

const double _lowBalanceThreshold = 5;

class ChildrenListScreen extends StatefulWidget {
  /// Lo llama el ParentShell: elige al hijo y lleva a la pestaña Menú.
  final void Function(int childId)? onOrderForChild;

  const ChildrenListScreen({super.key, this.onOrderForChild});

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
    final provider = context.read<ChildrenProvider>();
    Future.microtask(provider.ensureLoaded);
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
    final provider = context.read<ChildrenProvider>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)),
        )
        .then((_) => provider.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = context.watch<ChildrenProvider>();
    final children = childrenProvider.children;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      bubbleCorner: BubbleCorner.topRight,
      body: RefreshIndicator(
        onRefresh: () => childrenProvider.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola ${_userName.isNotEmpty ? _userName : "Usuario"}!',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTodaySpanish(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink900.withValues(alpha: 0.7),
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
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tus hijos',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (childrenProvider.isLoading && !childrenProvider.hasLoadedOnce)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.secondary500),
                  ),
                )
              else if (childrenProvider.errorMessage != null)
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'No pudimos cargar tus hijos',
                  message: childrenProvider.errorMessage,
                  actionLabel: 'Reintentar',
                  onAction: () => childrenProvider.refresh(),
                )
              else if (children.isEmpty)
                const EmptyState(
                  icon: Icons.backpack_outlined,
                  title: 'Aún no has registrado ningún hijo',
                  message: 'Añade a tu primer hijo/a para empezar a pedir.',
                )
              else
                ...children.map((c) => _buildChildCard(c)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final provider = context.read<ChildrenProvider>();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudentRegistrationScreen(),
                      ),
                    );
                    provider.refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Añadir hijo/a',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    final textTheme = Theme.of(context).textTheme;
    final isLowBalance =
        child.balance != null && child.balance! < _lowBalanceThreshold;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => _openChildDetail(child),
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  child.institutionName,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isLowBalance ? AppColors.dangerBg : AppColors.brand50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              child.balance != null
                  ? '\$${child.balance!.toStringAsFixed(2)}'
                  : '—',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isLowBalance
                    ? AppColors.danger700
                    : AppColors.brand700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }
}
