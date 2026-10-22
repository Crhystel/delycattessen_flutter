import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
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
import '../../menu/models/menu_models.dart';
import '../../menu/services/menu_service.dart';
import '../providers/children_provider.dart';
import 'child_detail_screen.dart';

const double _lowBalanceThreshold = 5;

class ChildrenListScreen extends StatefulWidget {
  /// Lo llama el ParentShell: elige al hijo y lleva a la pestaña Menú.
  final void Function(int childId)? onOrderForChild;

  /// Abre la pestaña Menú con un día preseleccionado.
  final void Function(int childId, DateTime date)? onOpenMenuDay;

  const ChildrenListScreen({
    super.key,
    this.onOrderForChild,
    this.onOpenMenuDay,
  });

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen>
    with NotificationMixin {
  final _authService = AuthService();
  final _menuService = MenuService();
  String _userName = '';

  MenuDay? _firstAvailableMenuDay;
  bool _isLoadingMenuDay = false;
  int? _loadedStudentId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChildrenProvider>();
    Future.microtask(() async {
      await provider.ensureLoaded();
      _syncMenuPreview();
    });
    _loadUserName();
  }

  void _syncMenuPreview() {
    final provider = context.read<ChildrenProvider>();
    final child =
        provider.selectedChild ??
        (provider.children.isNotEmpty ? provider.children.first : null);
    if (child != null && child.id != _loadedStudentId) {
      _loadMonthlyMenuPreview(child.id);
    }
  }

  Future<void> _loadMonthlyMenuPreview(int studentId) async {
    _loadedStudentId = studentId;
    setState(() => _isLoadingMenuDay = true);
    try {
      final days = await _menuService.getStudentMonthlyMenu(studentId);
      if (!mounted) return;
      final availableDay = days.where((d) => d.dishes.isNotEmpty).firstOrNull;
      setState(() {
        _firstAvailableMenuDay = availableDay;
        _isLoadingMenuDay = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _firstAvailableMenuDay = null;
        _isLoadingMenuDay = false;
      });
    }
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

  void _navigateToMenu({required int studentId, DateTime? date}) {
    if (date != null && widget.onOpenMenuDay != null) {
      widget.onOpenMenuDay!(studentId, date);
    } else if (widget.onOrderForChild != null) {
      widget.onOrderForChild!(studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = context.watch<ChildrenProvider>();
    final children = childrenProvider.children;
    final textTheme = Theme.of(context).textTheme;

    // Si cambiaron los hijos o el seleccionado, sincronizar preview
    final currentTarget =
        childrenProvider.selectedChild ??
        (children.isNotEmpty ? children.first : null);
    if (currentTarget != null &&
        currentTarget.id != _loadedStudentId &&
        !_isLoadingMenuDay) {
      Future.microtask(() => _loadMonthlyMenuPreview(currentTarget.id));
    }

    return AppScaffold(
      bubbleCorner: BubbleCorner.topRight,
      body: RefreshIndicator(
        onRefresh: () async {
          await childrenProvider.refresh();
          if (currentTarget != null) {
            await _loadMonthlyMenuPreview(currentTarget.id);
          }
        },
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
                    child: CircularProgressIndicator(
                      color: AppColors.secondary500,
                    ),
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
              if (children.isNotEmpty && currentTarget != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildMonthlyMenuSection(currentTarget, textTheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Fila de platillos con columnas fijas (3 en teléfono, 5 en tablet): si
  /// hay menos platillos, los espacios sobrantes quedan vacíos para que las
  /// tarjetas no se estiren.
  Widget _buildDishPreviewRow(MenuDay day, int childId) {
    final slots = AppLayout.isTablet(context) ? 5 : 3;
    final dishes = day.dishes.take(slots).toList();
    final parsedDate = DateFormatter.parseIsoDate(day.date);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots; i++)
          Expanded(
            child: i < dishes.length
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildDishPreviewCard(
                      dishes[i],
                      childId,
                      parsedDate,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildMonthlyMenuSection(Child child, TextTheme textTheme) {
    final day = _firstAvailableMenuDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menú Mensual',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink900,
          ),
        ),
        if (day != null) ...[
          const SizedBox(height: 2),
          Text(
            'Para el ${DateFormatter.formatLong(DateFormatter.parseIsoDate(day.date))}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.ink900.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (_isLoadingMenuDay)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary500,
                ),
              ),
            ),
          )
        else if (day == null || day.dishes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aún no hay menú publicado.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          _buildDishPreviewRow(day, child.id),
      ],
    );
  }

  Widget _buildDishPreviewCard(MenuDish dish, int studentId, DateTime date) {
    return GestureDetector(
      onTap: () => _navigateToMenu(studentId: studentId, date: date),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: dish.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: dish.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: AppImageCacheHelper.cacheSize(
                          context,
                          120,
                        ),
                        memCacheHeight: AppImageCacheHelper.cacheSize(
                          context,
                          120,
                        ),
                        placeholder: (_, _) => Container(
                          color: AppColors.ink50,
                          child: const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.secondary500,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.ink50,
                          child: const Icon(
                            Icons.fastfood,
                            color: AppColors.secondary500,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.ink50,
                        child: const Icon(
                          Icons.fastfood,
                          color: AppColors.secondary500,
                          size: 24,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${dish.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    final textTheme = Theme.of(context).textTheme;
    final isLowBalance =
        child.balance != null && child.balance! < _lowBalanceThreshold;
    final avatarSize = AppImageCacheHelper.cacheSize(context, 52);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => _openChildDetail(child),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.ink50,
            backgroundImage: child.profilePictureUrl != null
                ? ResizeImage(
                    CachedNetworkImageProvider(child.profilePictureUrl!),
                    width: avatarSize,
                    height: avatarSize,
                  )
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  child.institutionName,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
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
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isLowBalance ? AppColors.danger700 : AppColors.brand700,
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
