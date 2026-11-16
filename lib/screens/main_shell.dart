import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/bill.dart';
import '../models/debt.dart';
import '../models/money_summary.dart';
import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mascot.dart';
import 'add_transaction_screen.dart';
import 'debts_tab.dart';
import 'energy_tab.dart';
import 'games_screen.dart';
import 'home_tab.dart';
import 'whatsapp_screen.dart';

/// Área da família (depois do login): uma tela com 4 abas.
///
/// É um StatefulWidget porque guarda os dados que mudam durante o uso
/// (movimentações, dívidas e alertas), carregados da API. Quando algo é
/// registrado, chamamos `setState` e o saldo e o termômetro são recalculados
/// e redesenhados.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final TransactionService _transactionApi = TransactionService.instance;
  final DebtService _debtApi = DebtService.instance;

  late final DateTime _now = DateTime.now();

  // Estado do carregamento inicial.
  bool _loading = true;
  bool _slowLoad = false; // true se a API demorar (servidor acordando)
  String? _loadError;

  // Dados vindos da API.
  List<TxCategory> _categories = const [];
  MoneySummary _summary = const MoneySummary(income: 0, expenses: 0);
  List<Transaction> _transactions = [];
  List<Debt> _debts = [];
  Map<int, DebtPlan> _plans = {};
  DebtThermometer? _thermometer;
  List<Bill> _bills = [];

  int _tabIndex = 0;

  static const List<String> _titles = [
    'Grana Amiga',
    'Plano de quitação',
    'Alertas e energia',
    'Aprender',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ---------------------------------------------------------------------
  // Carregamento
  // ---------------------------------------------------------------------

  // Busca tudo o que o painel precisa em paralelo (Future.wait) para não
  // esperar uma chamada terminar antes de começar a outra.
  Future<void> _fetch() async {
    final categoriesF = _transactionApi.categories();
    final summaryF = _transactionApi.monthSummary(_now.year, _now.month);
    final recentF = _transactionApi.recent();
    final debtsF = _debtApi.list();
    final thermometerF = _debtApi.thermometer();

    await Future.wait<Object?>([
      categoriesF,
      summaryF,
      recentF,
      debtsF,
      thermometerF,
    ]);

    // Todos terminaram: `await` em um Future pronto devolve o valor na hora.
    final categories = await categoriesF;
    final summary = await summaryF;
    final recent = await recentF;
    final debts = await debtsF;
    final thermometer = await thermometerF;
    // Os alertas precisam da lista de dívidas (para escolher o ícone).
    final bills = await _debtApi.alerts(debts);

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _summary = summary;
      _transactions = recent;
      _debts = debts;
      _thermometer = thermometer;
      _bills = bills;
    });
    unawaited(_loadPlans());
  }

  // Primeira carga: mostra a tela de carregamento (ou de erro com "tentar de novo").
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _slowLoad = false;
      _loadError = null;
    });
    // Se passar de 6 segundos, avisa que o servidor está acordando.
    final slowTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _loading) setState(() => _slowLoad = true);
    });
    try {
      await _fetch();
      if (!mounted) return;
      setState(() => _loading = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } finally {
      slowTimer.cancel();
    }
  }

  // Recarregamento ao puxar a lista para baixo: não troca a tela por um
  // carregando, só atualiza os dados (e avisa se der erro).
  Future<void> _refresh() async {
    try {
      await _fetch();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  // Busca o plano de quitação (meses para quitar) de cada dívida aberta.
  // Se alguma chamada falhar, só não mostramos o plano dessa dívida.
  Future<void> _loadPlans() async {
    final plans = <int, DebtPlan>{};
    for (final debt in _debts.where((debt) => !debt.isPaidOff)) {
      try {
        plans[debt.id] = await _debtApi.plan(debt.id);
      } on ApiException {
        // Ignora: o plano é uma informação extra.
      }
    }
    if (!mounted) return;
    setState(() => _plans = plans);
  }

  // Atualiza alertas, termômetro e planos depois de mudar as dívidas.
  Future<void> _refreshDebtInfo() async {
    try {
      final bills = await _debtApi.alerts(_debts);
      final thermometer = await _debtApi.thermometer();
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _thermometer = thermometer;
      });
      await _loadPlans();
    } on ApiException {
      // Sem problema: a próxima atualização corrige.
    }
  }

  // ---------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------

  // Abre a tela de gasto/entrada e espera o resultado (Navigator.pop com valor).
  Future<void> _addTransaction(TransactionType type) async {
    final created = await Navigator.pushNamed<Transaction?>(
      context,
      AppRoutes.addTransaction,
      arguments: AddTransactionArgs(type: type, categories: _categories),
    );
    if (created == null || !mounted) return; // a pessoa cancelou
    _onTransactionCreated(created);
  }

  // Insere no começo da lista e soma ao total do mês. O `setState` redesenha
  // a tela: o saldo muda na hora, sem precisar buscar tudo de novo.
  void _onTransactionCreated(Transaction transaction) {
    if (!mounted) return;
    setState(() {
      _transactions.insert(0, transaction);
      _summary = MoneySummary(
        income: _summary.income + (transaction.isExpense ? 0 : transaction.amount),
        expenses: _summary.expenses + (transaction.isExpense ? transaction.amount : 0),
      );
    });
  }

  void _openWhatsApp() {
    Navigator.pushNamed(
      context,
      AppRoutes.whatsapp,
      arguments: WhatsAppArgs(
        categories: _categories,
        onCreated: _onTransactionCreated,
      ),
    );
  }

  Future<void> _addDebt() async {
    final created = await Navigator.pushNamed<Debt?>(context, AppRoutes.addDebt);
    if (created == null || !mounted) return;
    setState(() => _debts = [..._debts, created]);
    unawaited(_refreshDebtInfo());
  }

  Future<void> _payInstallment(Debt debt) async {
    if (debt.isPaidOff) return;
    try {
      final updated = await _debtApi.payInstallment(debt);
      if (!mounted) return;
      setState(() {
        _debts = [
          for (final item in _debts) item.id == updated.id ? updated : item,
        ];
      });
      showAppSnackBar(
        context,
        updated.isPaidOff
            ? 'Parabéns! Você quitou ${updated.name}!'
            : 'Parcela de ${updated.name} marcada como paga.',
      );
      unawaited(_refreshDebtInfo());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir dívida?'),
        content: Text('Excluir "${debt.name}" do seu plano? Isso não pode ser desfeito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _debtApi.delete(debt);
      if (!mounted) return;
      setState(() {
        _debts = _debts.where((item) => item.id != debt.id).toList();
        _plans = Map.of(_plans)..remove(debt.id);
      });
      showAppSnackBar(context, 'Dívida "${debt.name}" excluída.');
      unawaited(_refreshDebtInfo());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    }
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
          summary: _summary,
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

  // ---------------------------------------------------------------------
  // Telas
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    final loadError = _loadError;
    if (loadError != null) return _buildError(loadError);

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
              summary: _summary,
              transactions: _transactions,
              now: _now,
              dueSoon: dueThisWeek(_bills, _now),
              onAddTransaction: _addTransaction,
              onOpenWhatsApp: _openWhatsApp,
              onSeeBills: () => setState(() => _tabIndex = 2),
              onRefresh: _refresh,
            ),
            DebtsTab(
              debts: _debts,
              plans: _plans,
              thermometer: _thermometer,
              now: _now,
              onPayInstallment: _payInstallment,
              onDelete: _deleteDebt,
              onAdd: _addDebt,
              onRefresh: _refresh,
            ),
            EnergyTab(bills: _bills, now: _now),
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

  // Tela de espera da primeira carga. A API gratuita do Render "dorme" e
  // pode levar até 1 minuto na primeira chamada, então explicamos a demora.
  Widget _buildLoading() {
    return Scaffold(
      appBar: buildAppBar(title: 'Grana Amiga'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(height: 110),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Carregando as suas contas...', style: AppText.h2),
                if (_slowLoad) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'O servidor estava descansando e está acordando. Isso pode levar até 1 minuto na primeira vez.',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Scaffold(
      appBar: buildAppBar(title: 'Grana Amiga'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: AppColors.brickDark),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível carregar',
                  textAlign: TextAlign.center,
                  style: AppText.h2,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: AppText.body),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Tentar de novo',
                  icon: Icons.refresh,
                  showArrow: false,
                  onPressed: _loadAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
