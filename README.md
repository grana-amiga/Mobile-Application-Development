# Grana Amiga

App de educação e organização financeira para famílias de baixa renda para ensinar como organizar suas finanças de forma didática, feito em Flutter como projeto CitizenTech.

## Vídeo pitch

[Assista ao vídeo pitch no YouTube](https://youtu.be/wXHXHOTMFTw)

## Descrição

O Grana Amiga ajuda pessoas com baixa escolaridade que sustentam a casa a entender e controlar o dinheiro da família, sem jargão e sem planilhas. Segundo a CNC (PEIC de julho de 2026), 82% das famílias brasileiras estão endividadas e, entre elas, 85% têm dívida no cartão de crédito. O projeto é sem fins lucrativos, pensado para receber investimento público. O app tem:

- **Início aberto**: boas-vindas com áudio, botão de acessibilidade (tamanho da letra), carrossel de jogos e de vídeos educativos, e simuladores, tudo acessível antes de criar conta.
- **Jogos de educação financeira** (5): Preciso ou Quero, Mercado com Orçamento, Parcelas e Juros, Cofrinho de Metas e Mito ou Verdade. A pontuação muda a cada resposta.
- **Vídeos educativos** (6): vídeos curtos incluídos no app, na aba Aprender e na tela inicial.
- **Simuladores**: poupança (quanto juntar por mês) e juros de dívida, calculados pela API.
- **Login e cadastro** reais pela API (JWT), com formulário validado e biometria simulada.
- **Painel principal**: Termômetro do Dinheiro (verde, amarelo, vermelho com ícone e texto), saldo grande com leitura em voz alta, feed de gastos com ícones e botões fixos de Entrada, Saída e WhatsApp.
- **Adicionar gasto/entrada**: grade de categorias com ícones (vindas da API), teclado numérico grande e confirmação por SnackBar.
- **Dívidas**: cadastro, plano de quitação ordenado por juros, barra de progresso, próximo vencimento e pagamento de parcela.
- **Alertas e energia**: contas a vencer e custo de luz do mês, com leituras do medidor (simuladas, como o ESP32 enviaria).
- **Chat do WhatsApp (simulado)**: frases como "gastei 30 no mercado" viram registros. O chatbot real é visão de produto.

## Cidadão beneficiado

Famílias de baixa renda, principalmente quem sustenta a casa e tem baixa escolaridade (muitas vezes mulheres que lideram o lar sozinhas), que hoje controlam o dinheiro de cabeça ou no caderno e acabam endividadas por falta de informação. O app usa ícones, áudio, letras grandes e cores com contraste para ser compreendido por quem lê com dificuldade.

## ODS relacionados

- **ODS 1 – Erradicação da pobreza**: ferramentas para a família organizar a renda.
- **ODS 4 – Educação de qualidade**: educação financeira em formato de jogo.
- **ODS 10 – Redução das desigualdades**: acesso gratuito e acessível à informação financeira.

As ODS (Objetivos de Desenvolvimento Sustentável) são a agenda da ONU com metas para tornar o mundo mais justo até 2030.

## Uso de IA generativa

A IA generativa (Claude) foi usada como apoio: ideias de nome e paleta, a criação dos jogos, dos testes e dos comentários do código e a integração com a API Java. As decisões de escopo, o fluxo de telas, a API e a revisão final foram feitos pelo grupo, que validou tudo localmente além de complentar e revisar tudo o que foi escrito pela IA.

## Participantes

- Cassio Alexandre Ribeiro de Moraes (RM 567295)
- Davi Isac Colin Pereira (RM 567265)
- Hugo Souza de Jesus (RM 568542)
- Matheus Peres Moraes de Jesus (RM 567300)
- Pedro Gonçalves Rodrigues (RM 567651)

## Como rodar

```bash
# 1. Gerar as pastas de plataforma (android, ios, web), uma única vez
flutter create --platforms=android,ios,web --org br.com.fiap --project-name grana_amiga .

# 2. Dependências, análise e testes
flutter pub get
flutter analyze
flutter test

# 3. Executar
flutter run -d chrome   # ou um emulador/dispositivo
```

Para a leitura em voz alta funcionar no Android 11+, adicione ao `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.TTS_SERVICE"/>
  </intent>
</queries>
```

Para o app falar com a API em builds Android de produção, adicione também, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Depois de adicionar plugins novos (`shared_preferences`, `http`), rode `flutter pub get` e reinicie o app por completo (e `pod install` no iOS).

## Integração com a API Java

O app consome a API Spring Boot (repositório [Java-Advanced](https://github.com/grana-amiga/Java-Advanced)), publicada em `https://grana-amiga-api.onrender.com` (Swagger em `/swagger-ui/index.html`).

- Login e cadastro reais (JWT); não há mais conta de demonstração. A senha do cadastro precisa ter no mínimo 8 caracteres.
- Categorias, movimentações, resumo do mês, dívidas, plano de quitação, termômetro, alertas, energia e simuladores vêm da API.
- A URL pode ser trocada: `flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1`.
- O servidor gratuito do Render "dorme": a primeira chamada pode levar até ~1 minuto.
- No Flutter Web, a origem usada (ex.: `flutter run -d chrome --web-port=3000`) precisa estar em `APP_CORS_ORIGINS` na API.
- O token fica só na memória: ao fechar o app, é preciso entrar de novo.
