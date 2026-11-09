import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

/// Linha do "feed" de gastos: ícone da categoria, nome, data e valor.
///
/// Entradas aparecem em verde com "+", saídas em tijolo com "-". O sinal e o
/// texto garantem que a informação não dependa só da cor.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, required this.now});

  final Transaction transaction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final amountColor = isExpense ? AppColors.brickDark : AppColors.green;
    final sign = isExpense ? '-' : '+';
    final note = transaction.note;
    final subtitle = note.isEmpty
        ? relativeDay(transaction.date, now)
        : '${relativeDay(transaction.date, now)} · $note';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isExpense ? AppColors.peachSoft : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(transaction.category.icon, color: AppColors.petrol),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category.label, style: AppText.h3),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign ${formatBRL(transaction.amount)}',
            style: TextStyle(
              color: amountColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
