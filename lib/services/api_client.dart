import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro de uma chamada à API, já com uma mensagem pronta para mostrar.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fields = const {},
    this.isNetwork = false,
  });

  /// Texto amigável para a pessoa (vai direto para SnackBar/aviso).
  final String message;

  /// Código HTTP (400, 401, 404...). Nulo quando nem chegou a falar com o servidor.
  final int? statusCode;

  /// Erros por campo devolvidos pela validação da API (campo -> mensagem).
  final Map<String, String> fields;

  /// Verdadeiro quando faltou internet ou o servidor não respondeu.
  final bool isNetwork;

  @override
  String toString() => message;
}

/// Cliente HTTP único do app para a API Java (Spring Boot).
///
/// Responsabilidades:
/// - montar a URL e os cabeçalhos (JSON e `Authorization: Bearer <token>`);
/// - converter erros da API e falhas de rede em [ApiException];
/// - avisar o app quando o token expira (HTTP 401 com sessão aberta).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Endereço da API. Para usar outro servidor (por exemplo, local), rode:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://grana-amiga-api.onrender.com/api/v1',
  );

  // O Render (plano gratuito) "dorme" quando fica parado e a primeira
  // chamada pode levar mais de 30 segundos para acordar o servidor.
  static const Duration _timeout = Duration(seconds: 70);

  final http.Client _client = http.Client();

  /// Token JWT da sessão atual (nulo = ninguém logado).
  String? token;

  /// Chamado quando a API recusa o token (expirado ou inválido).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  // Faz a chamada e devolve o JSON já convertido (Map, List ou null).
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    // Só enviamos os cabeçalhos que a API aceita no CORS (Web).
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    final currentToken = token;
    if (currentToken != null) headers['Authorization'] = 'Bearer $currentToken';

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou para responder. Tente de novo em instantes.',
        isNetwork: true,
      );
    } catch (_) {
      throw ApiException(
        'Sem conexão com o servidor. Confira a internet e tente de novo.',
        isNetwork: true,
      );
    }

    final data = _decode(response);
    final status = response.statusCode;
    if (status >= 200 && status < 300) return data;

    // 401 com token = sessão vencida (o token dura 2 horas).
    if (status == 401 && currentToken != null) {
      onSessionExpired?.call();
      throw ApiException(
        'Sua sessão expirou. Entre de novo para continuar.',
        statusCode: status,
      );
    }
    throw _toException(status, data);
  }

  // Converte o corpo da resposta em JSON (ou null se estiver vazio/inválido).
  dynamic _decode(http.Response response) {
    try {
      final text = utf8.decode(response.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  // Monta a mensagem de erro a partir do formato `ApiError` da API:
  // { status, erro, mensagem, campos: { campo: mensagem } }.
  ApiException _toException(int status, dynamic data) {
    String? message;
    final fields = <String, String>{};
    if (data is Map) {
      final apiMessage = data['mensagem'];
      if (apiMessage is String && apiMessage.isNotEmpty) message = apiMessage;
      final apiFields = data['campos'];
      if (apiFields is Map) {
        apiFields.forEach((key, value) => fields['$key'] = '$value');
      }
    }

    if (fields.isNotEmpty) {
      final details = fields.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      message = '${message ?? 'Dados inválidos'}\n$details';
    }

    message ??= switch (status) {
      403 => 'Você não tem permissão para fazer isso.',
      404 => 'Não encontramos o que você procurou.',
      502 || 503 || 504 =>
        'O servidor está acordando. Aguarde um minuto e tente de novo.',
      >= 500 => 'O servidor está com problemas. Tente de novo mais tarde.',
      _ => 'Algo deu errado. Tente de novo.',
    };
    return ApiException(message, statusCode: status, fields: fields);
  }
}

/// Lê um número do JSON (a API manda BigDecimal como número ou texto).
double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0.0;
}

/// Lê uma data/hora do JSON (ex.: "2026-11-14T08:30:00").
DateTime asDate(dynamic value) {
  return DateTime.tryParse('$value') ?? DateTime.now();
}
