import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_navigator.dart';
import 'services/api_client.dart';

/// Ponto de entrada do aplicativo.
///
/// `runApp` recebe o widget raiz e o coloca na tela.
void main() {
  // Se a API recusar o token (sessão vencida), o app volta para o login.
  ApiClient.instance.onSessionExpired = AppNavigator.sessionExpired;
  runApp(const GranaAmigaApp());
}
