import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/services/finance_metrics_service.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

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
  final FinanceMetricsService _metricsService = const FinanceMetricsService();
  ReportPeriod _periodo = ReportPeriod.semana;

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
    final report = _metricsService.buildReportSummary(
      period: _periodo,
      jornadas: jornadas,
      ganhos: ganhos,
      despesas: despesas,
    );

    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Relatorios'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Zerar dados',
            onPressed: () => _confirmarLimpeza(context),
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
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
                  _periodo == ReportPeriod.semana
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
                  _tituloIntervalo(report.interval),
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
                        value: report.totalKm.toStringAsFixed(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Horas',
                        value: report.totalHours.toStringAsFixed(1),
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
                        value: _currency.format(report.totalGains),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResumoMiniCard(
                        title: 'Despesas',
                        value: _currency.format(report.totalExpenses),
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
          if (report.details.isEmpty)
            const _RelatorioVazio()
          else
            ...report.details.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DetalheCard(
                      label: _dayFormat.format(item.day),
                      ganhos: _currency.format(item.gains),
                      despesas: _currency.format(item.expenses),
                      km: '${item.km.toStringAsFixed(1)} km',
                      horas: '${item.hours.toStringAsFixed(1)} h',
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _tituloIntervalo(DateInterval intervalo) {
    final formatter = DateFormat('dd/MM');
    final end = intervalo.end.subtract(const Duration(days: 1));
    return '${formatter.format(intervalo.start)} a ${formatter.format(end)}';
  }

  Future<void> _confirmarLimpeza(BuildContext context) async {
    final jornadaProvider = context.read<JornadaProvider>();
    final ganhoProvider = context.read<GanhoProvider>();
    final despesaProvider = context.read<DespesaProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Zerar dados do app?'),
          content: const Text(
            'Essa acao apaga jornadas, ganhos e despesas salvos no aparelho. Essa operacao nao pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Apagar tudo'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !context.mounted) {
      return;
    }

    await jornadaProvider.limparBanco();
    await ganhoProvider.carregarGanhos();
    await despesaProvider.carregarDespesas();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos os dados foram removidos do banco local.'),
      ),
    );
  }
}

class _PeriodoSwitcher extends StatelessWidget {
  const _PeriodoSwitcher({
    required this.periodo,
    required this.onChanged,
  });

  final ReportPeriod periodo;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final chipBackground = const Color(0xFF1A1F2B);
    final chipSelected = const Color(0xFF8BE9FD);

    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Semana'),
            selected: periodo == ReportPeriod.semana,
            onSelected: (_) => onChanged(ReportPeriod.semana),
            backgroundColor: chipBackground,
            selectedColor: chipSelected,
            side: BorderSide(
              color: periodo == ReportPeriod.semana
                  ? chipSelected
                  : Colors.white24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelStyle: TextStyle(
              color: periodo == ReportPeriod.semana
                  ? Colors.black
                  : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Mes'),
            selected: periodo == ReportPeriod.mes,
            onSelected: (_) => onChanged(ReportPeriod.mes),
            backgroundColor: chipBackground,
            selectedColor: chipSelected,
            side: BorderSide(
              color: periodo == ReportPeriod.mes
                  ? chipSelected
                  : Colors.white24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelStyle: TextStyle(
              color:
                  periodo == ReportPeriod.mes ? Colors.black : Colors.white70,
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
