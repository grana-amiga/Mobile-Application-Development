import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/app_routes.dart';
import '../data/videos_data.dart';
import '../models/lesson_video.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

/// Tela de uma videoaula: player com play/pausa, barra de progresso e botão
/// para a próxima aula.
///
/// O [VideoPlayerController] precisa ser criado, inicializado e, no fim,
/// descartado (`dispose`) pela própria tela, por isso ela é um StatefulWidget.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.video});

  final LessonVideo video;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.video.asset);
    _start();
  }

  // `initialize` carrega o arquivo e descobre tamanho e duração. É assíncrono,
  // então mostramos um indicador de carregamento até terminar.
  Future<void> _start() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      showAppSnackBar(
        context,
        'Não foi possível abrir o vídeo. Tente de novo mais tarde.',
        isError: true,
      );
    }
  }

  // Sempre liberar o controller ao sair da tela, senão o vídeo continua
  // ocupando memória (e o som pode continuar tocando).
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
      return;
    }
    // Se o vídeo terminou, volta ao começo antes de tocar de novo.
    final atEnd =
        value.duration > Duration.zero && value.position >= value.duration;
    if (atEnd) _controller.seekTo(Duration.zero);
    _controller.play();
  }

  String _format(Duration time) {
    final minutes = time.inMinutes.toString().padLeft(2, '0');
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  LessonVideo? get _next {
    final index = allVideos.indexWhere((v) => v.number == widget.video.number);
    if (index == -1 || index + 1 >= allVideos.length) return null;
    return allVideos[index + 1];
  }

  void _openNext(LessonVideo next) {
    // pushReplacementNamed troca esta tela pela próxima (o "voltar" continua
    // levando à lista de aulas).
    Navigator.pushReplacementNamed(context, AppRoutes.video, arguments: next);
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final next = _next;
    final maxPlayerHeight = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      appBar: buildAppBar(title: 'Aula ${video.number}'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            _buildPlayer(maxPlayerHeight),
            const SizedBox(height: 16),
            if (_ready) _buildControls(),
            const SizedBox(height: 16),
            Text(video.title, style: AppText.h1.copyWith(fontSize: 28)),
            const SizedBox(height: 6),
            Text(video.description, style: AppText.body),
            const SizedBox(height: 20),
            if (next != null)
              AppButton(
                label: 'Próxima aula: ${next.title}',
                icon: Icons.skip_next,
                kind: AppButtonKind.dark,
                showArrow: false,
                onPressed: () => _openNext(next),
              )
            else
              const Text(
                'Você chegou à última aula. Parabéns! 🎉',
                style: AppText.h3,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(double maxHeight) {
    // Enquanto carrega (ou se falhar), mostra uma caixa com o mesmo formato.
    if (!_ready) {
      return Container(
        height: maxHeight * 0.6,
        decoration: BoxDecoration(
          color: _failed ? AppColors.brickSoft : AppColors.petrolDark,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: _failed
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.brickDark, size: 32),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text('Não foi possível abrir o vídeo.',
                            style: AppText.h3),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // ClipRRect arredonda os cantos; AspectRatio mantém a proporção do vídeo
    // e ConstrainedBox impede que ele fique mais alto que metade da tela.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: GestureDetector(
              onTap: _togglePlay,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );
  }

  // ValueListenableBuilder redesenha só os controles quando o vídeo muda
  // (a posição muda várias vezes por segundo).
  Widget _buildControls() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final atEnd =
            value.duration > Duration.zero && value.position >= value.duration;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecor.card(radius: 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: value.isPlaying ? 'Pausar' : 'Tocar',
                    onPressed: _togglePlay,
                    iconSize: 34,
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause
                          : (atEnd ? Icons.replay : Icons.play_arrow),
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.petrol,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true, // permite arrastar para avançar
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.green,
                        bufferedColor: AppColors.mint,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_format(value.position)} / ${_format(value.duration)}',
                  style: AppText.small,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
