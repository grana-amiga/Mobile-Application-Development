import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Etiqueta pequena e arredondada ("Bem fácil", "Vence em 5 dias"...).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.background = AppColors.peachSoft,
    this.foreground = AppColors.petrol,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
