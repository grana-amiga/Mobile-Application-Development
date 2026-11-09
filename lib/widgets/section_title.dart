import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título de seção com um texto opcional à direita ("Dados de exemplo").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingText = trailing;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.h2)),
          if (trailingText != null)
            Text(trailingText, style: AppText.small),
        ],
      ),
    );
  }
}
