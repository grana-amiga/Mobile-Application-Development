import 'package:shared_preferences/shared_preferences.dart';

/// Lembra, no aparelho, o saldo de cada dívida na primeira vez que o app a
/// viu. A API só guarda o saldo atual; com esse valor inicial dá para
/// calcular a barra de progresso (quanto já foi pago).
class DebtProgressStore {
  DebtProgressStore._();

  static String _key(int userId, int debtId) => 'debt_initial_${userId}_$debtId';

  /// Devolve o saldo inicial salvo. Na primeira vez salva [currentBalance].
  /// Se o armazenamento falhar, usa o saldo atual (a barra fica em 0%).
  static Future<double> initialBalance({
    required int userId,
    required int debtId,
    required double currentBalance,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(userId, debtId);
      final saved = prefs.getDouble(key);
      if (saved != null) return saved;
      await prefs.setDouble(key, currentBalance);
      return currentBalance;
    } catch (_) {
      return currentBalance;
    }
  }

  /// Esquece o saldo de uma dívida excluída.
  static Future<void> forget({required int userId, required int debtId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId, debtId));
    } catch (_) {
      // Sem problema: é só um dado auxiliar.
    }
  }
}
