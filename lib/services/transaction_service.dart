import '../models/money_summary.dart';
import '../models/transaction.dart';
import 'api_client.dart';

/// Chamadas da API de categorias e transações.
class TransactionService {
  TransactionService._();

  static final TransactionService instance = TransactionService._();

  final ApiClient _api = ApiClient.instance;

  /// `GET /categorias`: catálogo público de categorias de entrada e saída.
  Future<List<TxCategory>> categories() async {
    final data = await _api.get('/categorias');
    final list = data is List ? data : const [];
    return list
        .map((item) => TxCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `POST /transacoes`: registra uma entrada ou saída e devolve o registro criado.
  Future<Transaction> create({
    required int categoryId,
    required TransactionType type,
    required double amount,
    String note = '',
  }) async {
    final data = await _api.post(
      '/transacoes',
      body: {
        'categoriaId': categoryId,
        'valor': amount,
        'tipo': type.apiValue,
        if (note.trim().isNotEmpty) 'descricao': note.trim(),
      },
    );
    return Transaction.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /transacoes`: as movimentações mais recentes (mais novas primeiro).
  Future<List<Transaction>> recent({int size = 20}) async {
    final data = await _api.get(
      '/transacoes',
      query: {'pagina': '0', 'tamanho': '$size'},
    );
    final items = (data is Map ? data['itens'] : null) as List? ?? const [];
    return items
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `GET /transacoes/resumo`: total de entradas e saídas de um mês.
  Future<MoneySummary> monthSummary(int year, int month) async {
    final data = await _api.get(
      '/transacoes/resumo',
      query: {'ano': '$year', 'mes': '$month'},
    ) as Map<String, dynamic>;
    return MoneySummary(
      income: asDouble(data['entradas']),
      expenses: asDouble(data['saidas']),
    );
  }
}
