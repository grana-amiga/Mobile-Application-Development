import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import 'app_routes.dart';

/// Navegação feita de fora das telas (sem `BuildContext`).
///
/// Quando o token vence no meio do uso, o `ApiClient` não tem uma tela para
/// navegar. Esta chave global dá acesso ao Navigator do app inteiro.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static bool _handling = false; // evita tratar o mesmo aviso várias vezes

  /// Sai da conta e leva a pessoa para o login com um aviso.
  static void sessionExpired() {
    if (_handling) return;
    _handling = true;

    AuthService.instance.logout();
    key.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);

    // Espera a tela de login aparecer para mostrar o aviso nela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null && context.mounted) {
        showAppSnackBar(
          context,
          'Sua sessão expirou. Entre de novo para continuar.',
          isError: true,
        );
      }
      _handling = false;
    });
  }
}
