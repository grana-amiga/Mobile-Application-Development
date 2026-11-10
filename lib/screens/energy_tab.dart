import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/bill.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

/// Tela 7: Alertas e energia.
///
/// Mostra os vencimentos próximos e o custo de luz do mês vindo do medidor
/// de baixo custo (Arduino/ESP32). Nesta versão os dados do medidor são
/// simulados: a leitura "agora" muda a cada poucos segundos.
class EnergyTab extends StatefulWidget {
  const EnergyTab({super.key, required this.bills, required this.now});

  final List<Bill> bills;
  final DateTime now;

  @override
  State<EnergyTab> createState() => _EnergyTabState();
}

class _EnergyTabState extends State<EnergyTab> {
  // Dados de exemplo do mês.
  static const double _monthKwh = 180; // consumo até agora
  static const double _tariff = 0.80; // preço do kWh em reais
  static const double _goalReais = 180; // meta de gasto com luz

  // Consumo dos últimos 4 meses de semanas (kWh por semana), para o gráfico.
  static const List<double> _weeks = [38, 52, 47, 43];

  final math.Random _random = math.Random();
  Timer? _timer;
  bool _connected = true;
  int _watts = 420; // leitura "agora" do medidor

  double get _cost => _monthKwh * _tariff;
  double get _ratio => _cost / _goalReais;

  @override
  void initState() {
    super.initState();
    _startMeter();
  }

  // Timer.periodic repete a função a cada 2 segundos, simulando o medidor
  // enviando novas leituras. O setState redesenha a tela com o novo valor.
  void _startMeter() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() => _watts = 300 + _random.nextInt(260));
    });
  }

  void _toggleMeter(bool connected) {
    setState(() => _connected = connected);
    if (connected) {
      _startMeter();
    } else {
      _timer?.cancel();
    }
  }

  // Sempre cancelar timers ao fechar a tela, senão eles continuam rodando.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_ratio * 100).round();
    final next = widget.bills.isEmpty ? null : widget.bills.first;

    final audio = StringBuffer('Alertas e energia. ');
    if (next == null) {
      audio.write('Nenhuma conta vence nos próximos dias. ');
    } else {
      audio.write(
        'Você tem ${widget.bills.length} contas para os próximos dias. '
        'A mais próxima é ${next.name}, ${dueText(next.due, widget.now)}. ',
      );
    }
    audio.write('O gasto de luz do mês está em $percent por cento da meta.');

    return Scaffold(
      appBar: buildAppBar(
        title: 'Alertas e energia',
        audioText: audio.toString(),
        compactAudio: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const SectionTitle('Contas a vencer'),
          if (widget.bills.isEmpty)
            const _EmptyState(
              icon: Icons.celebration,
              text: 'Nenhuma conta vence nos próximos dias.',
            ),
          for (final bill in widget.bills)
            _BillTile(bill: bill, now: widget.now),
          const SectionTitle('Energia da casa', trailing: 'Dados de exemplo'),
          _buildEnergyCard(percent),
          const SizedBox(height: 14),
          _buildWeeklyChart(),
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

  Widget _buildEnergyCard(int percent) {
    final over = _ratio >= 1;
    final warning = _ratio >= 0.8;

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
                        value: _ratio.clamp(0.0, 1.0).toDouble(),
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
                    Text(formatBRL(_cost), style: AppText.h1.copyWith(fontSize: 30)),
                    Text(
                      'Meta: ${formatBRL(_goalReais)} · ${_monthKwh.toStringAsFixed(0)} kWh',
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
              const Expanded(child: Text('Medidor conectado', style: AppText.h3)),
              // Switch: chave de liga/desliga.
              Switch(value: _connected, onChanged: _toggleMeter),
            ],
          ),
          const SizedBox(height: 6),
          if (_connected)
            Text(
              'Agora: ${(_watts / 1000).toStringAsFixed(2).replaceAll('.', ',')} kW '
              '(cerca de ${formatBRL(_watts / 1000 * _tariff)} por hora)',
              style: AppText.body,
            )
          else
            const Text(
              'Medidor desligado. Ligue para ver o consumo em tempo real.',
              style: AppText.small,
            ),
        ],
      ),
    );
  }

  // Gráfico de barras simples feito só com Containers (sem pacotes extras).
  Widget _buildWeeklyChart() {
    final maxValue = _weeks.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consumo por semana (kWh)', style: AppText.h3),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _weeks.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${_weeks[i].toStringAsFixed(0)}', style: AppText.small),
                          const SizedBox(height: 4),
                          Container(
                            height: 80 * (_weeks[i] / maxValue),
                            decoration: BoxDecoration(
                              color: _weeks[i] == maxValue
                                  ? AppColors.peach
                                  : AppColors.mint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Sem ${i + 1}', style: AppText.small),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
