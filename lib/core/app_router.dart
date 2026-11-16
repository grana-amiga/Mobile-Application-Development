import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../models/game.dart';
import '../models/lesson_video.dart';
import '../models/transaction.dart';
import '../screens/add_debt_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/main_shell.dart';
import '../screens/simulators_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/whatsapp_screen.dart';
import '../screens/game_screen.dart';
import '../screens/games_screen.dart';
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
      case AppRoutes.games:
        return _page(const GamesScreen(), settings);
      case AppRoutes.game:
        // Os parâmetros da rota chegam em `settings.arguments`.
        return _page(GameScreen(args: settings.arguments as GameArgs), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.main:
        return _page(const MainShell(), settings);
      case AppRoutes.addTransaction:
        // <Transaction?> faz a rota devolver o registro criado em `Navigator.pop`.
        return _page<Transaction?>(
          AddTransactionScreen(args: settings.arguments as AddTransactionArgs),
          settings,
        );
      case AppRoutes.addDebt:
        return _page<Debt?>(const AddDebtScreen(), settings);
      case AppRoutes.simulators:
        return _page(const SimulatorsScreen(), settings);
      case AppRoutes.video:
        return _page(
          VideoPlayerScreen(video: settings.arguments as LessonVideo),
          settings,
        );
      case AppRoutes.whatsapp:
        return _page(
          WhatsAppScreen(args: settings.arguments as WhatsAppArgs),
          settings,
        );
    }
    return null; // rota desconhecida
  }

  // MaterialPageRoute faz a transição padrão de tela de cada plataforma.
  // [T] é o tipo do valor que a tela devolve ao fechar (dynamic = qualquer um).
  static Route<T> _page<T>(Widget screen, RouteSettings settings) {
    return MaterialPageRoute<T>(
      builder: (context) => screen,
      settings: settings,
    );
  }
}
