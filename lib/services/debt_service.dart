import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/debt.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'debt_progress_store.dart';

/// Chamadas da API de dívidas, plano de quitação, termômetro e alertas.
class DebtService {
  DebtService._();

  static final DebtService instance = DebtService._();

  final ApiClient _api = ApiClient.instance;

  int get _userId => AuthService.instance.userId ?? 0;

  /// `GET /dividas`: todas as dívidas da conta (abertas e quitadas).
  Future<List<Debt>> list() async {
    final data = await _api.get('/dividas');
    final items = data is List ? data : const [];
    final debts = items
        .map((item) => Debt.fromJson(item as Map<String, dynamic>))
        .toList();
    for (final debt in debts) {
      debt.initialBalance = await DebtProgressStore.initialBalance(
        userId: _userId,
        debtId: debt.id,
        currentBalance: debt.balance,
      );
    }
    return debts;
  }

  /// `POST /dividas`: cadastra uma dívida nova (começa como ABERTA).
  Future<Debt> create({
    required String name,
    required DebtType type,
    required double balance,
    required double monthlyRate,
    required double installmentValue,
    required int dueDay,
  }) async {
    final data = await _api.post(
      '/dividas',
      body: {
        'credor': name.trim(),
        'tipo': type.apiValue,
        'saldoDevedor': balance,
        'taxaJurosMes': monthlyRate,
        'valorParcela': installmentValue,
        'diaVencimento': dueDay,
      },
    );
    final debt = Debt.fromJson(data as Map<String, dynamic>);
    debt.initialBalance = await DebtProgressStore.initialBalance(
      userId: _userId,
      debtId: debt.id,
      currentBalance: debt.balance,
    );
    return debt;
  }

  /// Registra o pagamento de uma parcela com `PUT /dividas/{id}`.
  ///
  /// A API não tem um endpoint "pagar parcela", então o app calcula o novo
  /// saldo: o saldo cresce com os juros do mês e diminui o valor da parcela
  /// (mesma conta do plano de quitação da API). Se zerar, a dívida vira
  /// QUITADA.
  Future<Debt> payInstallment(Debt debt) async {
    final accrued = debt.balance * (1 + debt.monthlyRate / 100);
    var newBalance = ((accrued - debt.installmentValue) * 100).round() / 100;
    if (newBalance <= 0) newBalance = 0.0;
    final paidOff = newBalance == 0;

    final data = await _api.put(
      '/dividas/${debt.id}',
      body: debt.toRequest(newBalance: newBalance, paidOff: paidOff),
    );
    final updated = Debt.fromJson(data as Map<String, dynamic>);
    updated.initialBalance = debt.initialBalance;
    return updated;
  }

  /// `DELETE /dividas/{id}`.
  Future<void> delete(Debt debt) async {
    await _api.delete('/dividas/${debt.id}');
    await DebtProgressStore.forget(userId: _userId, debtId: debt.id);
  }

  /// `GET /dividas/{id}/plano`: em quantos meses a dívida quita.
  Future<DebtPlan> plan(int debtId) async {
    final data = await _api.get('/dividas/$debtId/plano');
    return DebtPlan.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /dividas/termometro`: quanto da renda as parcelas comprometem.
  Future<DebtThermometer> thermometer() async {
    final data = await _api.get('/dividas/termometro');
    return DebtThermometer.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /dividas/alertas`: próximos vencimentos (por padrão, 15 dias).
  /// O ícone de cada conta vem da dívida correspondente.
  Future<List<Bill>> alerts(List<Debt> debts, {int days = 15}) async {
    final data = await _api.get('/dividas/alertas', query: {'dias': '$days'});
    final items = data is List ? data : const [];
    final icons = {for (final debt in debts) debt.id: debt.icon};
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      final id = (json['dividaId'] as num).toInt();
      return Bill.fromJson(json, icons[id] ?? Icons.receipt_long);
    }).toList();
  }
}
