import 'package:flutter/material.dart';

import '../core/accessibility.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'audio_button.dart';

/// Abre a janela de acessibilidade (tamanho da letra e audiodescrição).
///
/// [description] é o texto lido em voz alta para descrever a tela atual.
///
/// `showModalBottomSheet` abre um painel que sobe da parte de baixo e bloqueia
/// o resto da tela até ser fechado.
Future<void> showAccessibilitySheet(
  BuildContext context, {
  required String description,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // deixa o painel crescer com letras grandes
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _AccessibilitySheet(description: description),
  );
}

class _AccessibilitySheet extends StatelessWidget {
  const _AccessibilitySheet({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.accessibility_new, size: 32),
                const SizedBox(width: 10),
                const Expanded(child: Text('Acessibilidade', style: AppText.h1)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Tamanho da letra', style: AppText.h3),
            const SizedBox(height: 4),
            const Text('Escolha o tamanho que fica melhor para você.', style: AppText.small),
            const SizedBox(height: 12),
            // O ValueListenableBuilder redesenha as opções quando o tamanho muda.
            ValueListenableBuilder<double>(
              valueListenable: AccessibilitySettings.textScale,
              builder: (context, current, _) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in textSizeOptions)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: current == option.scale,
                        onSelected: (_) {
                          AccessibilitySettings.textScale.value = option.scale;
                        },
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: AppColors.petrol,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: current == option.scale
                              ? Colors.white
                              : AppColors.petrol,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Audiodescrição', style: AppText.h3),
            const SizedBox(height: 4),
            const Text('O app descreve em voz alta o que tem na tela.', style: AppText.small),
            const SizedBox(height: 12),
            AudioButton(text: description, label: 'Ouvir descrição desta tela'),
            const SizedBox(height: 24),
            AppButton(
              label: 'Fechar',
              kind: AppButtonKind.dark,
              showArrow: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
