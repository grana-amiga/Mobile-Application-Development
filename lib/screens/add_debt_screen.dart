import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/debt.dart';
import '../services/api_client.dart';
import '../services/debt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

/// Tela para cadastrar uma dívida (`POST /dividas`).
///
/// Usa `Form` + `GlobalKey<FormState>` para validar os campos antes de enviar.
/// Ao salvar, devolve a [Debt] criada para a tela anterior.
class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _rateController = TextEditingController();
  final _installmentController = TextEditingController();
  final _dayController = TextEditingController();

  DebtType _type = DebtType.card;
  bool _saving = false;
  bool _showErrorsWhileTyping = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _rateController.dispose();
    _installmentController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  // Teclado numérico com vírgula para valores em reais e porcentagem.
  static const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

  // Validador de número decimal. [min] é o menor valor aceito e [max] (opcional)
  // o maior. A mensagem explica o que digitar.
  String? Function(String?) _numberValidator({
    required String empty,
    required double min,
    double? max,
    bool allowMin = true,
  }) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return empty;
      final number = parseAmount(text);
      if (number == null) return 'Digite só números, por exemplo 250,00.';
      if (allowMin ? number < min : number <= min) {
        return allowMin
            ? 'O valor mínimo é ${min.toString().replaceAll('.', ',')}.'
            : 'O valor precisa ser maior que zero.';
      }
      if (max != null && number > max) {
        return 'O valor máximo é ${max.toStringAsFixed(0)}.';
      }
      return null;
    };
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      setState(() => _showErrorsWhileTyping = true);
      showAppSnackBar(context, 'Confira os campos em vermelho.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final debt = await DebtService.instance.create(
        name: _nameController.text,
        type: _type,
        balance: parseAmount(_balanceController.text) ?? 0.0,
        monthlyRate: parseAmount(_rateController.text) ?? 0.0,
        installmentValue: parseAmount(_installmentController.text) ?? 0.0,
        dueDay: int.tryParse(_dayController.text.trim()) ?? 1,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Dívida "${debt.name}" cadastrada!');
      Navigator.pop(context, debt);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        title: 'Nova dívida',
        audioText:
            'Cadastrar dívida. Escolha o tipo, diga com quem você deve, quanto falta pagar, os juros do mês, o valor da parcela e o dia do vencimento.',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _showErrorsWhileTyping
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text('Que tipo de dívida é?', style: AppText.h2),
              const SizedBox(height: 12),
              // Wrap + ChoiceChip: escolha de uma opção entre várias.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in DebtType.values)
                    ChoiceChip(
                      avatar: Icon(type.icon, size: 20, color: AppColors.petrol),
                      label: Text(type.label),
                      selected: _type == type,
                      showCheckmark: false,
                      selectedColor: AppColors.peachSoft,
                      backgroundColor: AppColors.card,
                      labelStyle: const TextStyle(
                        color: AppColors.petrol,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                style: AppText.body.copyWith(fontSize: 18),
                decoration: appInputDecoration(
                  label: 'Com quem você deve?',
                  hint: 'Banco, loja, pessoa...',
                  icon: Icons.storefront,
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Digite com quem você deve.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _balanceController,
                keyboardType: _decimalKeyboard,
                textInputAction: TextInputAction.next,
                style: AppText.body.copyWith(fontSize: 18),
                decoration: appInputDecoration(
                  label: 'Quanto falta pagar? (R\$)',
                  hint: '1500,00',
                  icon: Icons.attach_money,
                ),
                validator: _numberValidator(
                  empty: 'Digite quanto falta pagar.',
                  min: 0,
                  allowMin: false,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rateController,
                keyboardType: _decimalKeyboard,
                textInputAction: TextInputAction.next,
                style: AppText.body.copyWith(fontSize: 18),
                decoration: appInputDecoration(
                  label: 'Juros por mês (%)',
                  hint: '5,5',
                  icon: Icons.percent,
                ),
                validator: _numberValidator(
                  empty: 'Digite os juros do mês. Se não tiver, digite 0.',
                  min: 0,
                  max: 100,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _installmentController,
                keyboardType: _decimalKeyboard,
                textInputAction: TextInputAction.next,
                style: AppText.body.copyWith(fontSize: 18),
                decoration: appInputDecoration(
                  label: 'Valor da parcela (R\$)',
                  hint: '250,00',
                  icon: Icons.receipt_long,
                ),
                validator: _numberValidator(
                  empty: 'Digite o valor da parcela.',
                  min: 0,
                  allowMin: false,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dayController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: AppText.body.copyWith(fontSize: 18),
                decoration: appInputDecoration(
                  label: 'Dia do vencimento (1 a 31)',
                  hint: '10',
                  icon: Icons.calendar_today,
                ),
                validator: (value) {
                  final day = int.tryParse((value ?? '').trim());
                  if (day == null) return 'Digite o dia do mês em que a parcela vence.';
                  if (day < 1 || day > 31) return 'Digite um dia entre 1 e 31.';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Salvar dívida',
                icon: Icons.check,
                showArrow: false,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
