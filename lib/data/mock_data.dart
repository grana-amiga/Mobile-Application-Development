import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/debt.dart';
import '../models/transaction.dart';

/// Dados de exemplo (mock) da família da demonstração.
///
/// O app ainda não tem servidor nem banco de dados: tudo é gerado aqui.
/// As datas são calculadas a partir de "hoje" para a demonstração sempre
/// parecer atual.
class MockData {
  MockData._();

  /// Renda de exemplo: R$ 2.400 por mês, com R$ 2.080 em gastos.
  static List<Transaction> transactions(DateTime now) {
    TxCategory expense(String label) => findCategory(label, TransactionType.expense)!;
    TxCategory income(String label) => findCategory(label, TransactionType.income)!;

    // Volta [days] dias, mas sem sair do mês atual.
    DateTime daysAgo(int days) =>
        DateTime(now.year, now.month, math.max(1, now.day - days));

    return [
      Transaction(
        type: TransactionType.expense,
        category: expense('Comida'),
        amount: 190,
        date: daysAgo(0),
        note: 'Padaria e almoço',
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Remédio'),
        amount: 84,
        date: daysAgo(1),
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Mercado'),
        amount: 520,
        date: daysAgo(2),
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Transporte'),
        amount: 210,
        date: daysAgo(3),
        note: 'Passagens do mês',
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Água'),
        amount: 62,
        date: daysAgo(4),
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Luz'),
        amount: 144,
        date: daysAgo(5),
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Escola'),
        amount: 120,
        date: daysAgo(6),
        note: 'Material escolar',
      ),
      Transaction(
        type: TransactionType.expense,
        category: expense('Casa'),
        amount: 750,
        date: daysAgo(7),
        note: 'Aluguel',
      ),
      Transaction(
        type: TransactionType.income,
        category: income('Salário'),
        amount: 2400,
        date: daysAgo(8),
        note: 'Salário',
      ),
    ];
  }

  /// Dívidas de exemplo. O cartão tem os maiores juros e deve ser pago antes.
  static List<Debt> debts(DateTime now) {
    DateTime inDays(int days) => now.add(Duration(days: days));

    return [
      Debt(
        name: 'Compra parcelada',
        icon: Icons.home,
        monthlyRate: 3.5,
        totalInstallments: 8,
        paidInstallments: 4,
        installmentValue: 120,
        nextDue: inDays(3),
      ),
      Debt(
        name: 'Cartão de crédito',
        icon: Icons.credit_card,
        monthlyRate: 12,
        totalInstallments: 6,
        paidInstallments: 2,
        installmentValue: 250,
        nextDue: inDays(5),
      ),
      Debt(
        name: 'Empréstimo pessoal',
        icon: Icons.account_balance,
        monthlyRate: 5,
        totalInstallments: 10,
        paidInstallments: 7,
        installmentValue: 90,
        nextDue: inDays(12),
      ),
    ];
  }

  /// Contas fixas que também aparecem nos alertas de vencimento.
  static List<Bill> fixedBills(DateTime now) {
    DateTime inDays(int days) => now.add(Duration(days: days));

    return [
      Bill(
        name: 'Internet',
        icon: Icons.wifi,
        amount: 99,
        due: inDays(6),
      ),
      Bill(
        name: 'Conta de luz (estimada)',
        icon: Icons.bolt,
        amount: 144,
        due: inDays(9),
      ),
      Bill(
        name: 'Conta de água',
        icon: Icons.water_drop,
        amount: 62,
        due: inDays(10),
      ),
    ];
  }
}
