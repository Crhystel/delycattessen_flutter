import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  final _authService = AuthService();
  List<Child> _children = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final children = await _authService.getChildren();
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openWallet([Child? preselected]) {
    final withWallet = _children.where((c) => c.walletId != null).toList();
    if (withWallet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ningún hijo tiene billetera activa todavía.'),
        ),
      );
      return;
    }
    final target = preselected ?? withWallet.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletRechargeScreen(
          children: withWallet
              .map(
                (c) => ChildOption(
                  walletId: c.walletId!,
                  name: '${c.firstName} ${c.lastName}',
                  currentBalance: c.balance ?? 0,
                ),
              )
              .toList(),
          initialWalletId: target.walletId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChildren,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola!',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tus hijos',
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary500,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.nunito(color: AppColors.danger700),
                    ),
                  )
                else if (_children.isEmpty)
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
                  ..._children.map((c) => _buildChildCard(c)),
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
                      _loadChildren();
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
      bottomNavigationBar: Container(
        color: AppColors.brand500,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.attach_money, color: Colors.white),
                onPressed: () => _openWallet(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    final isLowBalance = child.balance != null && child.balance! < 5;
    return GestureDetector(
      onTap: () => _openWallet(child),
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
