import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';

/// Botão "Ouvir": lê [text] em voz alta.
///
/// Ajuda quem tem dificuldade de leitura. Se o aparelho não conseguir falar,
/// mostra um aviso de erro em vez de falhar em silêncio.
class AudioButton extends StatelessWidget {
  const AudioButton({super.key, required this.text, this.label = 'Ouvir'});

  final String text;
  final String label;

  // `async` permite usar `await`: esperamos o serviço de áudio responder
  // sem travar a tela. Depois do `await` a tela pode ter sido fechada, por
  // isso conferimos `context.mounted` antes de usar o contexto de novo.
  Future<void> _speak(BuildContext context) async {
    final ok = await AudioService.instance.speak(text);
    if (!ok && context.mounted) {
      showAppSnackBar(
        context,
        'Não foi possível ler em voz alta neste aparelho.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _speak(context),
      icon: const Icon(Icons.volume_up, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.petrol,
        backgroundColor: AppColors.card,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: const StadiumBorder(),
      ),
    );
  }
}
