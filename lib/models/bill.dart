import 'package:flutter/material.dart';

import '../core/formatters.dart';
import 'debt.dart';

/// Uma conta com data de vencimento (aparece na tela de alertas).
class Bill {
  const Bill({
    required this.name,
    required this.icon,
    required this.amount,
    required this.due,
  });

  final String name;
  final IconData icon;
  final double amount;
  final DateTime due;
}

/// Junta contas fixas (internet, luz...) com a próxima parcela de cada dívida
/// ainda aberta, deixando só as que vencem nos próximos [withinDays] dias.
/// O resultado vem ordenado do vencimento mais próximo para o mais distante.
List<Bill> upcomingBills(
  List<Debt> debts,
  List<Bill> fixedBills,
  DateTime now, {
  int withinDays = 15,
}) {
  final bills = <Bill>[...fixedBills];
  for (final debt in debts) {
    if (debt.isPaidOff) continue;
    bills.add(
      Bill(
        name: debt.name,
        icon: debt.icon,
        amount: debt.installmentValue,
        due: debt.nextDue,
      ),
    );
  }
  final filtered = bills
      .where((bill) => daysBetween(now, bill.due) <= withinDays)
      .toList();
  filtered.sort((a, b) => a.due.compareTo(b.due));
  return filtered;
}

/// Quantas contas vencem nos próximos 7 dias (usado no aviso do painel).
int dueThisWeek(List<Bill> bills, DateTime now) {
  return bills.where((bill) {
    final days = daysBetween(now, bill.due);
    return days >= 0 && days <= 7;
  }).length;
}
