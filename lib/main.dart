import 'package:flutter/material.dart';

// Ponto de entrada do aplicativo. Por enquanto mostra apenas uma tela vazia;
// as telas reais serão adicionadas nos próximos commits.
void main() {
  runApp(const GranaAmigaApp());
}

class GranaAmigaApp extends StatelessWidget {
  const GranaAmigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Grana Amiga',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Grana Amiga')),
      ),
    );
  }
}
