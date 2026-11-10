/// Nomes das rotas (telas) do aplicativo.
///
/// Usar constantes evita erros de digitação nos nomes e deixa o mapa de
/// navegação fácil de ler:
///
///   Início ──► Jogos ──► Jogo
///     │
///     └──► Login ──► Área da família (Painel · Dívidas · Energia · Aprender)
///                        ├──► Adicionar gasto/entrada
///                        └──► Conversa do WhatsApp
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String games = '/games';
  static const String game = '/game';
  static const String login = '/login';
  static const String main = '/main';
  static const String addTransaction = '/add-transaction';
  static const String whatsapp = '/whatsapp';
}
