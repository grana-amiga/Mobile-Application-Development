import '../models/transaction.dart';

/// Resultado da leitura de uma frase do chat, por exemplo "gastei 30 no mercado".
class ParsedEntry {
  const ParsedEntry({
    required this.type,
    required this.amount,
    required this.category,
  });

  final TransactionType type;
  final double amount;
  final TxCategory category;
}

/// Entende frases curtas e simples em português e transforma em um registro.
///
/// É uma versão de demonstração feita só com palavras-chave (sem IA). O
/// chatbot real do WhatsApp é visão de produto; aqui mostramos a ideia.
class ChatParser {
  ChatParser._();

  // Palavras que indicam dinheiro entrando.
  static const List<String> _incomeWords = [
    'recebi', 'ganhei', 'entrou', 'salario', 'pagamento', 'bico', 'vendi',
  ];

  // Palavras que indicam cada categoria de gasto. As chaves são os nomes das
  // categorias da API (catálogo `GET /categorias`).
  static const Map<String, List<String>> _expenseKeywords = {
    'Mercado': ['mercado', 'supermercado', 'feira', 'compras'],
    'Transporte': ['onibus', 'transporte', 'passagem', 'uber', 'gasolina', 'metro'],
    'Energia': ['luz', 'energia'],
    'Moradia': ['aluguel', 'casa', 'gas', 'condominio', 'agua'],
    'Alimentação': ['comida', 'almoco', 'lanche', 'padaria', 'pizza', 'jantar', 'cafe'],
    'Saúde': ['remedio', 'farmacia', 'medico', 'consulta'],
    'Lazer': ['lazer', 'cinema', 'passeio', 'festa', 'jogo'],
  };

  static const Map<String, List<String>> _incomeKeywords = {
    'Salário': ['salario', 'pagamento'],
  };

  // Categorias usadas quando nenhuma palavra-chave é encontrada.
  static const String _defaultExpense = 'Outros gastos';
  static const String _defaultIncome = 'Outras entradas';

  // Números escritos por extenso (só os mais comuns).
  static const Map<String, double> _numberWords = {
    'dois': 2, 'tres': 3, 'quatro': 4, 'cinco': 5, 'seis': 6,
    'sete': 7, 'oito': 8, 'nove': 9, 'dez': 10, 'vinte': 20, 'trinta': 30,
    'quarenta': 40, 'cinquenta': 50, 'sessenta': 60, 'setenta': 70,
    'oitenta': 80, 'noventa': 90, 'cem': 100, 'duzentos': 200,
    'trezentos': 300, 'quinhentos': 500, 'mil': 1000,
  };

  /// Tira acentos e deixa tudo em minúsculas para comparar palavras.
  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  /// Procura um valor em reais na frase. Aceita "30", "1.200,50" e "dez".
  static double? extractAmount(String text) {
    final normalized = normalize(text);

    // 1) Números em dígitos, com milhar (.) e centavos (,) opcionais.
    final match =
        RegExp(r'(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?').firstMatch(normalized);
    if (match != null) {
      final whole = (match.group(1) ?? '').replaceAll('.', '');
      final cents = match.group(2);
      final value = double.tryParse(cents == null ? whole : '$whole.$cents');
      if (value != null && value > 0) return value;
    }

    // 2) Números por extenso. Soma as palavras vistas ("vinte e cinco" = 25).
    double total = 0;
    var found = false;
    for (final word in normalized.split(RegExp(r'[^a-z]+'))) {
      final value = _numberWords[word];
      if (value == null) continue;
      found = true;
      // "dois mil" multiplica; os demais somam.
      if (value == 1000 && total > 0 && total < 1000) {
        total *= 1000;
      } else if (value == 1000) {
        total += 1000;
      } else {
        total += value;
      }
    }
    return found && total > 0 ? total : null;
  }

  /// Lê a frase inteira. Devolve `null` se não achar nenhum valor ou se a
  /// lista de [categories] (vinda da API) não tiver categoria do tipo.
  static ParsedEntry? parse(String text, List<TxCategory> categories) {
    final amount = extractAmount(text);
    if (amount == null) return null;

    final normalized = normalize(text);
    final words = normalized.split(RegExp(r'[^a-z]+'));
    final isIncome = _incomeWords.any(words.contains);
    final type = isIncome ? TransactionType.income : TransactionType.expense;

    final keywords = isIncome ? _incomeKeywords : _expenseKeywords;
    var label = isIncome ? _defaultIncome : _defaultExpense;
    for (final entry in keywords.entries) {
      if (entry.value.any(words.contains)) {
        label = entry.key;
        break;
      }
    }

    final category = _findCategory(categories, label, type);
    if (category == null) return null;
    return ParsedEntry(type: type, amount: amount, category: category);
  }

  // Procura a categoria pelo nome (sem acento e sem diferenciar maiúsculas).
  // Se não achar, usa a primeira categoria do mesmo tipo.
  static TxCategory? _findCategory(
    List<TxCategory> categories,
    String label,
    TransactionType type,
  ) {
    final sameType = categoriesOf(categories, type);
    for (final category in sameType) {
      if (normalize(category.label) == normalize(label)) return category;
    }
    return sameType.isEmpty ? null : sameType.first;
  }
}
