import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/auth_models.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  final Child child;
  final List<Child> allChildren;

  const ChildDetailScreen({
    super.key,
    required this.child,
    required this.allChildren,
  });

  void _goToWallet(BuildContext context) async {
    final withWallet = allChildren.where((c) => c.walletId != null).toList();
    if (child.walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este hijo aún no tiene billetera activa.'),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WalletRechargeScreen(
          children: withWallet
              .map(
                (c) => ChildOption(
                  walletId: c.walletId!,
                  name: '${c.firstName} ${c.lastName}',
                  currentBalance: c.balance ?? 0,
                  profilePictureUrl: c.profilePictureUrl,
                ),
              )
              .toList(),
          initialWalletId: child.walletId!,
        ),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 46,
              ),
              decoration: const BoxDecoration(color: AppColors.secondary500),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    backgroundImage: child.profilePictureUrl != null
                        ? NetworkImage(child.profilePictureUrl!)
                        : null,
                    child: child.profilePictureUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${child.firstName} ${child.lastName}',
                    style: GoogleFonts.nunito(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.institutionName,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saldo Actual',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(child.balance ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _goToWallet(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.teal500,
                            size: 18,
                          ),
                          label: Text(
                            'Recargar saldo',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Límite de gasto diario',
                    subtitle: '\$${(child.balance ?? 0) >= 5 ? '5.00' : '—'}',
                  ),
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Días permitidos de gasto',
                    subtitle: 'Pendiente de configurar',
                  ),
                  _buildSettingRow(
                    icon: Icons.warning_amber_outlined,
                    title: 'Alergias registradas',
                    subtitle: 'Pendiente de configurar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.ink900.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.settings_outlined,
            color: Color(0xFFBBBBBB),
            size: 18,
          ),
        ],
      ),
    );
  }
}
