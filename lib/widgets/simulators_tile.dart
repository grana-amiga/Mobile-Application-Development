import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../theme/app_theme.dart';

/// Cartão que abre a tela de simuladores (poupança e juros).
/// Usado na aba Aprender e na tela inicial.
class SimulatorsTile extends StatelessWidget {
  const SimulatorsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.yellowSoft,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.pushNamed(context, AppRoutes.simulators),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.card,
                child: Icon(Icons.calculate, color: AppColors.petrol, size: 30),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simuladores', style: AppText.h3),
                    SizedBox(height: 2),
                    Text(
                      'Veja quanto o dinheiro rende ou quanto uma dívida cresce.',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.chevron_right, color: AppColors.petrol, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
