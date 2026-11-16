import 'api_client.dart';

/// Resultado do simulador de poupança.
class SavingsResult {
  const SavingsResult({
    required this.totalContributed,
    required this.finalBalance,
    required this.earnings,
  });

  final double totalContributed;
  final double finalBalance;
  final double earnings;
}

/// Resultado do simulador de juros compostos.
class InterestResult {
  const InterestResult({required this.amount, required this.totalInterest});

  final double amount;
  final double totalInterest;
}

/// Simuladores públicos da API (não precisam de login).
class EducationService {
  EducationService._();

  static final EducationService instance = EducationService._();

  final ApiClient _api = ApiClient.instance;

  /// `POST /educacao/simuladores/poupanca`: guardar um valor todo mês.
  Future<SavingsResult> savings({
    required double monthlyDeposit,
    required double monthlyRate,
    required int months,
  }) async {
    final data = await _api.post(
      '/educacao/simuladores/poupanca',
      body: {
        'aporteMensal': monthlyDeposit,
        'taxaMensal': monthlyRate,
        'meses': months,
      },
    ) as Map<String, dynamic>;
    return SavingsResult(
      totalContributed: asDouble(data['totalAportado']),
      finalBalance: asDouble(data['saldoFinal']),
      earnings: asDouble(data['rendimento']),
    );
  }

  /// `POST /educacao/simuladores/juros`: quanto uma dívida cresce com juros.
  Future<InterestResult> compoundInterest({
    required double initialValue,
    required double monthlyRate,
    required int months,
  }) async {
    final data = await _api.post(
      '/educacao/simuladores/juros',
      body: {
        'valorInicial': initialValue,
        'taxaMensal': monthlyRate,
        'meses': months,
      },
    ) as Map<String, dynamic>;
    return InterestResult(
      amount: asDouble(data['montante']),
      totalInterest: asDouble(data['jurosTotais']),
    );
  }
}
