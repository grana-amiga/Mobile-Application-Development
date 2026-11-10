import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/games_data.dart';
import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

/// Jogo "Cofrinho que cresce": para cada meta, a pessoa escolhe quanto guardar
/// por mês e vê se chega lá no prazo.
///
/// Meta batida = 20 pontos. Chegou na metade = 10. Menos que isso = 5.
class SavingsGameView extends StatefulWidget {
  const SavingsGameView({
    super.key,
    required this.onPoints,
    required this.onFinished,
  });

  final ValueChanged<int> onPoints;
  final VoidCallback onFinished;

  @override
  State<SavingsGameView> createState() => _SavingsGameViewState();
}

class _SavingsGameViewState extends State<SavingsGameView> {
  int _index = 0; // meta atual
  double _deposit = 0; // valor mensal escolhido na barra (Slider)
  bool _checked = false; // já confirmou o valor desta meta?

  SavingsGoal get _goal => savingsGoals[_index];
  bool get _isLast => _index == savingsGoals.length - 1;
  double get _projected => _deposit * _goal.months;
  bool get _reachedGoal => _projected >= _goal.goal;

  void _confirm() {
    setState(() => _checked = true);
    if (_reachedGoal) {
      widget.onPoints(20);
    } else if (_projected >= _goal.goal / 2) {
      widget.onPoints(10);
    } else {
      widget.onPoints(5);
    }
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
    } else {
      setState(() {
        _index++;
        _deposit = 0;
        _checked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final progress = (_projected / goal.goal).clamp(0.0, 1.0).toDouble();
    final missing = goal.goal - _projected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text('Meta ${_index + 1} de ${savingsGoals.length}', style: AppText.small),
        const SizedBox(height: 10),
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
                    decoration: const BoxDecoration(
                      color: AppColors.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(goal.icon, color: AppColors.petrol, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(goal.title, style: AppText.h2)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Queremos juntar ${formatBRL(goal.goal.toDouble())} em ${goal.months} meses.',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              Text(
                'Do orçamento, dá para guardar até ${formatBRL(goal.maxDeposit.toDouble())} por mês.',
                style: AppText.small,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Quanto guardar por mês?', style: AppText.h3),
        const SizedBox(height: 4),
        Text(
          _deposit == 0
              ? 'Mexa na barra para escolher'
              : '${formatBRL(_deposit)} por mês',
          style: AppText.h1.copyWith(fontSize: 30),
        ),
        // Slider: barra deslizante. `divisions` faz o valor pular de 5 em 5.
        Slider(
          value: _deposit,
          min: 0,
          max: goal.maxDeposit.toDouble(),
          divisions: goal.maxDeposit ~/ 5,
          label: formatBRL(_deposit),
          activeColor: AppColors.petrol,
          inactiveColor: const Color(0x330F4C5C),
          onChanged: _checked ? null : (value) => setState(() => _deposit = value),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecor.card(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Em ${goal.months} meses você junta ${formatBRL(_projected)}',
                style: AppText.h3,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: AppColors.border,
                  color: _reachedGoal ? AppColors.green : AppColors.peach,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _reachedGoal
                    ? 'Meta alcançada!'
                    : 'Faltam ${formatBRL(missing)} para a meta.',
                style: AppText.small,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!_checked)
          AppButton(
            label: 'Guardar esse valor',
            icon: Icons.savings,
            onPressed: _deposit == 0 ? null : _confirm,
          )
        else ...[
          _ResultCard(
            reached: _reachedGoal,
            text: _reachedGoal
                ? 'Você chega lá! Guardando um pouco todo mês, a meta fica no caminho. +20 pontos'
                : 'Ainda faltam ${formatBRL(missing)}. Tente guardar um pouco mais por mês na próxima. '
                    '${_projected >= _goal.goal / 2 ? '+10 pontos' : '+5 pontos'}',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _isLast ? 'Ver resultado' : 'Próxima meta',
            onPressed: _next,
          ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.reached, required this.text});

  final bool reached;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reached ? AppColors.mintSoft : AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reached ? Icons.celebration : Icons.lightbulb,
            color: AppColors.petrol,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
