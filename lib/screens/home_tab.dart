import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/money_summary.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/section_title.dart';
import '../widgets/thermometer_card.dart';
import '../widgets/transaction_tile.dart';

/// Tela 4: Painel principal.
///
/// Mostra o Termômetro do Dinheiro, o saldo grande (com opção de áudio), o
/// feed dos últimos registros com ícones e os botões fixos de Entrada (+),
/// Saída (-) e WhatsApp.
///
/// Os dados (lista de movimentações) ficam no widget pai, que chama
/// `setState` quando algo é registrado. Assim o saldo é recalculado e esta
/// tela é redesenhada com os valores novos.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.userName,
    required this.transactions,
    required this.now,
    required this.dueSoon,
    required this.onAddTransaction,
    required this.onOpenWhatsApp,
    required this.onSeeBills,
  });

  final String userName;
  final List<Transaction> transactions;
  final DateTime now;

  /// Quantidade de contas que vencem nos próximos 7 dias.
  final int dueSoon;

  final ValueChanged<TransactionType> onAddTransaction;
  final VoidCallback onOpenWhatsApp;
  final VoidCallback onSeeBills;

  /// Texto lido em voz alta pelo botão de áudio da barra superior.
  static String audioText({
    required String userName,
    required List<Transaction> transactions,
    required DateTime now,
  }) {
    final summary = MoneySummary.fromTransactions(transactions);
    return 'Olá, $userName. O seu Termômetro do Dinheiro está em '
        '${summary.level.label}. ${_balanceAudio(summary, monthName(now.month))}';
  }

  static String _balanceAudio(MoneySummary summary, String month) {
    final negative = summary.balance < 0;
    return 'Seu saldo de $month é ${spokenBRL(summary.balance)}'
        '${negative ? ' negativo' : ''}. '
        'Entrou ${spokenBRL(summary.income)} e saiu ${spokenBRL(summary.expenses)}.';
  }

  @override
  Widget build(BuildContext context) {
    final summary = MoneySummary.fromTransactions(transactions);
    final month = monthName(now.month);
    final balanceAudio = _balanceAudio(summary, month);

    // Column: a lista rola dentro do Expanded e os botões ficam fixos embaixo.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              _buildHero(summary),
              if (dueSoon > 0) ...[
                const SizedBox(height: 14),
                _DueSoonPill(count: dueSoon, onTap: onSeeBills),
              ],
              const SizedBox(height: 14),
              _buildBalanceCard(summary, month, balanceAudio),
              const SectionTitle('Últimos registros'),
              _buildFeed(),
            ],
          ),
        ),
        _ActionBar(
          onIncome: () => onAddTransaction(TransactionType.income),
          onExpense: () => onAddTransaction(TransactionType.expense),
          onWhatsApp: onOpenWhatsApp,
        ),
      ],
    );
  }

  // Cartão do topo: saudação com fundo em degradê + termômetro.
  Widget _buildHero(MoneySummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD9C2), AppColors.cream, AppColors.mintSoft],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bem-vindo de volta', style: AppText.small),
                Text('Olá, $userName!', style: AppText.h1.copyWith(fontSize: 32)),
              ],
            ),
          ),
          ThermometerCard(summary: summary),
        ],
      ),
    );
  }

  // Saldo grande, com botão de áudio e o resumo de entradas e saídas.
  Widget _buildBalanceCard(MoneySummary summary, String month, String audio) {
    final negative = summary.balance < 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  negative ? 'Faltou em $month' : 'Saldo de $month',
                  style: AppText.small,
                ),
              ),
              AudioButton(text: audio),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatBRL(summary.balance),
            style: AppText.h1.copyWith(
              fontSize: 40,
              color: negative ? AppColors.brickDark : AppColors.petrol,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniFigure(
                  icon: Icons.arrow_downward,
                  label: 'Entrou',
                  value: formatBRL(summary.income),
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: _MiniFigure(
                  icon: Icons.arrow_upward,
                  label: 'Saiu',
                  value: formatBRL(summary.expenses),
                  color: AppColors.brickDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Feed com os 6 registros mais recentes (a lista já vem do mais novo para
  // o mais antigo). Se estiver vazia, mostra um estado vazio amigável.
  Widget _buildFeed() {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppDecor.card(color: AppColors.peachSoft, radius: 24),
        child: const Row(
          children: [
            Icon(Icons.edit_note, size: 36, color: AppColors.petrol),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ainda não há registros. Toque em Entrada ou Saída para começar.',
                style: AppText.body,
              ),
            ),
          ],
        ),
      );
    }

    final recent = transactions.take(6).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            TransactionTile(transaction: recent[i], now: now),
            if (i < recent.length - 1) const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

/// Faixa que avisa de contas vencendo na semana (leva às dívidas).
class _DueSoonPill extends StatelessWidget {
  const _DueSoonPill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.yellowSoft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.petrol),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? 'Você tem 1 conta vencendo esta semana'
                      : 'Você tem $count contas vencendo esta semana',
                  style: AppText.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.petrol),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFigure extends StatelessWidget {
  const _MiniFigure({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.small),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botões fixos: (+) Entrada, (-) Saída e WhatsApp.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onIncome,
    required this.onExpense,
    required this.onWhatsApp,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.add,
              label: 'Entrada',
              background: AppColors.mint,
              foreground: AppColors.petrolDark,
              onTap: onIncome,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.remove,
              label: 'Saída',
              background: AppColors.peach,
              foreground: AppColors.petrolDark,
              onTap: onExpense,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat,
              label: 'WhatsApp',
              background: AppColors.petrol,
              foreground: Colors.white,
              onTap: onWhatsApp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 28),
                // FittedBox encolhe o texto se não couber (letra grande).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
