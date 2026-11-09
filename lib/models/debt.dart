import 'package:flutter/material.dart';

/// Uma dívida parcelada que a família está pagando.
///
/// Os campos `paidInstallments` e `nextDue` são mutáveis porque mudam quando
/// a pessoa registra o pagamento de uma parcela.
class Debt {
  Debt({
    required this.name,
    required this.icon,
    required this.monthlyRate,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.installmentValue,
    required this.nextDue,
  });

  final String name;
  final IconData icon;

  /// Juros ao mês, em porcentagem (12.0 = 12% ao mês).
  final double monthlyRate;
  final int totalInstallments;
  int paidInstallments;
  final double installmentValue;
  DateTime nextDue;

  int get remainingInstallments => totalInstallments - paidInstallments;

  /// Quanto ainda falta pagar (sem contar juros futuros).
  double get remainingAmount => remainingInstallments * installmentValue;

  /// Progresso de 0 a 1 (usado na barra de progresso).
  double get progress =>
      totalInstallments == 0 ? 0 : paidInstallments / totalInstallments;

  bool get isPaidOff => remainingInstallments <= 0;

  /// Registra uma parcela paga e empurra o vencimento para o mês seguinte.
  void payInstallment() {
    if (isPaidOff) return;
    paidInstallments++;
    final day = nextDue.day > 28 ? 28 : nextDue.day; // evita dia 31 em fevereiro
    nextDue = DateTime(nextDue.year, nextDue.month + 1, day);
  }
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

/// Porcentagem geral do plano (0 a 1), somando o valor de todas as parcelas.
double planProgress(List<Debt> debts) {
  var total = 0.0;
  var paid = 0.0;
  for (final debt in debts) {
    total += debt.totalInstallments * debt.installmentValue;
    paid += debt.paidInstallments * debt.installmentValue;
  }
  return total == 0 ? 0 : paid / total;
}
