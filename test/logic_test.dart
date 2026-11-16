import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grana_amiga/core/formatters.dart';
import 'package:grana_amiga/data/videos_data.dart';
import 'package:grana_amiga/models/debt.dart';
import 'package:grana_amiga/models/game.dart';
import 'package:grana_amiga/models/money_summary.dart';
import 'package:grana_amiga/models/transaction.dart';
import 'package:grana_amiga/services/chat_parser.dart';

// Categorias de exemplo, com os mesmos nomes que a API cadastra.
const List<TxCategory> _categories = [
  TxCategory(
    id: 1,
    label: 'Mercado',
    icon: Icons.shopping_cart,
    type: TransactionType.expense,
  ),
  TxCategory(
    id: 2,
    label: 'Outros gastos',
    icon: Icons.category,
    type: TransactionType.expense,
  ),
  TxCategory(
    id: 3,
    label: 'Salário',
    icon: Icons.payments,
    type: TransactionType.income,
  ),
  TxCategory(
    id: 4,
    label: 'Outras entradas',
    icon: Icons.category,
    type: TransactionType.income,
  ),
];

/// Movimentações de exemplo: entra 1500 e sai 1180 (sobra 320).
List<Transaction> _sampleTransactions() => [
      Transaction(
        type: TransactionType.income,
        category: _categories[2],
        amount: 1500,
        date: DateTime(2026, 11, 5),
      ),
      Transaction(
        type: TransactionType.expense,
        category: _categories[0],
        amount: 1180,
        date: DateTime(2026, 11, 6),
      ),
    ];

Debt _debt({
  required int id,
  required String name,
  required double rate,
  double balance = 500,
  int dueDay = 10,
}) {
  return Debt(
    id: id,
    name: name,
    type: DebtType.other,
    balance: balance,
    monthlyRate: rate,
    installmentValue: 100,
    dueDay: dueDay,
    isPaidOff: false,
  );
}

void main() {
  group('formatters', () {
    test('formatBRL adds thousands separator and cents', () {
      expect(formatBRL(1234.5), 'R\$ 1.234,50');
      expect(formatBRL(0), 'R\$ 0,00');
      expect(formatBRL(-20), '-R\$ 20,00');
    });

    test('parseAmount reads Brazilian numbers and rejects invalid text', () {
      expect(parseAmount('10,50'), 10.5);
      expect(parseAmount('1.200,00'), 1200.0);
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });

  group('money summary', () {
    test('summary adds income and expenses and lands on a level', () {
      final summary = MoneySummary.fromTransactions(_sampleTransactions());
      expect(summary.income, 1500);
      expect(summary.expenses, 1180);
      expect(summary.balance, 320);
      expect(summary.level, ThermometerLevel.attention);
    });

    test('balance drops when an expense is registered', () {
      final list = _sampleTransactions();
      final before = MoneySummary.fromTransactions(list).balance;
      list.insert(
        0,
        Transaction(
          type: TransactionType.expense,
          category: _categories.first,
          amount: 50,
          date: DateTime(2026, 11, 10),
        ),
      );
      expect(MoneySummary.fromTransactions(list).balance, before - 50);
    });
  });

  group('games', () {
    test('GameResult.stars follows the score ratio', () {
      const id = 'x';
      expect(const GameResult(gameId: id, score: 10, maxScore: 10).stars, 3);
      expect(const GameResult(gameId: id, score: 5, maxScore: 10).stars, 2);
      expect(const GameResult(gameId: id, score: 1, maxScore: 10).stars, 1);
    });
  });

  group('debts', () {
    test('sortByInterest puts the highest rate first', () {
      final sorted = sortByInterest([
        _debt(id: 1, name: 'Loja', rate: 5),
        _debt(id: 2, name: 'Cartão de crédito', rate: 12),
      ]);
      expect(sorted.first.name, 'Cartão de crédito');
    });

    test('nextDue rolls to next month and clamps short months', () {
      final debt = _debt(id: 1, name: 'Loja', rate: 5, dueDay: 31);
      expect(debt.nextDue(DateTime(2026, 11, 10)), DateTime(2026, 11, 30));
      expect(debt.nextDue(DateTime(2026, 11, 30)), DateTime(2026, 11, 30));
      final early = _debt(id: 2, name: 'Luz', rate: 0, dueDay: 5);
      expect(early.nextDue(DateTime(2026, 11, 10)), DateTime(2026, 12, 5));
    });

    test('progress uses the initial balance', () {
      final debt = _debt(id: 1, name: 'Loja', rate: 5, balance: 250)
        ..initialBalance = 1000;
      expect(debt.progress, 0.75);
    });
  });

  group('video lessons', () {
    test('has 6 numbered lessons with distinct files', () {
      expect(allVideos.length, 6);
      expect(allVideos.map((v) => v.number).toList(), [1, 2, 3, 4, 5, 6]);
      expect(allVideos.map((v) => v.asset).toSet().length, 6);
    });
  });

  group('chat parser', () {
    test('reads an expense with category', () {
      final entry = ChatParser.parse('Gastei 30 no mercado', _categories);
      expect(entry?.type, TransactionType.expense);
      expect(entry?.amount, 30);
      expect(entry?.category.label, 'Mercado');
    });

    test('reads income and number words', () {
      final entry = ChatParser.parse('Recebi vinte e cinco de um bico', _categories);
      expect(entry?.type, TransactionType.income);
      expect(entry?.amount, 25);
    });

    test('returns null when there is no amount', () {
      expect(ChatParser.parse('oi tudo bem', _categories), isNull);
    });
  });
}
