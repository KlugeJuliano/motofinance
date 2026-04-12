import 'package:motofinance/models/despesa_model.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/models/jornada_model.dart';

enum ReportPeriod { semana, mes }

class DateInterval {
  const DateInterval({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

class DashboardSummary {
  const DashboardSummary({
    required this.referenceDate,
    required this.jornadasHoje,
    required this.jornadaAberta,
    required this.kmRodadosHoje,
    required this.ganhosPrincipaisHoje,
    required this.ganhosExtrasHoje,
    required this.ganhosHoje,
    required this.despesasHoje,
    required this.saldoHoje,
    required this.horasTrabalhadasHoje,
    required this.ganhoPorKm,
    required this.ganhoPorHora,
  });

  final DateTime referenceDate;
  final List<Jornada> jornadasHoje;
  final Jornada? jornadaAberta;
  final double kmRodadosHoje;
  final double ganhosPrincipaisHoje;
  final double ganhosExtrasHoje;
  final double ganhosHoje;
  final double despesasHoje;
  final double saldoHoje;
  final double horasTrabalhadasHoje;
  final double ganhoPorKm;
  final double ganhoPorHora;
}

class ReportDayDetail {
  const ReportDayDetail({
    required this.day,
    required this.km,
    required this.hours,
    required this.gains,
    required this.expenses,
  });

  final DateTime day;
  final double km;
  final double hours;
  final double gains;
  final double expenses;
}

class ReportSummary {
  const ReportSummary({
    required this.interval,
    required this.details,
    required this.totalKm,
    required this.totalHours,
    required this.totalGains,
    required this.totalExpenses,
  });

  final DateInterval interval;
  final List<ReportDayDetail> details;
  final double totalKm;
  final double totalHours;
  final double totalGains;
  final double totalExpenses;
}

class FinanceMetricsService {
  const FinanceMetricsService();

  DashboardSummary buildDashboardSummary({
    required List<Jornada> jornadas,
    required List<Ganho> ganhos,
    required List<Despesa> despesas,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final jornadasHoje = jornadas
        .where((jornada) => _isSameDay(jornada.inicio, reference))
        .toList();
    final jornadaAberta = jornadas.cast<Jornada?>().firstWhere(
          (jornada) => jornada?.fim == null,
          orElse: () => null,
        );
    final jornadaIdsHoje =
        jornadasHoje.map((jornada) => jornada.id).whereType<int>().toSet();

    final kmRodadosHoje = jornadasHoje.fold<double>(
      0,
      (total, jornada) => total + (jornada.kmRodados ?? 0),
    );

    final ganhosPrincipaisHoje = ganhos
        .where(
          (ganho) =>
              ganho.tipo == 'principal' &&
              jornadaIdsHoje.contains(ganho.jornadaId),
        )
        .fold<double>(0, (total, ganho) => total + ganho.valor);

    final ganhosExtrasHoje = ganhos
        .where(
          (ganho) =>
              ganho.tipo == 'extra' && jornadaIdsHoje.contains(ganho.jornadaId),
        )
        .fold<double>(0, (total, ganho) => total + ganho.valor);

    final ganhosHoje = ganhosPrincipaisHoje + ganhosExtrasHoje;

    final despesasHoje = despesas
        .where((despesa) => jornadaIdsHoje.contains(despesa.jornadaId))
        .fold<double>(0, (total, despesa) => total + despesa.valor);

    final saldoHoje = ganhosHoje - despesasHoje;
    final horasTrabalhadasHoje = calculateWorkedHours(
      jornadasHoje,
      now: reference,
    );

    return DashboardSummary(
      referenceDate: reference,
      jornadasHoje: jornadasHoje,
      jornadaAberta: jornadaAberta,
      kmRodadosHoje: kmRodadosHoje,
      ganhosPrincipaisHoje: ganhosPrincipaisHoje,
      ganhosExtrasHoje: ganhosExtrasHoje,
      ganhosHoje: ganhosHoje,
      despesasHoje: despesasHoje,
      saldoHoje: saldoHoje,
      horasTrabalhadasHoje: horasTrabalhadasHoje,
      ganhoPorKm: kmRodadosHoje > 0 ? saldoHoje / kmRodadosHoje : 0,
      ganhoPorHora:
          horasTrabalhadasHoje > 0 ? saldoHoje / horasTrabalhadasHoje : 0,
    );
  }

  ReportSummary buildReportSummary({
    required ReportPeriod period,
    required List<Jornada> jornadas,
    required List<Ganho> ganhos,
    required List<Despesa> despesas,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final interval = currentInterval(period, now: reference);
    final jornadasPeriodo = jornadas.where(
      (jornada) =>
          !jornada.inicio.isBefore(interval.start) &&
          jornada.inicio.isBefore(interval.end),
    );

    final Map<DateTime, _DailyAccumulator> grouped = {};

    for (final jornada in jornadasPeriodo) {
      final day = DateTime(
        jornada.inicio.year,
        jornada.inicio.month,
        jornada.inicio.day,
      );

      final accumulator = grouped.putIfAbsent(
        day,
        () => _DailyAccumulator(day: day),
      );

      accumulator.km += jornada.kmRodados ?? 0;
      accumulator.startTimes.add(jornada.inicio);
      accumulator.endTimes.add(jornada.fim ?? reference);

      final jornadaGanhos = ganhos.where((ganho) => ganho.jornadaId == jornada.id);
      final jornadaDespesas =
          despesas.where((despesa) => despesa.jornadaId == jornada.id);

      accumulator.gains +=
          jornadaGanhos.fold<double>(0, (sum, ganho) => sum + ganho.valor);
      accumulator.expenses += jornadaDespesas.fold<double>(
        0,
        (sum, despesa) => sum + despesa.valor,
      );
    }

    final details = grouped.values
        .map(
          (item) => ReportDayDetail(
            day: item.day,
            km: item.km,
            hours: item.calculateWorkedHours(),
            gains: item.gains,
            expenses: item.expenses,
          ),
        )
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));

    return ReportSummary(
      interval: interval,
      details: details,
      totalKm: details.fold<double>(0, (sum, item) => sum + item.km),
      totalHours: details.fold<double>(0, (sum, item) => sum + item.hours),
      totalGains: details.fold<double>(0, (sum, item) => sum + item.gains),
      totalExpenses:
          details.fold<double>(0, (sum, item) => sum + item.expenses),
    );
  }

  DateInterval currentInterval(ReportPeriod period, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (period == ReportPeriod.mes) {
      return DateInterval(
        start: DateTime(reference.year, reference.month),
        end: DateTime(reference.year, reference.month + 1),
      );
    }

    final start = DateTime(reference.year, reference.month, reference.day)
        .subtract(Duration(days: reference.weekday - 1));
    return DateInterval(
      start: start,
      end: start.add(const Duration(days: 7)),
    );
  }

  double calculateWorkedHours(List<Jornada> jornadas, {DateTime? now}) {
    if (jornadas.isEmpty) {
      return 0;
    }

    final reference = now ?? DateTime.now();
    final start = jornadas
        .map((jornada) => jornada.inicio)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = jornadas
        .map((jornada) => jornada.fim ?? reference)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final duration = end.difference(start).inMinutes / 60;
    return duration.isNegative ? 0 : duration;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DailyAccumulator {
  _DailyAccumulator({required this.day});

  final DateTime day;
  double km = 0;
  double gains = 0;
  double expenses = 0;
  final List<DateTime> startTimes = [];
  final List<DateTime> endTimes = [];

  double calculateWorkedHours() {
    if (startTimes.isEmpty || endTimes.isEmpty) {
      return 0;
    }

    final start = startTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = endTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    final duration = end.difference(start).inMinutes / 60;
    return duration.isNegative ? 0 : duration;
  }
}
