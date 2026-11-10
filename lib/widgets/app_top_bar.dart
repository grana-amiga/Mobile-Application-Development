import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'audio_button.dart';

/// AppBar padrão do app: fundo creme, título centralizado e, se [audioText]
/// for informado, o botão "Ouvir" que lê o texto em voz alta.
///
/// [extraActions] são botões extras exibidos antes do botão de áudio.
/// Com [compactAudio] o botão de áudio mostra só o ícone (cabe melhor).
AppBar buildAppBar({
  required String title,
  String? audioText,
  List<Widget> extraActions = const [],
  bool compactAudio = false,
}) {
  return AppBar(
    backgroundColor: AppColors.cream,
    surfaceTintColor: Colors.transparent,
    foregroundColor: AppColors.petrol,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    title: Text(
      title,
      style: AppText.h2,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    actions: [
      ...extraActions,
      if (audioText != null)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AudioButton(text: audioText, compact: compactAudio),
        ),
    ],
  );
}
