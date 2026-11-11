import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';

/// Title of a section that has no card of its own ("Otros combos").
class DetailSectionHeading extends StatelessWidget {
  final String title;

  const DetailSectionHeading(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(title, style: AppText.cardTitle),
    );
  }
}
