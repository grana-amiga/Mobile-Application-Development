import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Amiguinho", a moedinha que guia a pessoa pelo app.
///
/// [Image.asset] carrega a imagem que declaramos no pubspec.yaml. O
/// `semanticLabel` descreve a figura para leitores de tela.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mascot.png',
      height: height,
      semanticLabel: 'Amiguinho, a moedinha que ajuda você',
    );
  }
}

/// Cartão com o mascote dando uma dica curta (mensagem amiga em cada tela).
class MascotTip extends StatelessWidget {
  const MascotTip({
    super.key,
    required this.title,
    required this.message,
    this.background = AppColors.peachSoft,
  });

  final String title;
  final String message;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Mascot(height: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3),
                const SizedBox(height: 4),
                Text(message, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
