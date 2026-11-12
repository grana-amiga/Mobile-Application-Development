import 'package:flutter/material.dart';

import '../models/lesson_video.dart';

/// As 6 videoaulas do app, na ordem de estudo.
/// Para trocar um vídeo, substitua o arquivo em `assets/videos/`.
const List<LessonVideo> allVideos = [
  LessonVideo(
    number: 1,
    title: 'Raio-X do dinheiro',
    description: 'Descubra para onde o seu dinheiro está indo todo mês.',
    asset: 'assets/videos/aula1.mp4',
    duration: Duration(minutes: 1, seconds: 56),
    icon: Icons.search,
  ),
  LessonVideo(
    number: 2,
    title: 'Estancando o sangramento',
    description: 'Aprenda a cortar os gastos que fazem o dinheiro escorrer.',
    asset: 'assets/videos/aula2.mp4',
    duration: Duration(minutes: 2, seconds: 5),
    icon: Icons.healing,
  ),
  LessonVideo(
    number: 3,
    title: 'Regra das caixinhas',
    description: 'Separe o dinheiro em caixinhas para cada objetivo.',
    asset: 'assets/videos/aula3.mp4',
    duration: Duration(minutes: 1, seconds: 57),
    icon: Icons.inventory_2,
  ),
  LessonVideo(
    number: 4,
    title: 'Escudo contra imprevistos',
    description: 'Monte uma reserva para os sustos que aparecem sem avisar.',
    asset: 'assets/videos/aula4.mp4',
    duration: Duration(minutes: 1, seconds: 55),
    icon: Icons.shield,
  ),
  LessonVideo(
    number: 5,
    title: 'Compras inteligentes',
    description: 'Dicas simples para gastar menos nas compras do dia a dia.',
    asset: 'assets/videos/aula5.mp4',
    duration: Duration(minutes: 1, seconds: 53),
    icon: Icons.shopping_cart,
  ),
  LessonVideo(
    number: 6,
    title: 'Plantando sementinhas',
    description: 'Guarde um pouco todo mês e veja o seu dinheiro crescer.',
    asset: 'assets/videos/aula6.mp4',
    duration: Duration(minutes: 1, seconds: 53),
    icon: Icons.eco,
  ),
];
