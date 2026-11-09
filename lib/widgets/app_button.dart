import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estilos disponíveis para o [AppButton].
enum AppButtonKind {
  primary, // laranja-pêssego: ação principal da tela
  dark, // azul-petróleo: ação importante, mas secundária
  light, // fundo claro com borda: ação discreta
}

/// Botão grande e arredondado do app (altura mínima de 60 px, boa para o toque).
///
/// Mostra ícone opcional à esquerda e uma seta à direita. Se [onPressed] for
/// nulo o botão fica desabilitado; se [loading] for verdadeiro mostra um
/// indicador de progresso (feedback visual de "aguarde").
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.primary,
    this.showArrow = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool showArrow;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;
    BorderSide side = BorderSide.none;

    switch (kind) {
      case AppButtonKind.primary:
        background = AppColors.peach;
        foreground = AppColors.petrolDark;
        break;
      case AppButtonKind.dark:
        background = AppColors.petrol;
        foreground = Colors.white;
        break;
      case AppButtonKind.light:
        background = AppColors.card;
        foreground = AppColors.petrol;
        side = const BorderSide(color: AppColors.border, width: 1.5);
        break;
    }

    final iconData = icon; // cópia local para o Dart aceitar o teste de nulo
    final enabled = onPressed != null && !loading;

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: const Color(0x1F0F4C5C),
        disabledForegroundColor: AppColors.textSoft,
        elevation: 0,
        minimumSize: const Size.fromHeight(60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: AppText.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: side,
        ),
      ),
      child: loading
          ? SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: foreground,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconData != null) ...[
                  Icon(iconData, size: 26),
                  const SizedBox(width: 10),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
                if (showArrow) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 22),
                ],
              ],
            ),
    );
  }
}
