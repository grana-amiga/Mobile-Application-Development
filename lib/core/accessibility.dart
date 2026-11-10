import 'package:flutter/foundation.dart';

/// Ajustes de acessibilidade que valem para o app inteiro.
///
/// Usamos um [ValueNotifier]: um objeto que guarda um valor e avisa quem
/// está "ouvindo" quando ele muda. O widget raiz do app escuta o tamanho do
/// texto e redesenha tudo na hora quando a pessoa troca a opção.
class AccessibilitySettings {
  AccessibilitySettings._();

  /// Fator de tamanho do texto: 1.0 = normal, 1.2 = grande, 1.4 = extra grande.
  static final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);
}

/// Opções de tamanho de letra mostradas na janela de acessibilidade.
class TextSizeOption {
  const TextSizeOption(this.label, this.scale);

  final String label;
  final double scale;
}

const List<TextSizeOption> textSizeOptions = [
  TextSizeOption('Normal', 1.0),
  TextSizeOption('Grande', 1.2),
  TextSizeOption('Extra grande', 1.4),
];
