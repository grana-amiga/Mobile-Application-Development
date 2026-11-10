import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

/// Tela 5: Adicionar gasto (ou entrada).
///
/// Grade de categorias com ícones, teclado numérico grande e botão de câmera
/// (apenas visual nesta versão). Usa `Form` + `GlobalKey<FormState>` para
/// validar os campos e mostra um SnackBar de confirmação ao salvar.
///
/// Ao confirmar, a tela se fecha devolvendo a [Transaction] criada para a
/// tela anterior, que então chama `setState` e atualiza o saldo.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.initialType});

  /// Tipo escolhido no painel: (+) Entrada ou (-) Saída.
  final TransactionType initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // A chave dá acesso ao estado do Form para chamar `validate()`.
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  TxCategory? _category;
  String _amountText = ''; // o que foi digitado no teclado, ex.: "10,50"
  bool _showErrorsWhileTyping = false;

  // Teclas do teclado numérico. "back" é a tecla de apagar.
  static const List<String> _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    ',', '0', 'back',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isExpense => _type == TransactionType.expense;

  List<TxCategory> get _categories =>
      _isExpense ? expenseCategories : incomeCategories;

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      _category = null; // as categorias de gasto e de entrada são diferentes
    });
  }

  // Regras do teclado: no máximo 7 dígitos antes da vírgula, 2 depois, e só
  // uma vírgula. Cada toque atualiza o texto e o campo de valor.
  void _pressKey(String key) {
    var text = _amountText;

    if (key == 'back') {
      if (text.isNotEmpty) text = text.substring(0, text.length - 1);
    } else if (key == ',') {
      if (text.isEmpty) {
        text = '0,';
      } else if (!text.contains(',')) {
        text = '$text,';
      }
    } else {
      final commaIndex = text.indexOf(',');
      if (commaIndex == -1) {
        if (text.length >= 7) return;
        text = text == '0' ? key : '$text$key';
      } else {
        final decimals = text.length - commaIndex - 1;
        if (decimals >= 2) return;
        text = '$text$key';
      }
    }

    setState(() => _amountText = text);
    _amountController.text = text;
  }

  void _onCategoryTap(TxCategory category, FormFieldState<TxCategory> field) {
    setState(() => _category = category);
    field.didChange(category); // avisa o formulário para revalidar
  }

  void _openCamera() {
    showAppSnackBar(
      context,
      'Em breve: ler o comprovante pela câmera. Nesta versão o botão é só visual.',
    );
  }

  // Valida e salva. Se algo estiver errado, mostra o erro em cada campo e em
  // um SnackBar vermelho. Se estiver tudo certo, mostra o SnackBar de
  // confirmação e fecha a tela devolvendo a movimentação criada.
  void _submit() {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      setState(() => _showErrorsWhileTyping = true);
      showAppSnackBar(
        context,
        'Falta alguma coisa. Confira os avisos em vermelho.',
        isError: true,
      );
      return;
    }

    final amount = parseAmount(_amountController.text) ?? 0;
    final category = _category;
    if (category == null) return; // já garantido pela validação

    final transaction = Transaction(
      type: _type,
      category: category,
      amount: amount,
      date: DateTime.now(),
      note: _noteController.text.trim(),
    );

    showAppSnackBar(
      context,
      '${_isExpense ? 'Gasto' : 'Entrada'} de ${formatBRL(amount)} registrado em ${category.label}!',
    );
    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        title: _isExpense ? 'Registrar gasto' : 'Registrar entrada',
        audioText:
            'Escolha a figura, digite o valor no teclado e toque em confirmar.',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _showErrorsWhileTyping
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      icon: Icons.remove_circle,
                      label: 'Gasto',
                      selected: _isExpense,
                      onTap: () => _setType(TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeButton(
                      icon: Icons.add_circle,
                      label: 'Entrada',
                      selected: !_isExpense,
                      onTap: () => _setType(TransactionType.income),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _isExpense ? 'No que o dinheiro foi gasto?' : 'De onde veio o dinheiro?',
                style: AppText.h2,
              ),
              const SizedBox(height: 12),
              _buildCategoryField(),
              const SizedBox(height: 20),
              const Text('Quanto foi?', style: AppText.h2),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                readOnly: true, // o valor é digitado pelo teclado da tela
                showCursor: false,
                textAlign: TextAlign.center,
                style: AppText.h1.copyWith(fontSize: 38),
                decoration: appInputDecoration(
                  label: 'Valor em reais',
                  hint: '0,00',
                  icon: Icons.attach_money,
                ),
                validator: (value) {
                  final amount = parseAmount(value ?? '');
                  if (amount == null) return 'Digite o valor no teclado abaixo.';
                  if (amount <= 0) return 'O valor precisa ser maior que zero.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildKeypad(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                style: AppText.body.copyWith(fontSize: 17),
                decoration: appInputDecoration(
                  label: 'Quer anotar algo? (opcional)',
                  icon: Icons.edit,
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Foto do comprovante',
                icon: Icons.camera_alt,
                kind: AppButtonKind.light,
                showArrow: false,
                onPressed: _openCamera,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: _isExpense ? 'Confirmar gasto' : 'Confirmar entrada',
                icon: Icons.check,
                showArrow: false,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FormField permite criar um campo de formulário com visual próprio (aqui,
  // uma grade de figuras). O validator exige que uma categoria seja escolhida
  // e o `errorText` aparece embaixo da grade.
  Widget _buildCategoryField() {
    return FormField<TxCategory>(
      validator: (_) => _category == null ? 'Toque em uma figura para escolher.' : null,
      builder: (field) {
        final errorText = field.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GridView.count: grade de 3 colunas. A grade não rola sozinha
            // (a tela inteira rola), por isso `shrinkWrap` e `physics`.
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                for (final category in _categories)
                  _CategoryTile(
                    category: category,
                    selected: _category == category,
                    onTap: () => _onCategoryTap(category, field),
                  ),
              ],
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.brickDark, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorText,
                        style: const TextStyle(
                          color: AppColors.brickDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Teclado numérico grande, em grade 3x4.
  Widget _buildKeypad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.1,
      children: [
        for (final key in _keys)
          _KeyButton(keyLabel: key, onTap: () => _pressKey(key)),
      ],
    );
  }
}

/// Botão "Gasto" / "Entrada" do topo.
class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.petrol;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.petrol : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figura de uma categoria na grade.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: Material(
        color: selected ? AppColors.mintSoft : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 38, color: AppColors.petrol),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(category.label, style: AppText.h3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tecla do teclado numérico.
class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.keyLabel, required this.onTap});

  final String keyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBack = keyLabel == 'back';

    return Semantics(
      button: true,
      label: isBack ? 'Apagar' : (keyLabel == ',' ? 'vírgula' : keyLabel),
      child: Material(
        color: isBack ? AppColors.peachSoft : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: isBack
                ? const Icon(Icons.backspace_outlined, size: 28, color: AppColors.petrol)
                : Text(
                    keyLabel,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.petrol,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
