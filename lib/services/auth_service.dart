import '../core/formatters.dart';

/// Autenticação de exemplo (em memória).
///
/// Ainda não existe servidor: as contas ficam guardadas só enquanto o app
/// está aberto. Serve para demonstrar o fluxo de cadastro e login, com
/// validações e mensagens de erro. Em um app real, esta classe falaria com
/// uma API segura e a senha nunca seria guardada em texto puro.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Conta de exemplo para a demonstração.
  static const String demoPhone = '(11) 98888-1234';
  static const String demoPassword = '123456';

  // Chave = só os números do telefone.
  final Map<String, _Account> _accounts = {
    '11988881234': _Account(name: 'Maria', password: demoPassword),
  };

  String? _currentPhone; // quem está logado agora
  String? _lastPhone; // quem entrou por último (habilita a biometria)

  bool get isLoggedIn => _currentPhone != null;

  /// A biometria só fica disponível depois do primeiro acesso.
  bool get canUseBiometrics => _lastPhone != null;

  /// Primeiro nome de quem está logado.
  String get userName {
    final account = _accounts[_currentPhone];
    return account == null ? 'amigo' : account.name;
  }

  /// Entra com telefone e senha. Devolve uma mensagem de erro, ou `null` se
  /// deu certo.
  String? login(String phone, String password) {
    final key = phoneDigits(phone);
    final account = _accounts[key];
    if (account == null) {
      return 'Não encontramos esse telefone. Toque em "Criar conta" para começar.';
    }
    if (account.password != password) {
      return 'Senha incorreta. Confira e tente de novo.';
    }
    _currentPhone = key;
    _lastPhone = key;
    return null;
  }

  /// Cria uma conta nova e já entra nela. Devolve mensagem de erro ou `null`.
  String? register({
    required String name,
    required String phone,
    required String password,
  }) {
    final key = phoneDigits(phone);
    if (_accounts.containsKey(key)) {
      return 'Esse telefone já tem conta. Toque em "Entrar".';
    }
    _accounts[key] = _Account(name: name, password: password);
    _currentPhone = key;
    _lastPhone = key;
    return null;
  }

  /// Entrada simulada por biometria (digital ou rosto).
  bool loginWithBiometrics() {
    final last = _lastPhone;
    if (last == null) return false;
    _currentPhone = last;
    return true;
  }

  void logout() {
    _currentPhone = null;
  }
}

class _Account {
  const _Account({required this.name, required this.password});

  final String name;
  final String password;
}
