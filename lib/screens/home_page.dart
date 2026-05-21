import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/services/finance_metrics_service.dart';
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
  final FinanceMetricsService _metricsService = const FinanceMetricsService();

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
    final summary = _metricsService.buildDashboardSummary(
      jornadas: jornadas,
      ganhos: ganhos,
      despesas: despesas,
    );

    return Scaffold(
      backgroundColor: CustomTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Painel do dia',
              style: CustomTheme.darkTheme.textTheme.bodyMedium,
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(summary.referenceDate),
              style: const TextStyle(
                fontSize: 13,
                color: CustomTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
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
            decoration: CustomTheme.cardDecoration(
              color: CustomTheme.elevatedSurface,
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0x2457C7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    size: 38,
                    color: CustomTheme.primary,
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
                          color: CustomTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary.jornadaAberta == null
                            ? 'Sem jornada aberta neste momento'
                            : 'Jornada aberta desde ${DateFormat('HH:mm').format(summary.jornadaAberta!.inicio)}',
                        style: const TextStyle(
                          color: CustomTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${summary.kmRodadosHoje.toStringAsFixed(1)} km rodados hoje',
                        style: const TextStyle(
                          color: CustomTheme.primary,
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
            value: _currency.format(summary.saldoHoje),
            color: summary.saldoHoje >= 0
                ? CustomTheme.success
                : CustomTheme.danger,
            subtitle:
                'Bruto ${_currency.format(summary.ganhosHoje)}  |  Despesas ${_currency.format(summary.despesasHoje)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Ganho por km',
                  value: _currency.format(summary.ganhoPorKm),
                  color: CustomTheme.success,
                  subtitle:
                      '${summary.kmRodadosHoje.toStringAsFixed(1)} km no dia',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Ganho por hora',
                  value: _currency.format(summary.ganhoPorHora),
                  color: CustomTheme.primary,
                  subtitle:
                      '${summary.horasTrabalhadasHoje.toStringAsFixed(1)} h do primeiro inicio ao ultimo encerramento',
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
          if (summary.jornadasHoje.isEmpty)
            const _HomeEmptyState()
          else
            ...summary.jornadasHoje.take(3).map(
                  (jornada) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: CustomTheme.cardDecoration(),
                      child: Row(
                        children: [
                          Icon(
                            jornada.fim == null
                                ? Icons.timelapse
                                : Icons.check_circle,
                            color: jornada.fim == null
                                ? CustomTheme.warning
                                : CustomTheme.success,
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
      decoration: CustomTheme.cardDecoration(
        color: CustomTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: CustomTheme.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: CustomTheme.textSecondary,
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
      decoration: CustomTheme.cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.route, size: 42, color: CustomTheme.primary),
          const SizedBox(height: 12),
          Text('Nenhum dado hoje',
              style: CustomTheme.darkTheme.textTheme.bodyMedium),
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
