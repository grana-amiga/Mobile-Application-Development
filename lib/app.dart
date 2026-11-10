import 'package:flutter/material.dart';

import 'core/accessibility.dart';
import 'core/app_router.dart';
import 'core/app_routes.dart';
import 'theme/app_theme.dart';

/// Widget raiz do aplicativo: configura tema, rotas e acessibilidade.
class GranaAmigaApp extends StatelessWidget {
  const GranaAmigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta o tamanho de letra escolhido pela pessoa: quando ele muda, o app
    // inteiro é redesenhado com o novo tamanho.
    return ValueListenableBuilder<double>(
      valueListenable: AccessibilitySettings.textScale,
      builder: (context, scale, child) {
        return MaterialApp(
          title: 'Grana Amiga',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          initialRoute: AppRoutes.welcome,
          onGenerateRoute: AppRouter.onGenerateRoute,
          // O `builder` envolve todas as telas. Aqui aplicamos o tamanho do
          // texto e limitamos a largura no Web/tablet para o app não esticar.
          builder: (context, screen) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
              child: ColoredBox(
                color: AppColors.cream,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: screen,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
