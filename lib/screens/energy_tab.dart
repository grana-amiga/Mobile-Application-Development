import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/bill.dart';
import '../models/energy.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

/// Tela 7: Alertas e energia.
///
/// Mostra os vencimentos próximos (vindos de `/dividas/alertas`) e o custo de
/// luz do mês vindo do medidor de baixo custo (Arduino/ESP32) pela API de
/// energia. Nesta versão o botão "Simular leitura" faz o papel do medidor:
/// ele envia uma leitura para a API, como o aparelho faria sozinho.
class EnergyTab extends StatefulWidget {
  const EnergyTab({super.key, required this.bills, required this.now});

  final List<Bill> bills;
  final DateTime now;

  /// Texto lido em voz alta pelo botão de áudio da barra superior.
  static String audioText(List<Bill> bills, DateTime now) {
    final audio = StringBuffer('Alertas e energia. ');
    if (bills.isEmpty) {
      audio.write('Nenhuma conta vence nos próximos dias. ');
    } else {
      audio.write(
        'Você tem ${bills.length} contas para os próximos dias. '
        'A mais próxima é ${bills.first.name}, ${dueText(bills.first.due, now)}. ',
      );
    }
    audio.write('Mais abaixo, veja o gasto de luz do mês em relação à sua meta.');
    return audio.toString();
  }

  @override
  State<EnergyTab> createState() => _EnergyTabState();
}

class _EnergyTabState extends State<EnergyTab> {
  final EnergyService _api = EnergyService.instance;
  final math.Random _random = math.Random();

  bool _loading = true;
  String? _error;
  bool _sending = false; // true enquanto envia uma leitura simulada

  EnergyDevice? _device;
  EnergySummary? _summary;
  List<EnergyReading> _readings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Carrega o medidor e, se existir, o resumo do mês e as últimas leituras.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final device = await _api.firstDevice();
      EnergySummary? summary;
      var readings = const <EnergyReading>[];
      if (device != null) {
        final now = DateTime.now();
        summary = await _api.summary(device.id, now.year, now.month);
        readings = await _api.latestReadings(device.id);
      }
      if (!mounted) return;
      setState(() {
        _device = device;
        _summary = summary;
        _readings = readings;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _onDeviceCreated(EnergyDevice device) {
    setState(() => _device = device);
    showAppSnackBar(context, 'Medidor "${device.code}" cadastrado!');
    _load();
  }

  // Envia uma leitura de exemplo (um dia de consumo) e recarrega o resumo.
  Future<void> _simulateReading() async {
    final device = _device;
    if (device == null || _sending) return;
    setState(() => _sending = true);

    final powerW = (300 + _random.nextInt(260)).toDouble();
    final kwh = double.parse((powerW / 1000 * 24).toStringAsFixed(3));
    try {
      final reading = await _api.addReading(device.id, powerW: powerW, kwh: kwh);
      final now = DateTime.now();
      final summary = await _api.summary(device.id, now.year, now.month);
      final readings = await _api.latestReadings(device.id);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _readings = readings;
        _sending = false;
      });
      showAppSnackBar(
        context,
        'Leitura registrada: ${reading.kwh.toStringAsFixed(1).replaceAll('.', ',')} kWh '
        '(${formatBRL(reading.cost)}).',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const SectionTitle('Contas a vencer'),
          if (widget.bills.isEmpty)
            const _EmptyState(
              icon: Icons.celebration,
              text: 'Nenhuma conta vence nos próximos dias.',
            ),
          for (final bill in widget.bills) _BillTile(bill: bill, now: widget.now),
          const SectionTitle('Energia da casa'),
          _buildEnergySection(),
          const SectionTitle('Dicas para gastar menos luz'),
          const _TipRow(
            icon: Icons.shower,
            text: 'Banho mais curto: o chuveiro elétrico é um dos maiores gastos da casa.',
          ),
          const _TipRow(
            icon: Icons.power,
            text: 'Tire da tomada o que não está usando. O modo espera também gasta.',
          ),
          const _TipRow(
            icon: Icons.kitchen,
            text: 'Mantenha a porta da geladeira bem fechada.',
          ),
        ],
      ),
    );
  }

  // Escolhe o que mostrar: carregando, erro, cadastro do medidor ou os dados.
  Widget _buildEnergySection() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecor.card(radius: 26),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: AppDecor.card(color: AppColors.brickSoft, radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.brickDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Não foi possível carregar a energia.', style: AppText.h3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(error, style: AppText.body),
            const SizedBox(height: 12),
            AppButton(
              label: 'Tentar de novo',
              icon: Icons.refresh,
              kind: AppButtonKind.dark,
              showArrow: false,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final device = _device;
    final summary = _summary;
    if (device == null || summary == null) {
      return _DeviceForm(onCreated: _onDeviceCreated);
    }

    return Column(
      children: [
        _buildEnergyCard(device, summary),
        const SizedBox(height: 14),
        _buildReadingsChart(),
      ],
    );
  }

  Widget _buildEnergyCard(EnergyDevice device, EnergySummary summary) {
    final ratio = summary.percent / 100;
    final percent = summary.percent.round();
    final over = summary.band == EnergyBand.red;
    final warning = summary.band != EnergyBand.green;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stack coloca o texto do percentual por cima do círculo.
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: ratio.clamp(0.0, 1.0).toDouble(),
                        strokeWidth: 12,
                        backgroundColor: AppColors.border,
                        color: over
                            ? AppColors.brick
                            : (warning ? AppColors.yellow : AppColors.green),
                      ),
                    ),
                    Text('$percent%', style: AppText.h2),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gasto de luz no mês', style: AppText.small),
                    Text(
                      formatBRL(summary.totalCost),
                      style: AppText.h1.copyWith(fontSize: 30),
                    ),
                    Text(
                      'Meta: ${formatBRL(summary.goal)} · ${summary.totalKwh.toStringAsFixed(0)} kWh',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warning) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: over ? AppColors.brickSoft : AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    over ? Icons.error_outline : Icons.bolt,
                    color: over ? AppColors.brickDark : AppColors.petrol,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      over
                          ? 'A meta de luz estourou! Veja as dicas abaixo para economizar.'
                          : 'Você já usou $percent% da meta de luz. Falta pouco para estourar!',
                      style: TextStyle(
                        color: over ? AppColors.brickDark : AppColors.petrol,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 28, color: AppColors.border),
          Row(
            children: [
              const Icon(Icons.sensors, color: AppColors.petrol),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Medidor ${device.code}', style: AppText.h3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tarifa: ${formatBRL(device.tariff)} por kWh. No produto real, o medidor '
            'envia as leituras sozinho. Aqui você pode simular uma.',
            style: AppText.small,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Simular leitura do medidor',
            icon: Icons.sensors,
            kind: AppButtonKind.light,
            showArrow: false,
            loading: _sending,
            onPressed: _simulateReading,
          ),
        ],
      ),
    );
  }

  // Gráfico de barras simples feito só com Containers (sem pacotes extras).
  Widget _buildReadingsChart() {
    final readings = _readings;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Últimas leituras (kWh)', style: AppText.h3),
          const SizedBox(height: 14),
          if (readings.isEmpty)
            const Text(
              'Ainda não há leituras. Toque em "Simular leitura do medidor" para ver o gráfico.',
              style: AppText.body,
            )
          else
            _ReadingsBars(readings: readings),
        ],
      ),
    );
  }
}

/// Barras com o consumo (kWh) de cada leitura.
class _ReadingsBars extends StatelessWidget {
  const _ReadingsBars({required this.readings});

  final List<EnergyReading> readings;

  @override
  Widget build(BuildContext context) {
    final maxValue = readings.map((r) => r.kwh).reduce(math.max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final reading in readings)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(reading.kwh.toStringAsFixed(1), style: AppText.small),
                    const SizedBox(height: 4),
                    Container(
                      height: 80 * (reading.kwh / safeMax),
                      decoration: BoxDecoration(
                        color: reading.kwh == maxValue
                            ? AppColors.peach
                            : AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reading.date.day}/${reading.date.month}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Formulário para cadastrar o medidor (`POST /dispositivos`).
class _DeviceForm extends StatefulWidget {
  const _DeviceForm({required this.onCreated});

  final ValueChanged<EnergyDevice> onCreated;

  @override
  State<_DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<_DeviceForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController(
    text: 'CASA-${AuthService.instance.userId ?? ''}',
  );
  final _tariffController = TextEditingController(text: '0,80');
  final _goalController = TextEditingController(text: '180,00');
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _tariffController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  String? _positive(String? value, String empty) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return empty;
    final number = parseAmount(text);
    if (number == null || number <= 0) return 'Digite um valor maior que zero.';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      showAppSnackBar(context, 'Confira os campos em vermelho.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final device = await EnergyService.instance.createDevice(
        code: _codeController.text,
        tariff: parseAmount(_tariffController.text) ?? 0.0,
        monthlyGoal: parseAmount(_goalController.text) ?? 0.0,
      );
      if (!mounted) return;
      widget.onCreated(device);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sensors, color: AppColors.petrol),
                SizedBox(width: 8),
                Expanded(child: Text('Cadastre o medidor de luz', style: AppText.h3)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Informe a tarifa da sua conta de luz e quanto quer gastar por mês. '
              'Depois o app mostra se você está dentro da meta.',
              style: AppText.body,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _codeController,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              style: AppText.body.copyWith(fontSize: 18),
              decoration: appInputDecoration(
                label: 'Nome do medidor',
                icon: Icons.sensors,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Digite um nome para o medidor.';
                return null;
              },
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _tariffController,
              keyboardType: decimal,
              textInputAction: TextInputAction.next,
              style: AppText.body.copyWith(fontSize: 18),
              decoration: appInputDecoration(
                label: 'Preço do kWh (R\$)',
                hint: '0,80',
                icon: Icons.bolt,
              ),
              validator: (value) => _positive(value, 'Digite o preço do kWh.'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _goalController,
              keyboardType: decimal,
              textInputAction: TextInputAction.done,
              style: AppText.body.copyWith(fontSize: 18),
              decoration: appInputDecoration(
                label: 'Meta de gasto por mês (R\$)',
                hint: '180,00',
                icon: Icons.flag,
              ),
              validator: (value) => _positive(value, 'Digite a meta do mês.'),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Cadastrar medidor',
              icon: Icons.check,
              showArrow: false,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de uma conta a vencer.
class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill, required this.now});

  final Bill bill;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = daysBetween(now, bill.due);
    final urgent = days <= 3;
    final soon = days <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 22),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: urgent ? AppColors.brickSoft : AppColors.peachSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              bill.icon,
              color: urgent ? AppColors.brickDark : AppColors.petrol,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: AppText.h3),
                const SizedBox(height: 4),
                TagChip(
                  icon: urgent ? Icons.notifications_active : Icons.calendar_today,
                  label: '${dueText(bill.due, now)} · ${formatShortDate(bill.due)}',
                  background: urgent
                      ? AppColors.brickSoft
                      : (soon ? AppColors.yellowSoft : AppColors.mintSoft),
                  foreground: urgent ? AppColors.brickDark : AppColors.petrol,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatBRL(bill.amount), style: AppText.h3),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.petrol, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(color: AppColors.mintSoft, radius: 22),
      child: Row(
        children: [
          Icon(icon, color: AppColors.petrol, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
