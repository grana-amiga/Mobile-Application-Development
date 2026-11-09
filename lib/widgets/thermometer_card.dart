import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/money_summary.dart';
import '../theme/app_theme.dart';

/// "Termômetro do Dinheiro": mostra se o orçamento está Tranquilo, em Atenção
/// ou Urgente, de acordo com quanto da renda já foi gasto.
///
/// A situação é comunicada por cor + ícone de rosto + texto.
class ThermometerCard extends StatelessWidget {
  const ThermometerCard({super.key, required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final level = summary.level;
    final percent = (summary.commitment * 100).round();

    // Semantics descreve o widget para leitores de tela (TalkBack/VoiceOver).
    return Semantics(
      label:
          'Termômetro do Dinheiro: ${level.label}. ${level.message} '
          'Você já usou $percent por cento da renda.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecor.card(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: level.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(level.icon, color: level.onColor, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Termômetro do Dinheiro', style: AppText.small),
                      Text(level.label, style: AppText.h1.copyWith(fontSize: 26)),
                      Text(level.message, style: AppText.body),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Gauge(commitment: summary.commitment),
            const SizedBox(height: 8),
            Text(
              'Já saiu $percent% do dinheiro que entrou '
              '(${formatBRL(summary.expenses)} de ${formatBRL(summary.income)})',
              style: AppText.small,
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra com 3 faixas (verde, amarela, tijolo) e um marcador na posição atual.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.commitment});

  final double commitment;

  @override
  Widget build(BuildContext context) {
    final position = commitment.clamp(0.0, 1.0);

    // LayoutBuilder entrega a largura disponível, necessária para colocar o
    // marcador na posição certa dentro da barra.
    return LayoutBuilder(
      builder: (context, constraints) {
        const markerSize = 22.0;
        final left = (constraints.maxWidth - markerSize) * position;
        return SizedBox(
          height: markerSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: const [
                      Expanded(flex: 70, child: ColoredBox(color: AppColors.green)),
                      Expanded(flex: 20, child: ColoredBox(color: AppColors.yellow)),
                      Expanded(flex: 10, child: ColoredBox(color: AppColors.brick)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: left,
                child: Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.petrol, width: 4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
