import 'package:flutter_test/flutter_test.dart';
import 'package:grana_amiga/core/formatters.dart';
import 'package:grana_amiga/data/mock_data.dart';
import 'package:grana_amiga/models/debt.dart';
import 'package:grana_amiga/models/game.dart';
import 'package:grana_amiga/models/money_summary.dart';
import 'package:grana_amiga/models/transaction.dart';
import 'package:grana_amiga/services/chat_parser.dart';

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
    test('demo data lands on the attention level', () {
      final summary = MoneySummary.fromTransactions(
        MockData.transactions(DateTime(2026, 11, 10)),
      );
      expect(summary.balance, 320);
      expect(summary.level, ThermometerLevel.attention);
    });

    test('balance drops when an expense is registered', () {
      final list = MockData.transactions(DateTime(2026, 11, 10));
      final before = MoneySummary.fromTransactions(list).balance;
      list.insert(
        0,
        Transaction(
          type: TransactionType.expense,
          category: expenseCategories.first,
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
      final sorted = sortByInterest(MockData.debts(DateTime(2026, 11, 10)));
      expect(sorted.first.name, 'Cartão de crédito');
    });
  });

  group('chat parser', () {
    test('reads an expense with category', () {
      final entry = ChatParser.parse('Gastei 30 no mercado');
      expect(entry?.type, TransactionType.expense);
      expect(entry?.amount, 30);
      expect(entry?.category.label, 'Mercado');
    });

    test('reads income and number words', () {
      final entry = ChatParser.parse('Recebi vinte e cinco de um bico');
      expect(entry?.type, TransactionType.income);
      expect(entry?.amount, 25);
    });

    test('returns null when there is no amount', () {
      expect(ChatParser.parse('oi tudo bem'), isNull);
    });
  });
}
