import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../services/api_client.dart';

/// Uma conta com data de vencimento (aparece na tela de alertas).
class Bill {
  const Bill({
    required this.debtId,
    required this.name,
    required this.icon,
    required this.amount,
    required this.due,
  });

  /// Converte o `AlertaVencimentoResponse` da API.
  factory Bill.fromJson(Map<String, dynamic> json, IconData icon) {
    // A data vem como "2026-11-20" (sem hora): lemos só ano, mês e dia.
    final parsed = asDate(json['dataVencimento']);
    return Bill(
      debtId: (json['dividaId'] as num).toInt(),
      name: '${json['credor']}',
      icon: icon,
      amount: asDouble(json['valorParcela']),
      due: DateTime(parsed.year, parsed.month, parsed.day),
    );
  }

  final int debtId;
  final String name;
  final IconData icon;
  final double amount;
  final DateTime due;
}

/// Quantas contas vencem nos próximos 7 dias (usado no aviso do painel).
int dueThisWeek(List<Bill> bills, DateTime now) {
  return bills.where((bill) {
    final days = daysBetween(now, bill.due);
    return days >= 0 && days <= 7;
  }).length;
}
