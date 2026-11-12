import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../data/games_data.dart';
import '../data/videos_data.dart';
import '../models/game.dart';
import '../models/lesson_video.dart';
import '../theme/app_theme.dart';
import '../widgets/accessibility_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/audio_button.dart';
import '../widgets/mascot.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

/// Tela 1: Início (área aberta, antes do login).
///
/// Mostra o logo, o botão de acessibilidade (audiodescrição), a mensagem de
/// boas-vindas com áudio, o carrossel de jogos e o botão para entrar.
///
/// É um StatefulWidget porque guarda as estrelas ganhas nos jogos: quando um
/// jogo termina, chamamos `setState` e o contador da tela é atualizado.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const String _presentation =
      'Bem-vindo ao Grana Amiga. Aqui você aprende a cuidar do dinheiro e '
      'organiza as contas da família. É gratuito e não precisa de cadastro '
      'para jogar. Vamos juntos?';

  static const String _screenDescription =
      'Tela inicial do Grana Amiga. No topo, o logo e o botão de acessibilidade. '
      'Em seguida, uma mensagem de boas-vindas com o Amiguinho, a moedinha que '
      'guia você. Mais abaixo, cartões com jogos para aprender sobre dinheiro e '
      'cartões com seis videoaulas rápidas, que você pode assistir sem cadastro. '
      'No fim da tela, o botão para entrar ou criar a sua conta.';

  /// Tons pastel dos cartões de videoaula, em sequência.
  static const List<Color> _pastels = [
    Color(0xFFF7D9E2), // rosa claro
    Color(0xFFE4DCF3), // lilás claro
    Color(0xFFCDE5EA), // azul claro (o mesmo dos jogos)
    AppColors.yellowSoft,
    AppColors.mintSoft,
    AppColors.peachSoft,
  ];

  /// Melhor resultado (em estrelas) de cada jogo jogado nesta sessão.
  final Map<String, int> _bestStars = {};

  int get _totalStars => _bestStars.values.fold(0, (sum, value) => sum + value);

  // Chamado pela tela de jogo quando uma partida termina. O `setState` avisa
  // o Flutter que os dados mudaram, e a tela é desenhada de novo.
  void _onGameResult(GameResult result) {
    setState(() {
      final previous = _bestStars[result.gameId] ?? 0;
      _bestStars[result.gameId] = math.max(previous, result.stars);
    });
  }

  // Navegação: `pushNamed` abre a rota pelo nome e `arguments` leva os
  // parâmetros (qual jogo abrir e o que fazer com o resultado).
  void _openGame(GameInfo game) {
    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: GameArgs(game: game, onResult: _onGameResult),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = _totalStars;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _buildTopBar(context),
            const SizedBox(height: 20),
            _buildHero(),
            SectionTitle(
              'Jogos para aprender',
              trailing: stars == 0
                  ? null
                  : '$stars ${stars == 1 ? 'estrela' : 'estrelas'}',
            ),
            SizedBox(
              height: 214,
              // ListView horizontal = carrossel de cartões.
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allGames.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final game = allGames[index];
                  return _GameCarouselCard(
                    game: game,
                    stars: _bestStars[game.id] ?? 0,
                    onTap: () => _openGame(game),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.games),
                icon: const Icon(Icons.grid_view),
                label: const Text('Ver todos os jogos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.petrol,
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SectionTitle('Videoaulas rápidas',
                trailing: '${allVideos.length} aulas'),
            SizedBox(
              height: 190,
              // Outro carrossel horizontal, agora com as videoaulas.
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allVideos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final video = allVideos[index];
                  return _VideoCarouselCard(
                    video: video,
                    // Uma cor pastel diferente para cada uma das 6 aulas.
                    color: _pastels[index % _pastels.length],
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.video,
                      arguments: video,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Entrar / Criar minha conta',
              icon: Icons.lock,
              kind: AppButtonKind.dark,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Gratuito. Em parceria com CRAS, cooperativas e ONGs.',
                textAlign: TextAlign.center,
                style: AppText.small,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Linha do topo: logo + nome à esquerda, botão de acessibilidade à direita.
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.petrol,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grana Amiga', style: AppText.h2),
              Text('Um passo de cada vez', style: AppText.small),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Acessibilidade e audiodescrição',
          onPressed: () =>
              showAccessibilitySheet(context, description: _screenDescription),
          icon: const Icon(Icons.accessibility_new, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.petrol,
            minimumSize: const Size(52, 52),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  // Cartão de boas-vindas com fundo em degradê, texto, áudio e o mascote.
  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD9C2), AppColors.cream, AppColors.mintSoft],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OLÁ, QUE BOM TER VOCÊ AQUI', style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text('Dinheiro pode ser mais simples.',
              style: AppText.h1.copyWith(fontSize: 32)),
          const SizedBox(height: 10),
          const Text(
            'Aprenda e cuide das contas da família. Sem cobrança e sem julgamento.',
            style: AppText.body,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: AudioButton(
                      text: _presentation, label: 'Ouvir apresentação'),
                ),
              ),
              SizedBox(width: 8),
              Mascot(height: 112),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cartão de jogo do carrossel da tela inicial.
class _GameCarouselCard extends StatelessWidget {
  const _GameCarouselCard({
    required this.game,
    required this.stars,
    required this.onTap,
  });

  final GameInfo game;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: game.color,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(game.icon, color: AppColors.petrol, size: 28),
                    ),
                    if (stars > 0)
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.petrol, size: 22),
                          const SizedBox(width: 2),
                          Text('$stars', style: AppText.h3),
                        ],
                      ),
                  ],
                ),
                const Spacer(),
                TagChip(
                  label: '${game.level} · ${game.minutes} min',
                  background: AppColors.card,
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  style: AppText.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de videoaula do carrossel da tela inicial.
class _VideoCarouselCard extends StatelessWidget {
  const _VideoCarouselCard({
    required this.video,
    required this.color,
    required this.onTap,
  });

  final LessonVideo video;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: AppColors.petrol, size: 32),
                ),
                const Spacer(),
                TagChip(
                  icon: Icons.schedule,
                  label: video.durationLabel,
                  background: AppColors.card,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aula ${video.number} · ${video.title}',
                  style: AppText.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
