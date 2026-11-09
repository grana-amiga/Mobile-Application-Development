import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'transaction.dart';

/// Situação do orçamento no "Termômetro do Dinheiro".
enum ThermometerLevel { calm, attention, urgent }

/// Informações visuais de cada nível. Sempre mostramos cor + ícone + texto
/// (nunca só a cor), para ajudar pessoas com daltonismo.
extension ThermometerLevelInfo on ThermometerLevel {
  String get label {
    switch (this) {
      case ThermometerLevel.calm:
        return 'Tranquilo';
      case ThermometerLevel.attention:
        return 'Atenção';
      case ThermometerLevel.urgent:
        return 'Urgente';
    }
  }

  String get message {
    switch (this) {
      case ThermometerLevel.calm:
        return 'Suas contas cabem no seu dinheiro. Continue assim!';
      case ThermometerLevel.attention:
        return 'As contas cabem, mas está apertado.';
      case ThermometerLevel.urgent:
        return 'Quase todo o dinheiro já tem dono. Vamos ajustar juntos.';
    }
  }

  Color get color {
    switch (this) {
      case ThermometerLevel.calm:
        return AppColors.green;
      case ThermometerLevel.attention:
        return AppColors.yellow;
      case ThermometerLevel.urgent:
        return AppColors.brick;
    }
  }

  /// Cor do ícone/texto que fica por cima de [color] (garante contraste).
  Color get onColor =>
      this == ThermometerLevel.attention ? AppColors.petrolDark : Colors.white;

  IconData get icon {
    switch (this) {
      case ThermometerLevel.calm:
        return Icons.sentiment_satisfied_alt;
      case ThermometerLevel.attention:
        return Icons.sentiment_neutral;
      case ThermometerLevel.urgent:
        return Icons.sentiment_dissatisfied;
    }
  }
}

/// Resumo do mês calculado a partir da lista de movimentações.
class MoneySummary {
  const MoneySummary({required this.income, required this.expenses});

  /// Soma as entradas e as saídas da lista.
  factory MoneySummary.fromTransactions(List<Transaction> list) {
    var income = 0.0;
    var expenses = 0.0;
    for (final tx in list) {
      if (tx.isExpense) {
        expenses += tx.amount;
      } else {
        income += tx.amount;
      }
    }
    return MoneySummary(income: income, expenses: expenses);
  }

  final double income;
  final double expenses;

  /// Saldo: o que sobrou (ou faltou) no mês.
  double get balance => income - expenses;

  /// Quanto da renda já foi comprometido (0 a 1, ou mais se passou da renda).
  double get commitment {
    if (income <= 0) return expenses > 0 ? 1.0 : 0.0;
    return expenses / income;
  }

  /// Regra do Termômetro: até 70% da renda = Verde; até 90% = Amarelo;
  /// acima disso = Vermelho.
  ThermometerLevel get level {
    final value = commitment;
    if (value < 0.7) return ThermometerLevel.calm;
    if (value < 0.9) return ThermometerLevel.attention;
    return ThermometerLevel.urgent;
  }
}
