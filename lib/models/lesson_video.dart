import 'package:flutter/material.dart';

/// Uma videoaula curta da aba "Aprender".
class LessonVideo {
  const LessonVideo({
    required this.number,
    required this.title,
    required this.description,
    required this.asset,
    required this.duration,
    required this.icon,
  });

  /// Número da aula (1 a 6), na ordem em que devem ser assistidas.
  final int number;
  final String title;
  final String description;

  /// Caminho do arquivo dentro de `assets/videos/`.
  final String asset;
  final Duration duration;
  final IconData icon;
}
