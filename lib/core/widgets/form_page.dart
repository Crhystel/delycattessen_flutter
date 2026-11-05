import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Frame of the form-like pages (profile, edit data): `ink50` background,
/// a light app bar that blends with it, content centered with a maximum width
/// on tablets, and a scrollable column so nothing overflows on small screens,
/// in landscape or with the keyboard open.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppTheme.lightAppBar(
        title: Text(title),
        backgroundColor: AppColors.ink50,
      ),
      body: ResponsiveCenter(
        maxWidth: AppLayout.formMaxWidth,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
