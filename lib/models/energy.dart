import '../services/api_client.dart';

/// Faixa de consumo em relação à meta mensal (a API calcula).
enum EnergyBand {
  green,
  yellow,
  red;

  static EnergyBand fromApi(dynamic value) {
    switch (value) {
      case 'VERMELHO':
        return EnergyBand.red;
      case 'AMARELO':
        return EnergyBand.yellow;
      default:
        return EnergyBand.green;
    }
  }
}

/// Medidor de energia da casa (`DispositivoDto`).
class EnergyDevice {
  const EnergyDevice({
    required this.id,
    required this.code,
    required this.tariff,
    required this.monthlyGoal,
  });

  factory EnergyDevice.fromJson(Map<String, dynamic> json) {
    return EnergyDevice(
      id: (json['id'] as num).toInt(),
      code: '${json['codigo']}',
      tariff: asDouble(json['tarifaKwh']),
      monthlyGoal: asDouble(json['metaMensalReais']),
    );
  }

  final int id;
  final String code;

  /// Preço do kWh em reais.
  final double tariff;

  /// Meta de gasto com luz no mês, em reais.
  final double monthlyGoal;
}

/// Resumo do mês de um medidor (`ResumoEnergiaDto`).
class EnergySummary {
  const EnergySummary({
    required this.totalKwh,
    required this.totalCost,
    required this.goal,
    required this.percent,
    required this.band,
  });

  factory EnergySummary.fromJson(Map<String, dynamic> json) {
    return EnergySummary(
      totalKwh: asDouble(json['totalKwh']),
      totalCost: asDouble(json['custoTotal']),
      goal: asDouble(json['metaMensalReais']),
      percent: asDouble(json['percentualMeta']),
      band: EnergyBand.fromApi(json['faixa']),
    );
  }

  final double totalKwh;
  final double totalCost;
  final double goal;

  /// Quanto da meta já foi gasto, em porcentagem (100 = bateu a meta).
  final double percent;
  final EnergyBand band;
}

/// Uma leitura enviada pelo medidor (`LeituraEnergiaDto`).
class EnergyReading {
  const EnergyReading({
    required this.id,
    required this.date,
    required this.powerW,
    required this.kwh,
    required this.cost,
  });

  factory EnergyReading.fromJson(Map<String, dynamic> json) {
    return EnergyReading(
      id: (json['id'] as num).toInt(),
      date: asDate(json['dataLeitura']),
      powerW: asDouble(json['potenciaW']),
      kwh: asDouble(json['kwh']),
      cost: asDouble(json['custoEstimado']),
    );
  }

  final int id;
  final DateTime date;
  final double powerW;
  final double kwh;
  final double cost;
}
