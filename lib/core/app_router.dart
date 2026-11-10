import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import 'app_routes.dart';

/// Converte o nome de uma rota na tela correspondente.
///
/// O Flutter chama [onGenerateRoute] toda vez que o código faz
/// `Navigator.pushNamed(...)`. Os parâmetros enviados chegam em
/// `settings.arguments`.
class AppRouter {
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return _page(const WelcomeScreen(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
    }
    return null; // rota desconhecida
  }

  // MaterialPageRoute faz a transição padrão de tela de cada plataforma.
  static Route<dynamic> _page(Widget screen, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => screen,
      settings: settings,
    );
  }
}
