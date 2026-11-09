import 'package:flutter/services.dart';

/// Funções de formatação usadas em todo o app.
///
/// Não usamos o pacote `intl` de propósito: assim o projeto fica leve e as
/// regras de formatação ficam à vista para estudo.

const List<String> _monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Nome do mês em português (1 = janeiro).
String monthName(int month) => _monthNames[month - 1];

/// Formata um valor em reais: 1234.5 vira "R$ 1.234,50".
///
/// Trabalhamos com centavos inteiros para evitar erros de arredondamento
/// de números decimais (double).
String formatBRL(double value, {bool showSymbol = true}) {
  final negative = value < 0;
  final cents = (value.abs() * 100).round();
  final reais = (cents ~/ 100).toString();
  final decimals = (cents % 100).toString().padLeft(2, '0');

  // Insere o ponto de milhar: percorre os dígitos e, a cada grupo de 3
  // contados do fim, coloca um "." depois do dígito atual.
  final buffer = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    final remaining = reais.length - i;
    buffer.write(reais[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  final sign = negative ? '-' : '';
  final symbol = showSymbol ? 'R\$ ' : '';
  return '$sign$symbol$buffer,$decimals';
}

/// Texto para ser falado em voz alta: 10.5 vira "10 reais e 50 centavos".
String spokenBRL(double value) {
  final cents = (value.abs() * 100).round();
  final reais = cents ~/ 100;
  final centavos = cents % 100;
  final reaisText = reais == 1 ? '1 real' : '$reais reais';
  if (centavos == 0) return reaisText;
  final centavosText = centavos == 1 ? '1 centavo' : '$centavos centavos';
  return '$reaisText e $centavosText';
}

/// Converte o texto digitado ("10,50") em número. Retorna null se inválido.
double? parseAmount(String text) {
  final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// Data curta: "12 nov".
String formatShortDate(DateTime date) {
  return '${date.day} ${monthName(date.month).substring(0, 3)}';
}

/// "Hoje", "Ontem" ou a data curta, comparando só dia/mês/ano.
String relativeDay(DateTime date, DateTime now) {
  final diff = daysBetween(date, now);
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return formatShortDate(date);
}

/// Quantidade de dias entre duas datas (ignora a hora). Positivo se [to]
/// vem depois de [from].
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Texto de prazo: "vence hoje", "vence amanhã", "vence em 5 dias".
String dueText(DateTime due, DateTime now) {
  final days = daysBetween(now, due);
  if (days < 0) return 'venceu há ${-days} dia${days == -1 ? '' : 's'}';
  if (days == 0) return 'vence hoje';
  if (days == 1) return 'vence amanhã';
  return 'vence em $days dias';
}

/// Formatador de entrada do telefone: transforma dígitos em "(11) 98888-1234".
///
/// Um [TextInputFormatter] é chamado a cada tecla digitada e devolve o novo
/// valor do campo. Aqui só aceitamos números e limitamos a 11 dígitos.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Só os números de um telefone formatado: "(11) 98888-1234" -> "11988881234".
String phoneDigits(String text) => text.replaceAll(RegExp(r'\D'), '');
