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
/// Os dados vêm da API e ficam guardados na tela pai.
class DebtsTab extends StatelessWidget {
  const DebtsTab({
    super.key,
    required this.debts,
    required this.plans,
    required this.thermometer,
    required this.now,
    required this.onPayInstallment,
    required this.onDelete,
    required this.onAdd,
    required this.onRefresh,
  });

  final List<Debt> debts;

  /// Projeção de quitação de cada dívida (chave = id da dívida).
  final Map<int, DebtPlan> plans;

  /// Quanto da renda as parcelas comprometem (nulo se ainda não carregou).
  final DebtThermometer? thermometer;
  final DateTime now;

  /// Chamado quando a pessoa toca em "Paguei esta parcela".
  final ValueChanged<Debt> onPayInstallment;
  final ValueChanged<Debt> onDelete;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;

  /// Texto lido em voz alta pelo botão de áudio da barra superior.
  static String audioText(List<Debt> debts) {
    final open = sortByInterest(debts).where((debt) => !debt.isPaidOff).toList();
    if (debts.isEmpty) {
      return 'Plano de quitação. Você ainda não cadastrou dívidas. '
          'Toque em Adicionar dívida para começar.';
    }
    if (open.isEmpty) {
      return 'Plano de quitação. Parabéns, todas as dívidas foram pagas!';
    }
    final remaining = open.fold<double>(0, (sum, debt) => sum + debt.balance);
    return 'Plano de quitação. Ainda faltam ${spokenBRL(remaining)} em '
        '${open.length} dívidas. Pague primeiro ${open.first.name}, '
        'que tem os maiores juros.';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sortByInterest(debts);
    final open = sorted.where((debt) => !debt.isPaidOff).toList();
    final remaining = open.fold<double>(0, (sum, debt) => sum + debt.balance);
    final first = open.isEmpty ? null : open.first;
    final thermo = thermometer;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (debts.isNotEmpty) ...[
            _PlanSummary(
              progress: planProgress(debts),
              remaining: remaining,
              thermometer: thermo,
            ),
            const SizedBox(height: 16),
          ],
          if (first != null)
            MascotTip(
              title: 'Comece por aqui',
              message:
                  '${first.name} tem os maiores juros (${_rate(first.monthlyRate)}% ao mês). '
                  'Pagar ela primeiro economiza mais dinheiro.',
            ),
          SectionTitle('Minhas dívidas', trailing: debts.isEmpty ? null : '${debts.length}'),
          if (debts.isEmpty)
            const _EmptyDebts(),
          // `for` dentro da lista de filhos cria um cartão para cada dívida.
          for (var i = 0; i < sorted.length; i++)
            _DebtCard(
              debt: sorted[i],
              plan: plans[sorted[i].id],
              now: now,
              isPriority: i == 0 && !sorted[i].isPaidOff,
              onPay: () => onPayInstallment(sorted[i]),
              onDelete: () => onDelete(sorted[i]),
            ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Adicionar dívida',
            icon: Icons.add,
            kind: AppButtonKind.light,
            showArrow: false,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// Juros sem casas decimais quando for número inteiro (12.0 -> "12").
String _rate(double rate) => rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1);

/// Mensagem quando ainda não há dívidas cadastradas.
class _EmptyDebts extends StatelessWidget {
  const _EmptyDebts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecor.card(color: AppColors.mintSoft, radius: 22),
      child: const Row(
        children: [
          Icon(Icons.celebration, color: AppColors.petrol, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma dívida cadastrada. Se tiver alguma, adicione para o app montar o seu plano de quitação.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão com o progresso geral do plano e o peso das parcelas na renda.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.progress,
    required this.remaining,
    required this.thermometer,
  });

  final double progress;
  final double remaining;
  final DebtThermometer? thermometer;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final thermo = thermometer;

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
          if (thermo != null) ...[
            const SizedBox(height: 14),
            _IncomeWeight(thermometer: thermo),
          ],
        ],
      ),
    );
  }
}

/// Faixa que mostra quanto da renda as parcelas comprometem.
/// Cor + ícone + texto (nunca só a cor).
class _IncomeWeight extends StatelessWidget {
  const _IncomeWeight({required this.thermometer});

  final DebtThermometer thermometer;

  @override
  Widget build(BuildContext context) {
    if (!thermometer.hasIncome) {
      return const TagChip(
        icon: Icons.info_outline,
        label: 'Informe a sua renda para ver o peso das parcelas',
        background: AppColors.peachSoft,
      );
    }

    final percent = thermometer.percent ?? 0.0;
    final (background, foreground, icon, text) = switch (thermometer.band) {
      'VERMELHO' => (
          AppColors.brickSoft,
          AppColors.brickDark,
          Icons.error_outline,
          'pesa demais na sua renda'
        ),
      'AMARELO' => (
          AppColors.yellowSoft,
          AppColors.petrol,
          Icons.warning_amber,
          'pede atenção'
        ),
      _ => (AppColors.mintSoft, AppColors.petrol, Icons.check_circle, 'está sob controle'),
    };

    return TagChip(
      icon: icon,
      label: 'Parcelas: ${percent.toStringAsFixed(0)}% da renda · $text',
      background: background,
      foreground: foreground,
    );
  }
}

/// Cartão de uma dívida.
class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.plan,
    required this.now,
    required this.isPriority,
    required this.onPay,
    required this.onDelete,
  });

  final Debt debt;
  final DebtPlan? plan;
  final DateTime now;
  final bool isPriority;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  // Cor da etiqueta de vencimento: quanto mais perto, mais forte o aviso.
  // O texto "vence em N dias" sempre acompanha, então não dependemos só da cor.
  (Color, Color) _dueColors(int days) {
    if (days <= 3) return (AppColors.brickSoft, AppColors.brickDark);
    if (days <= 7) return (AppColors.yellowSoft, AppColors.petrol);
    return (AppColors.mintSoft, AppColors.petrol);
  }

  @override
  Widget build(BuildContext context) {
    final nextDue = debt.nextDue(now);
    final days = daysBetween(now, nextDue);
    final (dueBackground, dueForeground) = _dueColors(days);
    final debtPlan = plan;

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
                      'Parcela de ${formatBRL(debt.installmentValue)} · ${debt.type.label}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir dívida',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.brickDark,
                  minimumSize: const Size(48, 48),
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
                label: 'Juros ${_rate(debt.monthlyRate)}% ao mês',
                background: AppColors.peachSoft,
              ),
              if (!debt.isPaidOff && debtPlan != null)
                if (debtPlan.payable && debtPlan.months != null)
                  TagChip(
                    icon: Icons.event_available,
                    label: 'Quita em ${debtPlan.months} ${debtPlan.months == 1 ? 'mês' : 'meses'}',
                    background: AppColors.mintSoft,
                  )
                else
                  const TagChip(
                    icon: Icons.warning_amber,
                    label: 'A parcela não cobre os juros',
                    background: AppColors.brickSoft,
                    foreground: AppColors.brickDark,
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
                ? 'Dívida quitada!'
                : 'Faltam ${formatBRL(debt.balance)} · pago ${(debt.progress * 100).round()}%',
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
              label: 'Próximo vencimento: ${formatShortDate(nextDue)} (${dueText(nextDue, now)})',
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
