import '../models/energy.dart';
import 'api_client.dart';

/// Chamadas da API de energia (`/dispositivos`).
class EnergyService {
  EnergyService._();

  static final EnergyService instance = EnergyService._();

  final ApiClient _api = ApiClient.instance;

  /// `GET /dispositivos`: devolve o primeiro medidor da família (ou `null`).
  Future<EnergyDevice?> firstDevice() async {
    final data = await _api.get('/dispositivos');
    final items = data is List ? data : const [];
    if (items.isEmpty) return null;
    return EnergyDevice.fromJson(items.first as Map<String, dynamic>);
  }

  /// `POST /dispositivos`: cadastra um medidor.
  Future<EnergyDevice> createDevice({
    required String code,
    required double tariff,
    required double monthlyGoal,
  }) async {
    final data = await _api.post(
      '/dispositivos',
      body: {
        'codigo': code.trim(),
        'tarifaKwh': tariff,
        'metaMensalReais': monthlyGoal,
      },
    );
    return EnergyDevice.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /dispositivos/{id}/resumo`: consumo, custo e meta do mês.
  Future<EnergySummary> summary(int deviceId, int year, int month) async {
    final data = await _api.get(
      '/dispositivos/$deviceId/resumo',
      query: {'ano': '$year', 'mes': '$month'},
    );
    return EnergySummary.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /dispositivos/{id}/leituras`: as leituras mais recentes, devolvidas
  /// da mais antiga para a mais nova (boa ordem para o gráfico).
  Future<List<EnergyReading>> latestReadings(int deviceId, {int size = 6}) async {
    final data = await _api.get(
      '/dispositivos/$deviceId/leituras',
      query: {'pagina': '0', 'tamanho': '$size'},
    );
    final items = (data is Map ? data['itens'] : null) as List? ?? const [];
    final readings = items
        .map((item) => EnergyReading.fromJson(item as Map<String, dynamic>))
        .toList();
    return readings.reversed.toList();
  }

  /// `POST /dispositivos/{id}/leituras`: registra uma leitura. A API calcula
  /// o custo com a tarifa do medidor e usa a data/hora do servidor.
  Future<EnergyReading> addReading(
    int deviceId, {
    required double powerW,
    required double kwh,
  }) async {
    final data = await _api.post(
      '/dispositivos/$deviceId/leituras',
      body: {'potenciaW': powerW, 'kwh': kwh},
    );
    return EnergyReading.fromJson(data as Map<String, dynamic>);
  }
}
