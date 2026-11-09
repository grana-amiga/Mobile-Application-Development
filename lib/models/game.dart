import 'package:flutter/material.dart';

/// Tipo de mecânica de cada jogo. Cada tipo tem sua própria tela de jogo.
enum GameKind {
  quiz, // perguntas com alternativas (Preciso ou Quero, Mito ou Verdade...)
  cart, // montar o carrinho sem passar do orçamento
  savings, // escolher quanto guardar por mês para chegar a uma meta
}

/// Uma rodada de pergunta e resposta.
class QuizRound {
  const QuizRound({
    required this.title,
    required this.icon,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.detail,
  });

  final String title;
  final String? detail;
  final IconData icon;
  final List<String> options;
  final int correctIndex;

  /// Explicação mostrada depois da resposta (aprender com o erro e o acerto).
  final String explanation;
}

/// Item à venda no jogo "Mercado sem aperto".
class CartItem {
  const CartItem({
    required this.name,
    required this.price,
    required this.icon,
    required this.essential,
  });

  final String name;
  final int price;
  final IconData icon;

  /// Itens essenciais valem mais pontos.
  final bool essential;
}

/// Meta do jogo "Cofrinho que cresce".
class SavingsGoal {
  const SavingsGoal({
    required this.title,
    required this.icon,
    required this.goal,
    required this.months,
    required this.maxDeposit,
  });

  final String title;
  final IconData icon;
  final int goal; // quanto a família quer juntar (R$)
  final int months; // em quantos meses
  final int maxDeposit; // quanto sobra no orçamento por mês (R$)
}

/// Informações de um jogo exibidas nos cartões e na tela de jogo.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.level,
    required this.minutes,
    required this.kind,
    required this.intro,
    required this.maxScore,
    this.rounds = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String level;
  final int minutes;
  final GameKind kind;

  /// Texto curto de instrução, também lido em voz alta.
  final String intro;

  /// Pontuação máxima possível (usada para calcular as estrelas).
  final int maxScore;
  final List<QuizRound> rounds;
}

/// Resultado final de uma partida.
class GameResult {
  const GameResult({
    required this.gameId,
    required this.score,
    required this.maxScore,
  });

  final String gameId;
  final int score;
  final int maxScore;

  /// 3 estrelas com 80% ou mais, 2 com 50% ou mais; participar já vale 1.
  int get stars {
    if (maxScore <= 0) return 1;
    final ratio = score / maxScore;
    if (ratio >= 0.8) return 3;
    if (ratio >= 0.5) return 2;
    return 1;
  }
}

/// Parâmetros enviados para a tela de jogo pela rota nomeada.
class GameArgs {
  const GameArgs({required this.game, this.onResult});

  final GameInfo game;

  /// Chamado quando a partida termina, para a tela anterior somar as estrelas.
  final ValueChanged<GameResult>? onResult;
}
