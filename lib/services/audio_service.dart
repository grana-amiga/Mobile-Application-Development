import 'package:flutter_tts/flutter_tts.dart';

/// Leitura de textos em voz alta (audiodescrição) em português do Brasil.
///
/// Usa o pacote `flutter_tts`, que funciona em Android, iOS e Web.
/// É um "singleton": existe uma única instância compartilhada por todo o app.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  /// Fala o [text]. Devolve `false` se o aparelho não conseguir falar, para
  /// que a tela possa avisar a pessoa em vez de falhar em silêncio.
  Future<bool> speak(String text) async {
    try {
      if (!_configured) {
        await _tts.setLanguage('pt-BR');
        await _tts.setSpeechRate(0.45); // mais devagar para facilitar a escuta
        await _tts.setPitch(1.0);
        _configured = true;
      }
      await _tts.stop(); // interrompe qualquer fala anterior
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Para a fala atual (usado ao trocar de tela).
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Sem áudio disponível: nada a fazer.
    }
  }
}
