import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Tipo de movimentação: dinheiro que entra ou dinheiro que sai.
enum TransactionType { income, expense }

extension TransactionTypeApi on TransactionType {
  /// Valor usado pela API (`ENTRADA` ou `SAIDA`).
  String get apiValue => this == TransactionType.income ? 'ENTRADA' : 'SAIDA';

  static TransactionType fromApi(dynamic value) =>
      value == 'ENTRADA' ? TransactionType.income : TransactionType.expense;
}

/// Ícones que a API pode mandar pelo nome (campo `icone` da categoria).
/// Se aparecer um nome desconhecido, usamos o ícone genérico de categoria.
const Map<String, IconData> _iconsByName = {
  'attach_money': Icons.attach_money,
  'add_circle_outline': Icons.add_circle_outline,
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'directions_bus': Icons.directions_bus,
  'home': Icons.home,
  'bolt': Icons.bolt,
  'medication': Icons.medication,
  'sports_esports': Icons.sports_esports,
  'inventory_2': Icons.inventory_2,
  'water_drop': Icons.water_drop,
  'school': Icons.school,
  'build': Icons.build,
  'card_giftcard': Icons.card_giftcard,
  'local_hospital': Icons.local_hospital,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'phone_android': Icons.phone_android,
  'wifi': Icons.wifi,
  'credit_card': Icons.credit_card,
};

IconData iconFromName(String? name) => _iconsByName[name] ?? Icons.category;

/// Categoria de uma movimentação (ícone grande + nome curto).
///
/// As categorias vêm da API (`GET /categorias`), por isso cada uma tem [id].
class TxCategory {
  const TxCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
  });

  factory TxCategory.fromJson(Map<String, dynamic> json) {
    return TxCategory(
      id: (json['id'] as num).toInt(),
      label: '${json['nome']}',
      icon: iconFromName(json['icone'] as String?),
      type: TransactionTypeApi.fromApi(json['tipo']),
    );
  }

  final int id;
  final String label;
  final IconData icon;
  final TransactionType type;
}

/// Uma entrada ou saída de dinheiro registrada pela família.
class Transaction {
  const Transaction({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  /// Converte o `TransacaoDto` da API.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    final type = TransactionTypeApi.fromApi(json['tipo']);
    return Transaction(
      id: (json['id'] as num?)?.toInt(),
      type: type,
      category: TxCategory(
        id: (json['categoriaId'] as num).toInt(),
        label: '${json['categoria']}',
        icon: iconFromName(json['icone'] as String?),
        type: type,
      ),
      amount: asDouble(json['valor']),
      date: asDate(json['dataTransacao']),
      note: (json['descricao'] as String?) ?? '',
    );
  }

  final int? id;
  final TransactionType type;
  final TxCategory category;
  final double amount; // sempre positivo; o tipo diz se entra ou sai
  final DateTime date;
  final String note;

  bool get isExpense => type == TransactionType.expense;
}

/// Categorias de um tipo (só entradas ou só saídas).
List<TxCategory> categoriesOf(List<TxCategory> all, TransactionType type) {
  return all.where((category) => category.type == type).toList();
}
