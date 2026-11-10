import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/audio_button.dart';

/// Jogo de perguntas e respostas (Preciso ou Quero?, Parcelar ou esperar?,
/// Mito ou Verdade?). Todos usam esta mesma tela, só muda o conteúdo.
///
/// Cada resposta certa vale 10 pontos. Depois de responder, o jogo explica o
/// porquê, para a pessoa aprender também quando erra.
class QuizGameView extends StatefulWidget {
  const QuizGameView({
    super.key,
    required this.game,
    required this.onPoints,
    required this.onFinished,
  });

  final GameInfo game;

  /// Avisa a tela do jogo para somar pontos (ela chama `setState`).
  final ValueChanged<int> onPoints;

  /// Avisa que a última pergunta foi respondida.
  final VoidCallback onFinished;

  @override
  State<QuizGameView> createState() => _QuizGameViewState();
}

enum _OptionState { idle, correct, wrong, dimmed }

class _QuizGameViewState extends State<QuizGameView> {
  static const int _pointsPerAnswer = 10;

  int _index = 0; // pergunta atual
  int? _selected; // alternativa escolhida (null = ainda não respondeu)

  QuizRound get _round => widget.game.rounds[_index];
  bool get _isLast => _index == widget.game.rounds.length - 1;

  void _answer(int option) {
    if (_selected != null) return; // só vale a primeira escolha
    setState(() => _selected = option);
    if (option == _round.correctIndex) {
      widget.onPoints(_pointsPerAnswer);
    }
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  _OptionState _stateOf(int option) {
    final selected = _selected;
    if (selected == null) return _OptionState.idle;
    if (option == _round.correctIndex) return _OptionState.correct;
    if (option == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final total = widget.game.rounds.length;
    final selected = _selected;
    final answered = selected != null;
    final isCorrect = selected == round.correctIndex;
    final detail = round.detail;

    final spokenText =
        '${round.title} ${detail ?? ''} Opções: ${round.options.join(', ')}.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          'Pergunta ${_index + 1} de $total',
          style: AppText.small,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_index + (answered ? 1 : 0)) / total,
            minHeight: 12,
            backgroundColor: AppColors.border,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppDecor.card(radius: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.game.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(round.icon, color: AppColors.petrol, size: 30),
                  ),
                  const Spacer(),
                  AudioButton(text: spokenText),
                ],
              ),
              const SizedBox(height: 14),
              Text(round.title, style: AppText.h2.copyWith(fontSize: 22)),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail, style: AppText.body),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < round.options.length; i++) ...[
          _OptionButton(
            label: round.options[i],
            state: _stateOf(i),
            onTap: () => _answer(i),
          ),
          const SizedBox(height: 12),
        ],
        if (answered) ...[
          const SizedBox(height: 4),
          _ExplanationCard(correct: isCorrect, text: round.explanation),
          const SizedBox(height: 16),
          AppButton(
            label: _isLast ? 'Ver resultado' : 'Próxima',
            onPressed: _next,
          ),
        ],
      ],
    );
  }
}

/// Botão de alternativa. Depois da resposta mostra um ícone (certo/errado)
/// além da cor.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.card;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.petrol;
    IconData? trailingIcon;

    switch (state) {
      case _OptionState.idle:
        break;
      case _OptionState.correct:
        background = AppColors.mintSoft;
        borderColor = AppColors.green;
        trailingIcon = Icons.check_circle;
        break;
      case _OptionState.wrong:
        background = AppColors.brickSoft;
        borderColor = AppColors.brick;
        textColor = AppColors.brickDark;
        trailingIcon = Icons.cancel;
        break;
      case _OptionState.dimmed:
        textColor = AppColors.textSoft;
        break;
    }

    final icon = trailingIcon;

    return Semantics(
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: state == _OptionState.idle ? 1.5 : 2.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: textColor, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explicação mostrada depois de responder.
class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correct ? AppColors.mintSoft : AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.celebration : Icons.lightbulb,
                color: AppColors.petrol,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Muito bem! +10 pontos' : 'Quase! Veja a dica:',
                style: AppText.h3,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}
