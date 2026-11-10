import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../data/games_data.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mascot.dart';
import '../widgets/tag_chip.dart';

/// Catálogo de jogos em tela cheia (aberto pelo "Ver todos os jogos").
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        title: 'Jogos',
        audioText:
            'Jogos para aprender sobre dinheiro. Escolha um jogo e toque para começar.',
      ),
      body: const SafeArea(child: GamesCatalog()),
    );
  }
}

/// Lista de jogos. Também é usada como a aba "Aprender" da área da família.
///
/// É um StatefulWidget: guarda as estrelas de cada jogo e, quando uma partida
/// termina, usa `setState` para atualizar o total na hora.
class GamesCatalog extends StatefulWidget {
  const GamesCatalog({super.key});

  @override
  State<GamesCatalog> createState() => _GamesCatalogState();
}

class _GamesCatalogState extends State<GamesCatalog> {
  final Map<String, int> _bestStars = {};

  int get _totalStars => _bestStars.values.fold(0, (sum, value) => sum + value);

  void _onResult(GameResult result) {
    setState(() {
      final previous = _bestStars[result.gameId] ?? 0;
      _bestStars[result.gameId] = math.max(previous, result.stars);
    });
  }

  void _openGame(GameInfo game) {
    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: GameArgs(game: game, onResult: _onResult),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalStars;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecor.card(color: AppColors.peachSoft, radius: 26),
          child: Row(
            children: [
              const Mascot(height: 80),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aprender jogando', style: AppText.h2),
                    const SizedBox(height: 4),
                    const Text(
                      'Jogue no seu tempo. Cada jogo explica o porquê das respostas.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: 8),
                    TagChip(
                      icon: Icons.star,
                      label: total == 1 ? '1 estrela' : '$total estrelas',
                      background: AppColors.card,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final game in allGames)
          _GameTile(
            game: game,
            stars: _bestStars[game.id] ?? 0,
            onTap: () => _openGame(game),
          ),
      ],
    );
  }
}

/// Cartão de um jogo na lista (usa o widget Card do Material).
class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.stars,
    required this.onTap,
  });

  final GameInfo game;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: game.color,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias, // recorta o "efeito de toque" nos cantos
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, color: AppColors.petrol, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagChip(
                      label: '${game.level} · ${game.minutes} min',
                      background: AppColors.card,
                    ),
                    const SizedBox(height: 6),
                    Text(game.title, style: AppText.h3),
                    const SizedBox(height: 2),
                    Text(game.subtitle, style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // As 3 estrelinhas mostram o melhor resultado neste jogo.
              Column(
                children: [
                  for (var i = 1; i <= 3; i++)
                    Icon(
                      i <= stars ? Icons.star : Icons.star_border,
                      size: 20,
                      color: AppColors.petrol,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
