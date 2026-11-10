import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/games_data.dart';
import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/mascot.dart';

/// Jogo "Mercado sem aperto": a pessoa escolhe itens sem passar do dinheiro.
///
/// Itens essenciais valem 10 pontos, os extras valem 2. Se sobrar pelo menos
/// R$ 5 no fim, ganha mais 5 pontos (pensar na reserva também vale!).
class CartGameView extends StatefulWidget {
  const CartGameView({
    super.key,
    required this.onPoints,
    required this.onFinished,
  });

  final ValueChanged<int> onPoints;
  final VoidCallback onFinished;

  @override
  State<CartGameView> createState() => _CartGameViewState();
}

class _CartGameViewState extends State<CartGameView> {
  // Índices dos itens que estão no carrinho. Um Set não repete valores.
  final Set<int> _selected = {};

  int get _total =>
      _selected.fold(0, (sum, index) => sum + cartItems[index].price);

  int get _left => cartBudget - _total;
  bool get _overBudget => _total > cartBudget;

  void _toggle(int index) {
    // `remove` devolve true se o item estava no carrinho (e já o tirou);
    // se devolver false, o item não estava lá e então o adicionamos.
    setState(() {
      if (!_selected.remove(index)) {
        _selected.add(index);
      }
    });
  }

  int _score() {
    var points = 0;
    for (final index in _selected) {
      points += cartItems[index].essential ? 10 : 2;
    }
    if (_left >= 5) points += 5;
    return points;
  }

  void _finish() {
    widget.onPoints(_score());
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _selected.isNotEmpty && !_overBudget;
    final progress = (_total / cartBudget).clamp(0.0, 1.0).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        const MascotTip(
          title: 'Dica do Amiguinho',
          message:
              'Comece pelo que a família precisa. Os extras só entram se sobrar.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecor.card(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Figure(label: 'Você tem', value: formatBRL(cartBudget.toDouble())),
                  ),
                  Expanded(
                    child: _Figure(label: 'No carrinho', value: formatBRL(_total.toDouble())),
                  ),
                  Expanded(
                    child: _Figure(
                      label: _overBudget ? 'Passou' : 'Sobra',
                      value: formatBRL(_left.abs().toDouble()),
                      alert: _overBudget,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: AppColors.border,
                  color: _overBudget ? AppColors.brick : AppColors.green,
                ),
              ),
              if (_overBudget) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.brickDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Passou ${formatBRL((-_left).toDouble())} do valor! Tire algum item.',
                        style: const TextStyle(
                          color: AppColors.brickDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // GridView.count monta uma grade com um número fixo de colunas.
        // `shrinkWrap` + `NeverScrollableScrollPhysics` deixam a grade do
        // tamanho do conteúdo, rolando junto com a lista de fora.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (var i = 0; i < cartItems.length; i++)
              _ItemTile(
                item: cartItems[i],
                selected: _selected.contains(i),
                onTap: () => _toggle(i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Finalizar compras',
          icon: Icons.shopping_cart_checkout,
          onPressed: canFinish ? _finish : null,
        ),
        if (!canFinish)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _overBudget
                  ? 'Tire itens até o valor caber nos R\$ 60.'
                  : 'Toque nos itens para colocar no carrinho.',
              textAlign: TextAlign.center,
              style: AppText.small,
            ),
          ),
      ],
    );
  }
}

/// Número com rótulo (ex.: "Você tem  R$ 60,00").
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.alert = false});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.small),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.h3.copyWith(
            color: alert ? AppColors.brickDark : AppColors.petrol,
          ),
        ),
      ],
    );
  }
}

/// Cartão de um produto: toque para pôr ou tirar do carrinho.
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CartItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.name}, ${formatBRL(item.price.toDouble())}',
      child: Material(
        color: selected ? AppColors.mintSoft : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, size: 36, color: AppColors.petrol),
                    // Ícone de "marcado" além da cor da borda.
                    Icon(
                      selected ? Icons.check_circle : Icons.add_circle_outline,
                      color: selected ? AppColors.green : AppColors.textSoft,
                      size: 28,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  style: AppText.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatBRL(item.price.toDouble()),
                  style: AppText.h2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
