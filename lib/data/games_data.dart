import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_theme.dart';

/// Conteúdo educativo dos 5 jogos do Grana Amiga.
///
/// Os textos usam linguagem simples e exemplos do dia a dia. Em toda resposta
/// o jogo explica o porquê, para a pessoa aprender sem se sentir julgada.

const Color _blueSoft = Color(0xFFCDE5EA);

// ---------------------------------------------------------------------------
// Jogo 1: Preciso ou Quero?
// ---------------------------------------------------------------------------
const List<QuizRound> _needOrWantRounds = [
  QuizRound(
    title: 'Arroz e feijão para a semana',
    icon: Icons.shopping_cart,
    options: ['Preciso', 'Quero'],
    correctIndex: 0,
    explanation:
        'Comida do dia a dia é uma necessidade. Esse gasto vem primeiro.',
  ),
  QuizRound(
    title: 'Tênis de marca novo (o seu ainda está bom)',
    icon: Icons.directions_walk,
    options: ['Preciso', 'Quero'],
    correctIndex: 1,
    explanation:
        'Se o tênis atual ainda serve, trocar é um desejo. Dá para esperar sobrar dinheiro.',
  ),
  QuizRound(
    title: 'Conta de luz do mês',
    icon: Icons.bolt,
    options: ['Preciso', 'Quero'],
    correctIndex: 0,
    explanation: 'Luz é uma conta essencial. Atrasar gera multa e juros.',
  ),
  QuizRound(
    title: 'Pacote extra de canais de TV',
    icon: Icons.tv,
    options: ['Preciso', 'Quero'],
    correctIndex: 1,
    explanation:
        'Não é essencial. Com o orçamento apertado, esse é um bom gasto para cortar.',
  ),
  QuizRound(
    title: 'Remédio receitado pelo médico',
    icon: Icons.medication,
    options: ['Preciso', 'Quero'],
    correctIndex: 0,
    explanation: 'Saúde é prioridade. Esse gasto não deve ser adiado.',
  ),
  QuizRound(
    title: 'Celular novo (o seu funciona bem)',
    icon: Icons.smartphone,
    options: ['Preciso', 'Quero'],
    correctIndex: 1,
    explanation:
        'Se o aparelho funciona, trocar é um desejo. Guardar um pouco por mês ajuda a comprar sem dívida.',
  ),
  QuizRound(
    title: 'Passagem de ônibus para ir ao trabalho',
    icon: Icons.directions_bus,
    options: ['Preciso', 'Quero'],
    correctIndex: 0,
    explanation:
        'Chegar ao trabalho garante a renda da família. É uma necessidade.',
  ),
  QuizRound(
    title: 'Salgadinho e refrigerante todo dia na saída',
    icon: Icons.fastfood,
    options: ['Preciso', 'Quero'],
    correctIndex: 1,
    explanation:
        'Pequenos gastos somam. R\$ 5 por dia viram R\$ 150 por mês.',
  ),
];

// ---------------------------------------------------------------------------
// Jogo 3: Parcelar ou esperar?
// ---------------------------------------------------------------------------
const List<QuizRound> _installmentRounds = [
  QuizRound(
    title: 'TV de R\$ 1.000 à vista. No carnê: 10 parcelas de R\$ 130.',
    detail: 'Qual sai mais barato?',
    icon: Icons.tv,
    options: ['À vista: R\$ 1.000', 'No carnê: 10x de R\$ 130 = R\$ 1.300'],
    correctIndex: 0,
    explanation:
        'No carnê você paga R\$ 300 a mais. Esse extra é o juros: o preço de pedir dinheiro emprestado.',
  ),
  QuizRound(
    title:
        'Fogão de R\$ 600. Você pode juntar R\$ 50 por mês durante 12 meses, ou comprar já em 12 parcelas de R\$ 70.',
    detail: 'Qual custa menos?',
    icon: Icons.kitchen,
    options: [
      'Juntar R\$ 50 por mês e pagar à vista (R\$ 600)',
      'Comprar já em 12x de R\$ 70 (R\$ 840)',
    ],
    correctIndex: 0,
    explanation:
        'Esperar custa R\$ 240 a menos. Se o fogão quebrou e você precisa agora, procure a menor parcela e o menor juros.',
  ),
  QuizRound(
    title: 'Chegou a fatura do cartão: R\$ 800. O pagamento mínimo é R\$ 160.',
    detail: 'O que é melhor fazer?',
    icon: Icons.credit_card,
    options: ['Pagar tudo: R\$ 800', 'Pagar só o mínimo: R\$ 160'],
    correctIndex: 0,
    explanation:
        'O que sobra vai para o rotativo, um dos juros mais altos que existem. Sempre que der, pague o valor total.',
  ),
  QuizRound(
    title:
        'Dois empréstimos de R\$ 500 em 5 parcelas. O banco A cobra 5x de R\$ 120. O banco B cobra 5x de R\$ 105.',
    detail: 'Qual é a melhor oferta?',
    icon: Icons.account_balance,
    options: ['Banco A: R\$ 600 no total', 'Banco B: R\$ 525 no total'],
    correctIndex: 1,
    explanation:
        'No banco B você devolve só R\$ 25 a mais. No A são R\$ 100 a mais. Compare o valor total, não só a parcela.',
  ),
  QuizRound(
    title:
        'Geladeira de R\$ 900. À vista tem 10% de desconto. Ou 3 parcelas de R\$ 300, sem desconto.',
    detail: 'Qual compensa mais?',
    icon: Icons.kitchen,
    options: ['À vista com desconto: R\$ 810', '3x de R\$ 300: R\$ 900'],
    correctIndex: 0,
    explanation:
        'O desconto de R\$ 90 fica no seu bolso. Só compre à vista se o dinheiro já estiver guardado.',
  ),
  QuizRound(
    title:
        'Você tem R\$ 300 guardados e uma dívida de cartão com juros de mais de 10% ao mês.',
    detail: 'O que fazer com o dinheiro?',
    icon: Icons.savings,
    options: [
      'Pagar a dívida do cartão',
      'Deixar parado na poupança',
    ],
    correctIndex: 0,
    explanation:
        'A dívida cresce muito mais rápido do que a poupança rende. Pague o cartão, mas deixe uma pequena reserva para imprevistos.',
  ),
];

// ---------------------------------------------------------------------------
// Jogo 5: Mito ou Verdade?
// ---------------------------------------------------------------------------
const List<QuizRound> _mythOrTruthRounds = [
  QuizRound(
    title: 'Pagar só o mínimo da fatura do cartão resolve a dívida.',
    icon: Icons.credit_card,
    options: ['Mito', 'Verdade'],
    correctIndex: 0,
    explanation:
        'Mito. O que não foi pago vira dívida com juros muito altos e continua crescendo.',
  ),
  QuizRound(
    title:
        'Guardar um pouquinho todo mês ajuda mais do que guardar muito de vez em quando.',
    icon: Icons.savings,
    options: ['Mito', 'Verdade'],
    correctIndex: 1,
    explanation:
        'Verdade. O hábito de guardar todo mês é mais forte do que uma grande economia isolada.',
  ),
  QuizRound(
    title: 'Quem ganha pouco não consegue guardar nada.',
    icon: Icons.attach_money,
    options: ['Mito', 'Verdade'],
    correctIndex: 0,
    explanation:
        'Mito. Valores pequenos somam: R\$ 10 por semana viram mais de R\$ 500 em um ano.',
  ),
  QuizRound(
    title: 'Anotar os gastos ajuda a descobrir para onde o dinheiro está indo.',
    icon: Icons.edit,
    options: ['Mito', 'Verdade'],
    correctIndex: 1,
    explanation:
        'Verdade. Quando a gente enxerga os gastos, fica mais fácil cortar o que pesa.',
  ),
  QuizRound(
    title:
        'Emprestar o seu nome (CPF) para um conhecido comprar parcelado é seguro.',
    icon: Icons.warning_amber,
    options: ['Mito', 'Verdade'],
    correctIndex: 0,
    explanation:
        'Mito. Se a pessoa não pagar, a dívida fica no seu nome e você é cobrado.',
  ),
  QuizRound(
    title: 'Dívida antiga some sozinha se eu não pagar.',
    icon: Icons.hourglass_bottom,
    options: ['Mito', 'Verdade'],
    correctIndex: 0,
    explanation:
        'Mito. Ela continua sendo cobrada e pode crescer. O melhor caminho é procurar renegociar.',
  ),
  QuizRound(
    title: 'Comparar preços antes de comprar pode economizar bastante no mês.',
    icon: Icons.search,
    options: ['Mito', 'Verdade'],
    correctIndex: 1,
    explanation:
        'Verdade. O mesmo produto pode ter preços bem diferentes de uma loja para outra.',
  ),
  QuizRound(
    title:
        'Uma reserva de emergência serve para imprevistos, como um remédio ou um conserto.',
    icon: Icons.health_and_safety,
    options: ['Mito', 'Verdade'],
    correctIndex: 1,
    explanation:
        'Verdade. Com uma reserva, um imprevisto não vira dívida no cartão.',
  ),
];

// ---------------------------------------------------------------------------
// Jogo 2: Mercado sem aperto
// ---------------------------------------------------------------------------

/// Dinheiro disponível para as compras.
const int cartBudget = 60;

/// Soma dos preços de todos os itens essenciais (R$ 55): dá para comprar todos
/// e ainda sobram R$ 5.
const List<CartItem> cartItems = [
  CartItem(
    name: 'Arroz e feijão',
    price: 18,
    icon: Icons.shopping_basket,
    essential: true,
  ),
  CartItem(
    name: 'Ovos',
    price: 12,
    icon: Icons.free_breakfast,
    essential: true,
  ),
  CartItem(name: 'Frutas', price: 10, icon: Icons.eco, essential: true),
  CartItem(name: 'Leite', price: 6, icon: Icons.local_drink, essential: true),
  CartItem(
    name: 'Sabão em pó',
    price: 9,
    icon: Icons.local_laundry_service,
    essential: true,
  ),
  CartItem(
    name: 'Refrigerante',
    price: 9,
    icon: Icons.local_bar,
    essential: false,
  ),
  CartItem(
    name: 'Biscoito recheado',
    price: 6,
    icon: Icons.cake,
    essential: false,
  ),
  CartItem(
    name: 'Salgadinho',
    price: 7,
    icon: Icons.fastfood,
    essential: false,
  ),
];

// ---------------------------------------------------------------------------
// Jogo 4: Cofrinho que cresce
// ---------------------------------------------------------------------------
const List<SavingsGoal> savingsGoals = [
  SavingsGoal(
    title: 'Celular novo',
    icon: Icons.smartphone,
    goal: 900,
    months: 10,
    maxDeposit: 150,
  ),
  SavingsGoal(
    title: 'Reserva para imprevistos',
    icon: Icons.health_and_safety,
    goal: 1200,
    months: 12,
    maxDeposit: 200,
  ),
  SavingsGoal(
    title: 'Material escolar',
    icon: Icons.school,
    goal: 400,
    months: 8,
    maxDeposit: 100,
  ),
];

// ---------------------------------------------------------------------------
// Lista de jogos mostrada no catálogo e no carrossel da tela inicial.
// ---------------------------------------------------------------------------
const List<GameInfo> allGames = [
  GameInfo(
    id: 'need_want',
    title: 'Preciso ou Quero?',
    subtitle: 'Separe o que é necessidade do que é desejo.',
    icon: Icons.compare_arrows,
    color: AppColors.peachSoft,
    level: 'Bem fácil',
    minutes: 3,
    kind: GameKind.quiz,
    intro:
        'Vou mostrar um gasto. Diga se é algo que você precisa ou algo que você quer.',
    maxScore: 80,
    rounds: _needOrWantRounds,
  ),
  GameInfo(
    id: 'market',
    title: 'Mercado sem aperto',
    subtitle: 'Faça as compras sem passar de 60 reais.',
    icon: Icons.shopping_cart,
    color: AppColors.mintSoft,
    level: 'Fácil',
    minutes: 4,
    kind: GameKind.cart,
    intro:
        'Você tem 60 reais para as compras. Toque nos itens que quer levar e não passe do valor. O que é essencial vale mais pontos.',
    maxScore: 55,
  ),
  GameInfo(
    id: 'installments',
    title: 'Parcelar ou esperar?',
    subtitle: 'Descubra quanto os juros custam de verdade.',
    icon: Icons.credit_card,
    color: AppColors.yellowSoft,
    level: 'Fácil',
    minutes: 4,
    kind: GameKind.quiz,
    intro:
        'Em cada situação, escolha a opção que sai mais barata. Juros são o preço de pedir dinheiro emprestado.',
    maxScore: 60,
    rounds: _installmentRounds,
  ),
  GameInfo(
    id: 'piggy_bank',
    title: 'Cofrinho que cresce',
    subtitle: 'Escolha quanto guardar por mês e chegue à meta.',
    icon: Icons.savings,
    color: _blueSoft,
    level: 'Bem fácil',
    minutes: 3,
    kind: GameKind.savings,
    intro:
        'Cada meta tem um prazo. Mexa na barra para escolher quanto guardar por mês e veja se chega lá.',
    maxScore: 60,
  ),
  GameInfo(
    id: 'myth_truth',
    title: 'Mito ou Verdade?',
    subtitle: 'Acabe com as ideias erradas sobre dinheiro.',
    icon: Icons.lightbulb_outline,
    color: AppColors.peachSoft,
    level: 'Bem fácil',
    minutes: 3,
    kind: GameKind.quiz,
    intro:
        'Vou ler uma frase sobre dinheiro. Diga se ela é um mito ou uma verdade.',
    maxScore: 80,
    rounds: _mythOrTruthRounds,
  ),
];
