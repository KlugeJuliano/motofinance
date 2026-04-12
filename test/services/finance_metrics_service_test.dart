import 'package:flutter_test/flutter_test.dart';
import 'package:motofinance/models/despesa_model.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/services/finance_metrics_service.dart';

void main() {
  group('FinanceMetricsService', () {
    const service = FinanceMetricsService();
    final now = DateTime(2025, 1, 15, 18, 0);

    test('deve resumir o painel do dia fora da view', () {
      final jornadas = [
        Jornada(
          id: 1,
          inicio: DateTime(2025, 1, 15, 8, 0),
          fim: DateTime(2025, 1, 15, 12, 0),
          kmInicial: 100,
          kmFinal: 130,
          kmRodados: 30,
        ),
        Jornada(
          id: 2,
          inicio: DateTime(2025, 1, 15, 13, 0),
          fim: null,
          kmInicial: 130,
          kmFinal: null,
          kmRodados: 20,
        ),
        Jornada(
          id: 3,
          inicio: DateTime(2025, 1, 14, 10, 0),
          fim: DateTime(2025, 1, 14, 14, 0),
          kmInicial: 50,
          kmFinal: 80,
          kmRodados: 30,
        ),
      ];

      final ganhos = [
        Ganho(
          id: 1,
          jornadaId: 1,
          valor: 100,
          descricao: 'Principal 1',
          tipo: 'principal',
        ),
        Ganho(
          id: 2,
          jornadaId: 2,
          valor: 40,
          descricao: 'Extra 2',
        ),
        Ganho(
          id: 3,
          jornadaId: 3,
          valor: 999,
          descricao: 'Outro dia',
          tipo: 'principal',
        ),
      ];

      final despesas = [
        Despesa(id: 1, jornadaId: 1, valor: 25, categoria: 'Combustivel'),
        Despesa(id: 2, jornadaId: 2, valor: 15, categoria: 'Almoco'),
        Despesa(id: 3, jornadaId: 3, valor: 999, categoria: 'Outro dia'),
      ];

      final summary = service.buildDashboardSummary(
        jornadas: jornadas,
        ganhos: ganhos,
        despesas: despesas,
        now: now,
      );

      expect(summary.jornadasHoje, hasLength(2));
      expect(summary.jornadaAberta?.id, 2);
      expect(summary.kmRodadosHoje, 50);
      expect(summary.ganhosPrincipaisHoje, 100);
      expect(summary.ganhosExtrasHoje, 40);
      expect(summary.ganhosHoje, 140);
      expect(summary.despesasHoje, 40);
      expect(summary.saldoHoje, 100);
      expect(summary.horasTrabalhadasHoje, 10);
      expect(summary.ganhoPorKm, 2);
      expect(summary.ganhoPorHora, 10);
    });

    test('deve consolidar o relatorio semanal fora da view', () {
      final jornadas = [
        Jornada(
          id: 1,
          inicio: DateTime(2025, 1, 13, 8, 0),
          fim: DateTime(2025, 1, 13, 12, 0),
          kmInicial: 100,
          kmFinal: 140,
          kmRodados: 40,
        ),
        Jornada(
          id: 2,
          inicio: DateTime(2025, 1, 13, 14, 0),
          fim: DateTime(2025, 1, 13, 18, 0),
          kmInicial: 140,
          kmFinal: 180,
          kmRodados: 40,
        ),
        Jornada(
          id: 3,
          inicio: DateTime(2025, 1, 10, 8, 0),
          fim: DateTime(2025, 1, 10, 10, 0),
          kmInicial: 10,
          kmFinal: 20,
          kmRodados: 10,
        ),
      ];

      final ganhos = [
        Ganho(
          id: 1,
          jornadaId: 1,
          valor: 120,
          descricao: 'Principal',
          tipo: 'principal',
        ),
        Ganho(
          id: 2,
          jornadaId: 2,
          valor: 30,
          descricao: 'Extra',
        ),
        Ganho(
          id: 3,
          jornadaId: 3,
          valor: 999,
          descricao: 'Fora da semana',
        ),
      ];

      final despesas = [
        Despesa(id: 1, jornadaId: 1, valor: 20, categoria: 'Gasolina'),
        Despesa(id: 2, jornadaId: 2, valor: 10, categoria: 'Cafe'),
        Despesa(id: 3, jornadaId: 3, valor: 999, categoria: 'Fora da semana'),
      ];

      final report = service.buildReportSummary(
        period: ReportPeriod.semana,
        jornadas: jornadas,
        ganhos: ganhos,
        despesas: despesas,
        now: now,
      );

      expect(report.interval.start, DateTime(2025, 1, 13));
      expect(report.interval.end, DateTime(2025, 1, 20));
      expect(report.details, hasLength(1));
      expect(report.details.first.day, DateTime(2025, 1, 13));
      expect(report.details.first.km, 80);
      expect(report.details.first.hours, 10);
      expect(report.details.first.gains, 150);
      expect(report.details.first.expenses, 30);
      expect(report.totalKm, 80);
      expect(report.totalHours, 10);
      expect(report.totalGains, 150);
      expect(report.totalExpenses, 30);
    });
  });
}
