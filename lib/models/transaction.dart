import 'package:flutter/material.dart';

/// Tipo de movimentação: dinheiro que entra ou dinheiro que sai.
enum TransactionType { income, expense }

/// Categoria de uma movimentação (ícone grande + nome curto).
class TxCategory {
  const TxCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Categorias de gasto mostradas em figuras na tela "Registrar".
const List<TxCategory> expenseCategories = [
  TxCategory(label: 'Mercado', icon: Icons.shopping_cart),
  TxCategory(label: 'Transporte', icon: Icons.directions_bus),
  TxCategory(label: 'Luz', icon: Icons.bolt),
  TxCategory(label: 'Água', icon: Icons.water_drop),
  TxCategory(label: 'Comida', icon: Icons.restaurant),
  TxCategory(label: 'Remédio', icon: Icons.medication),
  TxCategory(label: 'Escola', icon: Icons.school),
  TxCategory(label: 'Lazer', icon: Icons.sports_esports),
  TxCategory(label: 'Casa', icon: Icons.home),
];

/// Categorias de entrada de dinheiro.
const List<TxCategory> incomeCategories = [
  TxCategory(label: 'Salário', icon: Icons.attach_money),
  TxCategory(label: 'Bico', icon: Icons.build),
  TxCategory(label: 'Benefício', icon: Icons.card_giftcard),
  TxCategory(label: 'Outros', icon: Icons.add_circle_outline),
];

/// Uma entrada ou saída de dinheiro registrada pela família.
class Transaction {
  const Transaction({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final TransactionType type;
  final TxCategory category;
  final double amount; // sempre positivo; o tipo diz se entra ou sai
  final DateTime date;
  final String note;

  bool get isExpense => type == TransactionType.expense;
}

/// Procura uma categoria pelo nome (ignorando maiúsculas). Usado pelo chat.
TxCategory? findCategory(String label, TransactionType type) {
  final list =
      type == TransactionType.expense ? expenseCategories : incomeCategories;
  for (final category in list) {
    if (category.label.toLowerCase() == label.toLowerCase()) return category;
  }
  return null;
}
