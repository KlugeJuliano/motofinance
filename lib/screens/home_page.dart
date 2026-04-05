import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

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
    final jornadasHoje = _jornadasDoDia(jornadas).toList();
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
    final jornadaAberta = context.watch<JornadaProvider>().jornadaAberta;
    final horasTrabalhadasHoje = _horasTrabalhadas(jornadasHoje);
    final ganhoPorKm = kmRodadosHoje > 0 ? saldoHoje / kmRodadosHoje : 0.0;
    final ganhoPorHora =
        horasTrabalhadasHoje > 0 ? saldoHoje / horasTrabalhadasHoje : 0.0;

    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Painel do dia',
              style: CustomTheme.darkTheme.textTheme.bodyMedium,
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    size: 38,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo rapido',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        jornadaAberta == null
                            ? 'Sem jornada aberta neste momento'
                            : 'Jornada aberta desde ${DateFormat('HH:mm').format(jornadaAberta.inicio)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${kmRodadosHoje.toStringAsFixed(1)} km rodados hoje',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MetricCard(
            title: 'Ganho liquido',
            value: _currency.format(saldoHoje),
            color: saldoHoje >= 0 ? Colors.greenAccent : Colors.redAccent,
            subtitle:
                'Bruto ${_currency.format(ganhosHoje)}  |  Despesas ${_currency.format(despesasHoje)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Ganho por km',
                  value: _currency.format(ganhoPorKm),
                  color: Colors.greenAccent,
                  subtitle: '${kmRodadosHoje.toStringAsFixed(1)} km no dia',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Ganho por hora',
                  value: _currency.format(ganhoPorHora),
                  color: Colors.lightBlueAccent,
                  subtitle:
                      '${horasTrabalhadasHoje.toStringAsFixed(1)} h do primeiro inicio ao ultimo encerramento',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hoje',
            style: CustomTheme.darkTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (jornadasHoje.isEmpty)
            const _HomeEmptyState()
          else
            ...jornadasHoje.take(3).map(
                  (jornada) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            jornada.fim == null
                                ? Icons.timelapse
                                : Icons.check_circle,
                            color: jornada.fim == null
                                ? Colors.orangeAccent
                                : Colors.greenAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              jornada.fim == null
                                  ? 'Jornada aberta  |  Km inicial ${jornada.kmInicial.toStringAsFixed(1)}'
                                  : 'Jornada fechada  |  ${(jornada.kmRodados ?? 0).toStringAsFixed(1)} km rodados',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Iterable<Jornada> _jornadasDoDia(List<Jornada> jornadas) {
    final now = DateTime.now();
    return jornadas.where(
      (jornada) =>
          jornada.inicio.year == now.year &&
          jornada.inicio.month == now.month &&
          jornada.inicio.day == now.day,
    );
  }

  double _horasTrabalhadas(List<Jornada> jornadasHoje) {
    if (jornadasHoje.isEmpty) {
      return 0;
    }

    final inicio = jornadasHoje
        .map((jornada) => jornada.inicio)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final fim = jornadasHoje
        .map((jornada) => jornada.fim ?? DateTime.now())
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final duration = fim.difference(inicio).inMinutes / 60;
    return duration.isNegative ? 0 : duration;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final String value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

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
          const Icon(Icons.route, size: 42, color: Colors.lightBlueAccent),
          const SizedBox(height: 12),
          Text('Nenhum dado hoje', style: CustomTheme.darkTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          const Text(
            'Comece uma jornada para acompanhar ganhos, despesas e saldo do dia.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
