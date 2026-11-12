import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../data/mock_data.dart';
import '../models/bill.dart';
import '../models/debt.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import 'debts_tab.dart';
import 'energy_tab.dart';
import 'games_screen.dart';
import 'home_tab.dart';
import 'whatsapp_screen.dart';

/// Área da família (depois do login): uma tela com 4 abas.
///
/// É um StatefulWidget porque guarda os dados que mudam durante o uso
/// (movimentações e dívidas). Quando algo é registrado, chamamos `setState`
/// e o saldo e o termômetro são recalculados e redesenhados.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final DateTime _now = DateTime.now();
  late final List<Transaction> _transactions = MockData.transactions(_now);
  late final List<Debt> _debts = MockData.debts(_now);
  late final List<Bill> _fixedBills = MockData.fixedBills(_now);

  int _tabIndex = 0;

  static const List<String> _titles = [
    'Grana Amiga',
    'Plano de quitação',
    'Alertas e energia',
    'Aprender',
  ];

  List<Bill> get _bills => upcomingBills(_debts, _fixedBills, _now);

  // Abre a tela de gasto/entrada e espera o resultado (Navigator.pop com valor).
  Future<void> _addTransaction(TransactionType type) async {
    final created = await Navigator.pushNamed<Transaction>(
      context,
      AppRoutes.addTransaction,
      arguments: type,
    );
    if (created == null || !mounted) return; // a pessoa cancelou
    _insert(created);
  }

  // Insere no começo da lista e redesenha: o saldo muda na hora.
  void _insert(Transaction transaction) {
    setState(() => _transactions.insert(0, transaction));
  }

  void _openWhatsApp() {
    Navigator.pushNamed(
      context,
      AppRoutes.whatsapp,
      arguments: WhatsAppArgs(onConfirm: _insert),
    );
  }

  void _payInstallment(Debt debt) {
    if (debt.isPaidOff) return;
    setState(() {
      debt.paidInstallments += 1;
      // A próxima parcela vence 30 dias depois da anterior.
      debt.nextDue = debt.nextDue.add(const Duration(days: 30));
    });
    showAppSnackBar(
      context,
      debt.isPaidOff
          ? 'Parabéns! Você quitou ${debt.name}!'
          : 'Parcela de ${debt.name} marcada como paga.',
    );
  }

  Future<void> _confirmLogout() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do app?'),
        content: const Text('Você poderá entrar de novo quando quiser.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ficar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    AuthService.instance.logout();
    // Remove todas as telas anteriores: não dá para "voltar" para a área logada.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
  }

  // Texto do botão de áudio muda conforme a aba aberta.
  String get _audioText {
    switch (_tabIndex) {
      case 0:
        return HomeTab.audioText(
          userName: AuthService.instance.userName,
          transactions: _transactions,
          now: _now,
        );
      case 1:
        return DebtsTab.audioText(_debts);
      case 2:
        return EnergyTab.audioText(_bills, _now);
      default:
        return 'Aprender. Escolha um jogo para treinar ou assista às videoaulas rápidas sobre dinheiro.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = _bills;

    return Scaffold(
      appBar: buildAppBar(
        title: _titles[_tabIndex],
        audioText: _audioText,
        compactAudio: true,
        extraActions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // IndexedStack mantém todas as abas vivas e mostra só a atual,
      // assim o estado de cada aba não se perde ao trocar.
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            HomeTab(
              userName: AuthService.instance.userName,
              transactions: _transactions,
              now: _now,
              dueSoon: dueThisWeek(bills, _now),
              onAddTransaction: _addTransaction,
              onOpenWhatsApp: _openWhatsApp,
              onSeeBills: () => setState(() => _tabIndex = 2),
            ),
            DebtsTab(
              debts: _debts,
              now: _now,
              onPayInstallment: _payInstallment,
            ),
            EnergyTab(bills: bills, now: _now),
            const GamesCatalog(showVideos: true),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
      ),
    );
  }
}
