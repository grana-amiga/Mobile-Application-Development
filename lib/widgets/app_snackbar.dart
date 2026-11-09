import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mostra uma mensagem rápida na parte de baixo da tela (SnackBar).
///
/// O [ScaffoldMessenger] fica no topo do app e controla todos os SnackBars,
/// por isso a mensagem continua visível mesmo se a tela atual for fechada
/// logo depois (por exemplo, ao confirmar um gasto e voltar ao painel).
///
/// Use [isError] para avisos de erro: a cor muda para tijolo e o ícone para
/// um alerta, assim a pessoa entende o aviso sem depender só da cor.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar(); // evita empilhar mensagens
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? AppColors.brick : AppColors.petrol,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
