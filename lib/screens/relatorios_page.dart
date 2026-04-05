import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/models/despesa_model.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

enum _PeriodoRelatorio { semana, mes }

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
  final DateFormat _dayFormat = DateFormat('dd/MM');
  _PeriodoRelatorio _periodo = _PeriodoRelatorio.semana;

  @override
  void initState() {
    super.initState();
    if (!widget.loadData) {
      return;
    }
    final jornadaProvider = context.read<JornadaProvider>();
    final ganhoProvider = context.read<GanhoProvider>();
    final despesaProvider = context.read<DespesaProvider>();
    Future.microtask(() async {
      await jornadaProvider.carregarJornadas();
      await ganhoProvider.carregarGanhos();
      await despesaProvider.carregarDespesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jornadas = context.watch<JornadaProvider>().jornadas;
    final ganhos = context.watch<GanhoProvider>().ganhos;
    final despesas = context.watch<DespesaProvider>().despesas;

    final intervalo = _intervaloAtual();
    final jornadasPeriodo = jornadas.where(
      (jornada) =>
          !jornada.inicio.isBefore(intervalo.start) &&
          jornada.inicio.isBefore(intervalo.end),
    );
    final detalhes = _buildDetalhes(
      jornadasPeriodo.toList(),
      ganhos,
      despesas,
    );
    final totalKm = detalhes.fold<double>(0, (sum, item) => sum + item.km);
    final totalHoras = detalhes.fold<double>(0, (sum, item) => sum + item.horas);
    final totalGanhos =
        detalhes.fold<double>(0, (sum, item) => sum + item.ganhos);
    final totalDespesas =
        detalhes.fold<double>(0, (sum, item) => sum + item.despesas);

    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Relatorios'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PeriodoSwitcher(
            periodo: _periodo,
            onChanged: (periodo) {
              setState(() {
                _periodo = periodo;
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodo == _PeriodoRelatorio.semana
                      ? 'Resumo da semana'
                      : 'Resumo do mes',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tituloIntervalo(intervalo),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Km',
                        value: totalKm.toStringAsFixed(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Horas',
                        value: totalHoras.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Ganhos',
                        value: _currency.format(totalGanhos),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Despesas',
                        value: _currency.format(totalDespesas),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lista detalhada',
            style: CustomTheme.darkTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (detalhes.isEmpty)
            const _RelatorioVazio()
          else
            ...detalhes.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DetalheCard(
                      label: _dayFormat.format(item.dia),
                      ganhos: _currency.format(item.ganhos),
                      despesas: _currency.format(item.despesas),
                      km: '${item.km.toStringAsFixed(1)} km',
                      horas: '${item.horas.toStringAsFixed(1)} h',
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  DateTimeRange _intervaloAtual() {
    final now = DateTime.now();
    if (_periodo == _PeriodoRelatorio.mes) {
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1);
      return DateTimeRange(start: start, end: end);
    }

    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return DateTimeRange(start: start, end: end);
  }

  String _tituloIntervalo(DateTimeRange intervalo) {
    final formatter = DateFormat('dd/MM');
    final end = intervalo.end.subtract(const Duration(days: 1));
    return '${formatter.format(intervalo.start)} a ${formatter.format(end)}';
  }

  List<_DetalheRelatorio> _buildDetalhes(
    List<Jornada> jornadasPeriodo,
    List<Ganho> ganhos,
    List<Despesa> despesas,
  ) {
    final Map<DateTime, _DetalheRelatorio> detalhes = {};

    for (final jornada in jornadasPeriodo) {
      final dia = DateTime(
        jornada.inicio.year,
        jornada.inicio.month,
        jornada.inicio.day,
      );
      final detalhe = detalhes.putIfAbsent(
        dia,
        () => _DetalheRelatorio(dia: dia),
      );

      final fim = jornada.fim ?? DateTime.now();
      final horas = fim.difference(jornada.inicio).inMinutes / 60;
      detalhe.km += jornada.kmRodados ?? 0;
      detalhe._inicios.add(jornada.inicio);
      detalhe._fins.add(fim);

      final jornadaGanhos = ganhos.where((ganho) => ganho.jornadaId == jornada.id);
      final jornadaDespesas =
          despesas.where((despesa) => despesa.jornadaId == jornada.id);

      detalhe.ganhos +=
          jornadaGanhos.fold<double>(0, (sum, ganho) => sum + ganho.valor);
      detalhe.despesas +=
          jornadaDespesas.fold<double>(0, (sum, despesa) => sum + despesa.valor);
      detalhe.horas = horas > 0 ? detalhe._calcularHorasJanela() : detalhe.horas;
    }

    final lista = detalhes.values.toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    return lista;
  }
}

class _PeriodoSwitcher extends StatelessWidget {
  const _PeriodoSwitcher({
    required this.periodo,
    required this.onChanged,
  });

  final _PeriodoRelatorio periodo;
  final ValueChanged<_PeriodoRelatorio> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Semana'),
            selected: periodo == _PeriodoRelatorio.semana,
            onSelected: (_) => onChanged(_PeriodoRelatorio.semana),
            selectedColor: Colors.lightBlueAccent,
            labelStyle: TextStyle(
              color: periodo == _PeriodoRelatorio.semana
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Mes'),
            selected: periodo == _PeriodoRelatorio.mes,
            onSelected: (_) => onChanged(_PeriodoRelatorio.mes),
            selectedColor: Colors.lightBlueAccent,
            labelStyle: TextStyle(
              color:
                  periodo == _PeriodoRelatorio.mes ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumoMiniCard extends StatelessWidget {
  const _ResumoMiniCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheCard extends StatelessWidget {
  const _DetalheCard({
    required this.label,
    required this.ganhos,
    required this.despesas,
    required this.km,
    required this.horas,
  });

  final String label;
  final String ganhos;
  final String despesas;
  final String km;
  final String horas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipInfo(label: 'Km', value: km, color: Colors.lightBlueAccent),
              _ChipInfo(label: 'Horas', value: horas, color: Colors.blueGrey),
              _ChipInfo(label: 'Ganhos', value: ganhos, color: Colors.greenAccent),
              _ChipInfo(
                label: 'Despesas',
                value: despesas,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RelatorioVazio extends StatelessWidget {
  const _RelatorioVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 42, color: Colors.lightBlueAccent),
          const SizedBox(height: 12),
          Text(
            'Sem dados no periodo',
            style: CustomTheme.darkTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'As jornadas fechadas vao aparecer aqui em formato de relatorio.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetalheRelatorio {
  _DetalheRelatorio({required this.dia});

  final DateTime dia;
  double km = 0;
  double horas = 0;
  double ganhos = 0;
  double despesas = 0;
  final List<DateTime> _inicios = [];
  final List<DateTime> _fins = [];

  double _calcularHorasJanela() {
    if (_inicios.isEmpty || _fins.isEmpty) {
      return 0;
    }
    final inicio = _inicios.reduce((a, b) => a.isBefore(b) ? a : b);
    final fim = _fins.reduce((a, b) => a.isAfter(b) ? a : b);
    final duration = fim.difference(inicio).inMinutes / 60;
    return duration.isNegative ? 0 : duration;
  }
}
