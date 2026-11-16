import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../services/api_client.dart';
import '../services/education_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mascot.dart';

/// Simuladores de educação financeira: poupança e juros compostos.
///
/// Os cálculos são feitos pela API (`/educacao/simuladores/...`), que é
/// pública: dá para usar sem criar conta.
class SimulatorsScreen extends StatefulWidget {
  const SimulatorsScreen({super.key});

  @override
  State<SimulatorsScreen> createState() => _SimulatorsScreenState();
}

/// Resultado já formatado para mostrar na tela.
class _SimResult {
  const _SimResult({required this.headline, required this.rows, required this.tip});

  final String headline;
  final List<(String, String)> rows; // (rótulo, valor)
  final String tip;
}

class _SimulatorsScreenState extends State<SimulatorsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _rateController = TextEditingController();
  final _monthsController = TextEditingController();

  bool _isSavings = true; // true = poupança, false = juros (dívida)
  bool _loading = false;
  bool _showErrorsWhileTyping = false;
  _SimResult? _result;

  @override
  void dispose() {
    _valueController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  void _setMode(bool savings) {
    setState(() {
      _isSavings = savings;
      _result = null;
      _showErrorsWhileTyping = false;
    });
    _formKey.currentState?.reset();
  }

  // Valida o número digitado (aceita vírgula) dentro de um intervalo.
  String? _validateNumber(String? value, {required double max}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Preencha este campo.';
    final number = parseAmount(text);
    if (number == null) return 'Digite só números, por exemplo 100,00.';
    if (number < 0) return 'O valor não pode ser negativo.';
    if (number > max) return 'O valor máximo é ${max.toStringAsFixed(0)}.';
    return null;
  }

  Future<void> _simulate() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      setState(() => _showErrorsWhileTyping = true);
      showAppSnackBar(context, 'Confira os campos em vermelho.', isError: true);
      return;
    }

    final value = parseAmount(_valueController.text) ?? 0.0;
    final rate = parseAmount(_rateController.text) ?? 0.0;
    final months = int.tryParse(_monthsController.text.trim()) ?? 1;

    setState(() => _loading = true);
    try {
      final _SimResult result;
      if (_isSavings) {
        final data = await EducationService.instance.savings(
          monthlyDeposit: value,
          monthlyRate: rate,
          months: months,
        );
        result = _SimResult(
          headline: 'Em $months ${months == 1 ? 'mês' : 'meses'} você terá ${formatBRL(data.finalBalance)}',
          rows: [
            ('Você guardou', formatBRL(data.totalContributed)),
            ('Rendimento', formatBRL(data.earnings)),
          ],
          tip: 'Guardar um pouco todo mês, com paciência, faz o dinheiro crescer.',
        );
      } else {
        final data = await EducationService.instance.compoundInterest(
          initialValue: value,
          monthlyRate: rate,
          months: months,
        );
        result = _SimResult(
          headline: 'Em $months ${months == 1 ? 'mês' : 'meses'} a dívida vira ${formatBRL(data.amount)}',
          rows: [
            ('Valor da dívida hoje', formatBRL(value)),
            ('Só de juros', formatBRL(data.totalInterest)),
          ],
          tip: 'Juros sobre juros fazem a dívida crescer rápido. Por isso é bom pagar primeiro a que tem mais juros.',
        );
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final result = _result;

    return Scaffold(
      appBar: buildAppBar(
        title: 'Simuladores',
        audioText:
            'Simuladores. Descubra quanto o seu dinheiro rende se você guardar todo mês, ou quanto uma dívida cresce com os juros.',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const MascotTip(
              title: 'Teste antes de decidir',
              message: 'Veja quanto o dinheiro rende ou quanto uma dívida cresce. É só uma simulação.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Guardar dinheiro',
                    selected: _isSavings,
                    onTap: () => _setMode(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: 'Dívida com juros',
                    selected: !_isSavings,
                    onTap: () => _setMode(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              autovalidateMode: _showErrorsWhileTyping
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  TextFormField(
                    controller: _valueController,
                    keyboardType: decimal,
                    textInputAction: TextInputAction.next,
                    style: AppText.body.copyWith(fontSize: 18),
                    decoration: appInputDecoration(
                      label: _isSavings
                          ? 'Quanto vai guardar por mês? (R\$)'
                          : 'Valor da dívida (R\$)',
                      hint: _isSavings ? '100,00' : '1000,00',
                      icon: Icons.attach_money,
                    ),
                    validator: (value) => _validateNumber(value, max: 1000000000),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rateController,
                    keyboardType: decimal,
                    textInputAction: TextInputAction.next,
                    style: AppText.body.copyWith(fontSize: 18),
                    decoration: appInputDecoration(
                      label: 'Juros por mês (%)',
                      hint: _isSavings ? '0,5' : '8',
                      icon: Icons.percent,
                    ),
                    validator: (value) => _validateNumber(value, max: 100),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _monthsController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: AppText.body.copyWith(fontSize: 18),
                    decoration: appInputDecoration(
                      label: 'Por quantos meses?',
                      hint: '12',
                      icon: Icons.calendar_month,
                    ),
                    validator: (value) {
                      final months = int.tryParse((value ?? '').trim());
                      if (months == null) return 'Digite o número de meses.';
                      if (months < 1 || months > 600) return 'Digite entre 1 e 600 meses.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Simular',
              icon: Icons.calculate,
              showArrow: false,
              loading: _loading,
              onPressed: _simulate,
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Calculando... na primeira vez pode levar até 1 minuto.',
                  textAlign: TextAlign.center,
                  style: AppText.small,
                ),
              ),
            if (result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: result),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botão do seletor de tipo de simulação.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.petrol : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.petrol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão com o resultado da simulação.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _SimResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(color: AppColors.mintSoft, radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.headline, style: AppText.h2),
          const SizedBox(height: 12),
          for (final (label, value) in result.rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: AppText.body)),
                  Text(value, style: AppText.h3),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.petrol),
              const SizedBox(width: 8),
              Expanded(child: Text(result.tip, style: AppText.small)),
            ],
          ),
        ],
      ),
    );
  }
}
