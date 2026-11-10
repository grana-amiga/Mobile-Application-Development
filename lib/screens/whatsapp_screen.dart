import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/transaction.dart';
import '../services/chat_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

/// Parâmetros enviados para a tela do chat pela rota.
class WhatsAppArgs {
  const WhatsAppArgs({required this.onConfirm});

  /// Chamado quando a pessoa confirma um registro feito pelo chat.
  /// O painel usa isso para atualizar o saldo (setState lá no pai).
  final ValueChanged<Transaction> onConfirm;
}

/// Uma mensagem do chat.
class _Message {
  _Message({required this.text, required this.fromBot, this.entry});

  final String text;
  final bool fromBot;

  /// Registro proposto pelo robô, esperando confirmação.
  final ParsedEntry? entry;
  bool confirmed = false;
}

/// Conversa simulada com o "Amiguinho" no WhatsApp.
///
/// O chatbot real é visão de produto: aqui um leitor de palavras-chave
/// entende frases como "gastei 30 no mercado" e propõe o registro.
class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key, required this.args});

  final WhatsAppArgs args;

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Message> _messages = [
    _Message(
      fromBot: true,
      text: 'Oi! Eu sou o Amiguinho da Grana Amiga. 👋\n'
          'Me conte o que você gastou ou recebeu, por exemplo: '
          '"gastei 30 no mercado".',
    ),
  ];

  static const List<String> _suggestions = [
    'Gastei 30 no mercado',
    'Recebi 200 de um bico',
    'Paguei 62 de água',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Rola a lista até a última mensagem (depois de o frame ser desenhado).
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // Envia a frase: mostra a mensagem da pessoa e depois a resposta do robô.
  Future<void> _send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      showAppSnackBar(context, 'Escreva uma mensagem antes de enviar.', isError: true);
      return;
    }
    setState(() => _messages.add(_Message(fromBot: false, text: clean)));
    _controller.clear();
    _scrollToEnd();

    // Pequena pausa para parecer uma conversa de verdade.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final entry = ChatParser.parse(clean);
    setState(() {
      if (entry == null) {
        _messages.add(_Message(
          fromBot: true,
          text: 'Não consegui achar o valor. 😕 Tente assim: '
              '"gastei 30 no mercado" ou "recebi 200".',
        ));
      } else {
        final verb = entry.type == TransactionType.income ? 'entrada' : 'saída';
        _messages.add(_Message(
          fromBot: true,
          entry: entry,
          text: 'Entendi! Uma $verb de ${formatBRL(entry.amount)} '
              'em ${entry.category.label}. Posso registrar?',
        ));
      }
    });
    _scrollToEnd();
  }

  // Simula o envio de um áudio: no produto real o áudio seria transcrito.
  void _sendFakeAudio() {
    _send('Gastei vinte reais no mercado');
  }

  void _confirm(_Message message) {
    final entry = message.entry;
    if (entry == null || message.confirmed) return;
    widget.args.onConfirm(
      Transaction(
        type: entry.type,
        category: entry.category,
        amount: entry.amount,
        date: DateTime.now(),
        note: 'Pelo WhatsApp',
      ),
    );
    setState(() {
      message.confirmed = true;
      _messages.add(_Message(
        fromBot: true,
        text: 'Pronto, registrado! ✅ Seu saldo já foi atualizado.',
      ));
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'Amiguinho no WhatsApp'),
      body: SafeArea(
        child: Column(
          children: [
            // Aviso: deixa claro que esta conversa é uma simulação.
            Container(
              width: double.infinity,
              color: AppColors.yellowSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.petrol, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Conversa de demonstração. O chatbot de verdade no WhatsApp é a visão do produto.',
                      style: AppText.small,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _Bubble(
                    message: message,
                    onConfirm: () => _confirm(message),
                  );
                },
              ),
            ),
            // Sugestões rápidas para quem não gosta de digitar.
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final text = _suggestions[index];
                  return ActionChip(
                    label: Text(text),
                    labelStyle: const TextStyle(
                      color: AppColors.petrol,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    backgroundColor: AppColors.mintSoft,
                    onPressed: () => _send(text),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      style: AppText.body,
                      decoration: appInputDecoration(label: 'Mensagem', hint: 'Escreva aqui...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Enviar áudio de exemplo',
                    onPressed: _sendFakeAudio,
                    icon: const Icon(Icons.mic),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      foregroundColor: AppColors.petrol,
                      backgroundColor: AppColors.peach,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Enviar',
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.petrol,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Balão de mensagem: do robô à esquerda, da pessoa à direita.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onConfirm});

  final _Message message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bot = message.fromBot;

    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bot ? AppColors.card : AppColors.mintSoft,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(bot ? 4 : 20),
            bottomRight: Radius.circular(bot ? 20 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: AppText.body),
            if (message.entry != null) ...[
              const SizedBox(height: 10),
              if (message.confirmed)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.green, size: 22),
                    SizedBox(width: 6),
                    Text('Registrado', style: AppText.h3),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.petrol,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
