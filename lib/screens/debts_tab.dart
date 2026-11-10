import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/debt.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/mascot.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

/// Tela 6: Plano de quitação.
///
/// Lista as dívidas ordenadas pelos maiores juros (a que mais cresce deve ser
/// paga primeiro), com barra de progresso por dívida e o próximo vencimento.
class DebtsTab extends StatelessWidget {
  const DebtsTab({
    super.key,
    required this.debts,
    required this.now,
    required this.onPayInstallment,
  });

  final List<Debt> debts;
  final DateTime now;

  /// Chamado quando a pessoa toca em "Paguei esta parcela".
  final ValueChanged<Debt> onPayInstallment;

  /// Texto lido em voz alta pelo botão de áudio da barra superior.
  static String audioText(List<Debt> debts) {
    final open = sortByInterest(debts).where((debt) => !debt.isPaidOff).toList();
    if (open.isEmpty) {
      return 'Plano de quitação. Parabéns, todas as dívidas foram pagas!';
    }
    final remaining =
        open.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    return 'Plano de quitação. Ainda faltam ${spokenBRL(remaining)} em '
        '${open.length} dívidas. Pague primeiro ${open.first.name}, '
        'que tem os maiores juros.';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sortByInterest(debts);
    final open = sorted.where((debt) => !debt.isPaidOff).toList();
    final remaining =
        open.fold<double>(0, (sum, debt) => sum + debt.remainingAmount);
    final first = open.isEmpty ? null : open.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _PlanSummary(progress: planProgress(debts), remaining: remaining),
        const SizedBox(height: 16),
        if (first != null)
          MascotTip(
            title: 'Comece por aqui',
            message:
                '${first.name} tem os maiores juros (${first.monthlyRate.toStringAsFixed(0)}% ao mês). '
                'Pagar ela primeiro economiza mais dinheiro.',
          ),
        const SectionTitle('Minhas dívidas'),
        if (sorted.isEmpty)
          const Text('Nenhuma dívida cadastrada. Que ótimo!', style: AppText.body),
        // `for` dentro da lista de filhos cria um cartão para cada dívida.
        for (var i = 0; i < sorted.length; i++)
          _DebtCard(
            debt: sorted[i],
            now: now,
            isPriority: i == 0 && !sorted[i].isPaidOff,
            onPay: () => onPayInstallment(sorted[i]),
          ),
      ],
    );
  }
}

/// Cartão com o progresso geral do plano.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.progress, required this.remaining});

  final double progress;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Falta pagar no total', style: AppText.small),
          const SizedBox(height: 2),
          Text(formatBRL(remaining), style: AppText.h1.copyWith(fontSize: 36)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: AppColors.border,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text('Você já pagou $percent% do plano.', style: AppText.body),
        ],
      ),
    );
  }
}

/// Cartão de uma dívida.
class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.now,
    required this.isPriority,
    required this.onPay,
  });

  final Debt debt;
  final DateTime now;
  final bool isPriority;
  final VoidCallback onPay;

  // Cor da etiqueta de vencimento: quanto mais perto, mais forte o aviso.
  // O texto "vence em N dias" sempre acompanha, então não dependemos só da cor.
  (Color, Color) _dueColors(int days) {
    if (days <= 3) return (AppColors.brickSoft, AppColors.brickDark);
    if (days <= 7) return (AppColors.yellowSoft, AppColors.petrol);
    return (AppColors.mintSoft, AppColors.petrol);
  }

  @override
  Widget build(BuildContext context) {
    final days = daysBetween(now, debt.nextDue);
    final (dueBackground, dueForeground) = _dueColors(days);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 26, outlined: isPriority),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPriority ? AppColors.peachSoft : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(debt.icon, color: AppColors.petrol, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name, style: AppText.h3),
                    const SizedBox(height: 2),
                    Text(
                      'Parcela de ${formatBRL(debt.installmentValue)}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Wrap quebra as etiquetas em outra linha se não couberem.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isPriority)
                const TagChip(
                  label: 'Pague primeiro',
                  icon: Icons.flag,
                  background: AppColors.petrol,
                  foreground: Colors.white,
                ),
              TagChip(
                label: 'Juros ${debt.monthlyRate.toStringAsFixed(debt.monthlyRate % 1 == 0 ? 0 : 1)}% ao mês',
                background: AppColors.peachSoft,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: debt.progress,
              minHeight: 14,
              backgroundColor: AppColors.border,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            debt.isPaidOff
                ? 'Todas as ${debt.totalInstallments} parcelas pagas!'
                : '${debt.paidInstallments} de ${debt.totalInstallments} parcelas pagas · faltam ${formatBRL(debt.remainingAmount)}',
            style: AppText.small,
          ),
          const SizedBox(height: 12),
          if (debt.isPaidOff)
            const TagChip(
              label: 'Dívida quitada',
              icon: Icons.check_circle,
              background: AppColors.mintSoft,
            )
          else ...[
            TagChip(
              icon: Icons.calendar_today,
              label: 'Próximo vencimento: ${formatShortDate(debt.nextDue)} (${dueText(debt.nextDue, now)})',
              background: dueBackground,
              foreground: dueForeground,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Paguei esta parcela',
              icon: Icons.check,
              kind: AppButtonKind.dark,
              showArrow: false,
              onPressed: onPay,
            ),
          ],
        ],
      ),
    );
  }
}
