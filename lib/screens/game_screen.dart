import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/game.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mascot.dart';
import 'games/cart_game_view.dart';
import 'games/quiz_game_view.dart';
import 'games/savings_game_view.dart';

/// Tela 2: Jogo / Simulador.
///
/// Recebe por parâmetro qual jogo abrir ([GameArgs]) e mantém a pontuação em
/// um `StatefulWidget`: a cada resposta o `setState` atualiza o placar.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.args});

  final GameArgs args;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _score = 0;
  bool _finished = false;

  // Muda a cada "Jogar de novo". Usada como `key` da tela do jogo: quando a
  // chave muda, o Flutter descarta o estado antigo e começa um jogo novo.
  int _attempt = 0;

  GameInfo get _game => widget.args.game;

  // Chamado pelas telas de jogo a cada resposta. O `setState` redesenha o
  // placar com a nova pontuação.
  void _addPoints(int points) {
    setState(() => _score += points);
  }

  // Chamado quando o jogo acaba: mostra o resultado e avisa a tela anterior
  // (para ela somar as estrelas) usando o callback recebido por parâmetro.
  void _finish() {
    setState(() => _finished = true);
    widget.args.onResult?.call(
      GameResult(gameId: _game.id, score: _score, maxScore: _game.maxScore),
    );
  }

  void _restart() {
    setState(() {
      _score = 0;
      _finished = false;
      _attempt++;
    });
  }

  Widget _buildGame() {
    final key = ValueKey<int>(_attempt);
    switch (_game.kind) {
      case GameKind.quiz:
        return QuizGameView(
          key: key,
          game: _game,
          onPoints: _addPoints,
          onFinished: _finish,
        );
      case GameKind.cart:
        return CartGameView(
          key: key,
          onPoints: _addPoints,
          onFinished: _finish,
        );
      case GameKind.savings:
        return SavingsGameView(
          key: key,
          onPoints: _addPoints,
          onFinished: _finish,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: _game.title, audioText: _game.intro),
      body: SafeArea(
        child: _finished
            ? _ResultView(
                result: GameResult(
                  gameId: _game.id,
                  score: _score,
                  maxScore: _game.maxScore,
                ),
                lesson: _game.lesson,
                onRestart: _restart,
                onBack: () => Navigator.pop(context),
              )
            : Column(
                children: [
                  _ScoreBar(score: _score, maxScore: _game.maxScore),
                  Expanded(child: _buildGame()),
                ],
              ),
      ),
    );
  }
}

/// Placar do topo: mostra a pontuação atual e muda a cada resposta.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.maxScore});

  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecor.card(color: AppColors.yellowSoft, radius: 20),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.petrol, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text('Pontos: $score', style: AppText.h2)),
          Text('de $maxScore', style: AppText.small),
        ],
      ),
    );
  }
}

/// Tela de resultado com estrelas, aprendizado e convite para criar conta.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.lesson,
    required this.onRestart,
    required this.onBack,
  });

  final GameResult result;
  final String lesson;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  String get _title {
    switch (result.stars) {
      case 3:
        return 'Parabéns! Você mandou muito bem!';
      case 2:
        return 'Muito bem! Falta pouco para as 3 estrelas.';
      default:
        return 'Boa tentativa! Errar faz parte de aprender.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = AuthService.instance.isLoggedIn;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const Center(child: Mascot(height: 130)),
        const SizedBox(height: 12),
        Text(_title, textAlign: TextAlign.center, style: AppText.h1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i <= result.stars ? Icons.star : Icons.star_border,
                  size: 56,
                  color: i <= result.stars ? AppColors.yellow : AppColors.textSoft,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${result.stars} de 3 estrelas · ${result.score} de ${result.maxScore} pontos',
          textAlign: TextAlign.center,
          style: AppText.h3,
        ),
        const SizedBox(height: 20),
        MascotTip(
          title: 'O que levamos daqui',
          message: lesson,
          background: AppColors.mintSoft,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Jogar de novo',
          icon: Icons.replay,
          showArrow: false,
          onPressed: onRestart,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Voltar aos jogos',
          kind: AppButtonKind.light,
          showArrow: false,
          onPressed: onBack,
        ),
        // Quem ainda não tem conta recebe um convite gentil.
        if (!loggedIn) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(color: AppColors.peachSoft, radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quer guardar seu progresso?', style: AppText.h3),
                const SizedBox(height: 4),
                const Text(
                  'Crie a sua conta gratuita e organize também as contas da família.',
                  style: AppText.body,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Criar minha conta',
                  kind: AppButtonKind.dark,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
