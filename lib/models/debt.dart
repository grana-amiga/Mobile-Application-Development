import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Tipos de dívida aceitos pela API (`CARTAO`, `CARNE`, `PESSOAL`, `OUTROS`).
enum DebtType {
  card('CARTAO', 'Cartão de crédito', Icons.credit_card),
  installments('CARNE', 'Carnê ou compra parcelada', Icons.receipt_long),
  personal('PESSOAL', 'Empréstimo pessoal', Icons.account_balance),
  other('OUTROS', 'Outra dívida', Icons.payments);

  const DebtType(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static DebtType fromApi(dynamic value) {
    for (final type in DebtType.values) {
      if (type.apiValue == value) return type;
    }
    return DebtType.other;
  }
}

/// Uma dívida da família, como a API (`DividaResponse`) devolve.
///
/// A API guarda o saldo devedor atual, a parcela e o dia do vencimento. Ela
/// não guarda o saldo de quando a dívida foi cadastrada; por isso o app
/// lembra esse valor no aparelho ([initialBalance]) para desenhar a barra
/// de progresso.
class Debt {
  Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.monthlyRate,
    required this.installmentValue,
    required this.dueDay,
    required this.isPaidOff,
    this.initialBalance = 0,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: (json['id'] as num).toInt(),
      name: '${json['credor']}',
      type: DebtType.fromApi(json['tipo']),
      balance: asDouble(json['saldoDevedor']),
      monthlyRate: asDouble(json['taxaJurosMes']),
      installmentValue: asDouble(json['valorParcela']),
      dueDay: (json['diaVencimento'] as num).toInt(),
      isPaidOff: json['status'] == 'QUITADA',
    );
  }

  final int id;
  final String name;
  final DebtType type;

  /// Quanto ainda falta pagar (saldo devedor atual).
  final double balance;

  /// Juros ao mês, em porcentagem (12.0 = 12% ao mês).
  final double monthlyRate;
  final double installmentValue;

  /// Dia do mês em que a parcela vence (1 a 31).
  final int dueDay;
  final bool isPaidOff;

  /// Saldo devedor na primeira vez que o app viu esta dívida.
  double initialBalance;

  IconData get icon => type.icon;

  /// Progresso de 0 a 1 (usado na barra de progresso).
  double get progress {
    if (isPaidOff) return 1;
    if (initialBalance <= 0) return 0;
    return (1 - balance / initialBalance).clamp(0.0, 1.0).toDouble();
  }

  /// Próxima data de vencimento a partir de [now]. Em meses curtos o dia
  /// 31 vira o último dia do mês (mesma regra da API).
  DateTime nextDue(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var candidate = _dueIn(now.year, now.month);
    if (candidate.isBefore(today)) {
      candidate = _dueIn(now.year, now.month + 1);
    }
    return candidate;
  }

  DateTime _dueIn(int year, int month) {
    // `DateTime(ano, mes + 1, 0)` é o último dia do mês `mes`.
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = dueDay > lastDay ? lastDay : dueDay;
    return DateTime(year, month, day);
  }

  /// Corpo do `PUT /dividas/{id}` com os mesmos dados e outro saldo/status.
  Map<String, dynamic> toRequest({double? newBalance, bool? paidOff}) {
    final done = paidOff ?? isPaidOff;
    return {
      'credor': name,
      'tipo': type.apiValue,
      'saldoDevedor': newBalance ?? balance,
      'taxaJurosMes': monthlyRate,
      'valorParcela': installmentValue,
      'diaVencimento': dueDay,
      'status': done ? 'QUITADA' : 'ABERTA',
    };
  }
}

/// Projeção de quitação de uma dívida (`GET /dividas/{id}/plano`).
class DebtPlan {
  const DebtPlan({
    required this.payable,
    required this.warning,
    required this.months,
    required this.totalInterest,
  });

  factory DebtPlan.fromJson(Map<String, dynamic> json) {
    return DebtPlan(
      payable: json['quitavel'] == true,
      warning: '${json['aviso'] ?? ''}',
      months: (json['mesesParaQuitacao'] as num?)?.toInt(),
      totalInterest: asDouble(json['totalJurosSimulados']),
    );
  }

  /// Falso quando a parcela não cobre nem os juros do mês.
  final bool payable;
  final String warning;

  /// Meses até quitar (nulo se não quita).
  final int? months;
  final double totalInterest;
}

/// Quanto da renda as parcelas comprometem (`GET /dividas/termometro`).
class DebtThermometer {
  const DebtThermometer({
    required this.income,
    required this.installmentsTotal,
    required this.percent,
    required this.band,
  });

  factory DebtThermometer.fromJson(Map<String, dynamic> json) {
    final percent = json['percentualComprometimento'];
    return DebtThermometer(
      income: asDouble(json['rendaMensal']),
      installmentsTotal: asDouble(json['totalParcelasAbertas']),
      percent: percent == null ? null : asDouble(percent),
      band: '${json['faixa']}',
    );
  }

  final double income;
  final double installmentsTotal;

  /// Nulo quando a pessoa não informou a renda mensal.
  final double? percent;

  /// `VERDE`, `AMARELO`, `VERMELHO` ou `SEM_RENDA`.
  final String band;

  bool get hasIncome => percent != null && band != 'SEM_RENDA';
}

/// Ordena as dívidas pelos maiores juros primeiro (a que "cresce mais
/// rápido" deve ser paga antes). Dívidas quitadas vão para o fim da lista.
List<Debt> sortByInterest(List<Debt> debts) {
  final sorted = List<Debt>.of(debts);
  sorted.sort((a, b) {
    if (a.isPaidOff != b.isPaidOff) return a.isPaidOff ? 1 : -1;
    return b.monthlyRate.compareTo(a.monthlyRate);
  });
  return sorted;
}

/// Porcentagem geral do plano (0 a 1): quanto do saldo inicial já foi pago.
double planProgress(List<Debt> debts) {
  var initial = 0.0;
  var remaining = 0.0;
  for (final debt in debts) {
    final start = debt.initialBalance > debt.balance
        ? debt.initialBalance
        : debt.balance;
    initial += start;
    remaining += debt.isPaidOff ? 0 : debt.balance;
  }
  if (initial <= 0) return debts.isEmpty ? 0 : 1;
  return (1 - remaining / initial).clamp(0.0, 1.0).toDouble();
}
