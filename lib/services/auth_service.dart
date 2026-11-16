import '../core/formatters.dart';
import 'api_client.dart';

/// Dados da sessão aberta: token JWT, validade e quem entrou.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.name,
  });

  /// Converte o `AuthResponse` da API.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['usuario'] as Map<String, dynamic>;
    return AuthSession(
      token: '${json['token']}',
      // Se a validade não vier (ou vier inválida), assume 2 horas.
      expiresAt: DateTime.tryParse('${json['expiraEm']}') ??
          DateTime.now().toUtc().add(const Duration(hours: 2)),
      userId: (user['id'] as num).toInt(),
      name: '${user['nome']}',
    );
  }

  final String token;
  final DateTime expiresAt;
  final int userId;
  final String name;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());
}

/// Cadastro e login pela API (`/auth/cadastro` e `/auth/login`).
///
/// O token fica só na memória do app: ao fechar o app, a pessoa entra de
/// novo. Depois de sair da conta, a "biometria" (simulada) reaproveita o
/// último token enquanto ele ainda estiver válido (2 horas).
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;

  AuthSession? _session; // quem está logado agora
  AuthSession? _lastSession; // última sessão (habilita a biometria)

  bool get isLoggedIn => _session != null;

  /// A biometria só fica disponível depois do primeiro acesso e enquanto o
  /// último token não vencer.
  bool get canUseBiometrics {
    final last = _lastSession;
    return last != null && !last.isExpired;
  }

  int? get userId => _session?.userId;

  /// Primeiro nome de quem está logado.
  String get userName {
    final name = _session?.name.trim() ?? '';
    if (name.isEmpty) return 'amigo';
    return name.split(' ').first;
  }

  /// Entra com telefone e senha. Devolve uma mensagem de erro, ou `null` se
  /// deu certo.
  Future<String?> login(String phone, String password) async {
    try {
      final data = await _api.post(
        '/auth/login',
        body: {'telefone': phoneDigits(phone), 'senha': password},
      );
      _start(AuthSession.fromJson(data as Map<String, dynamic>));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Cria uma conta nova e já entra nela. Devolve mensagem de erro ou `null`.
  Future<String?> register({
    required String name,
    required String phone,
    required String password,
    double? monthlyIncome,
  }) async {
    try {
      final data = await _api.post(
        '/auth/cadastro',
        body: {
          'nome': name,
          'telefone': phoneDigits(phone),
          'senha': password,
          if (monthlyIncome != null) 'rendaMensal': monthlyIncome,
        },
      );
      _start(AuthSession.fromJson(data as Map<String, dynamic>));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Entrada simulada por biometria (digital ou rosto).
  bool loginWithBiometrics() {
    final last = _lastSession;
    if (last == null || last.isExpired) return false;
    _start(last);
    return true;
  }

  void logout() {
    _session = null;
    _api.token = null;
  }

  void _start(AuthSession session) {
    _session = session;
    _lastSession = session;
    _api.token = session.token;
  }
}
