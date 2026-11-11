import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// "Pidiendo para" row of the dish detail: the initials and name of the child
/// the order is for, and "Cambiar". The whole row calls [onChange].
class ChildOrderingRow extends StatelessWidget {
  final String name;
  final VoidCallback onChange;

  const ChildOrderingRow({
    super.key,
    required this.name,
    required this.onChange,
  });

  static const double _minHeight = 64;
  static const double _avatarSize = 44;

  /// First letter of the first two words, in capitals ("Pepito Pérez" -> "PP").
  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cambiar hijo. Pidiendo para $name',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rowAll,
          side: const BorderSide(color: AppColors.lineStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onChange,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.teal50,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(name),
                      style: AppText.infoValue.copyWith(
                        color: AppColors.teal700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pidiendo para', style: AppText.caption),
                        Text(name, style: AppText.itemTitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Cambiar', style: AppText.link),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
