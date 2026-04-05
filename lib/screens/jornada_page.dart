import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

class JornadaPage extends StatefulWidget {
  const JornadaPage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<JornadaPage> createState() => _JornadaPageState();
}

class _JornadaPageState extends State<JornadaPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    if (!widget.loadData) {
      return;
    }
    final jornadaProvider = context.read<JornadaProvider>();
    Future.microtask(jornadaProvider.carregarJornadas);
  }

  @override
  Widget build(BuildContext context) {
    final jornadaProvider = context.watch<JornadaProvider>();
    final jornadas = jornadaProvider.jornadas;
    final jornadaAberta = jornadaProvider.jornadaAberta;

    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Jornada'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(jornadaAberta: jornadaAberta, timeFormat: _timeFormat),
          const SizedBox(height: 16),
          Text(
            'Historico de hoje',
            style: CustomTheme.darkTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (jornadas.isEmpty)
            _EmptyState(
              icon: Icons.two_wheeler,
              title: 'Nenhuma jornada iniciada',
              subtitle: 'Toque no botao abaixo quando comecar a rodar.',
            )
          else
            ...jornadas.take(8).map(
                  (jornada) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JornadaTile(
                      jornada: jornada,
                      timeFormat: _timeFormat,
                      onFinish: jornada.fim == null
                          ? () => _abrirFinalizacao(context, jornada)
                          : null,
                    ),
                  ),
                ),
          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: jornadaAberta == null ? Colors.lightBlueAccent : Colors.orangeAccent,
        foregroundColor: Colors.black,
        onPressed: () {
          if (jornadaAberta == null) {
            _abrirInicio(context);
            return;
          }
          _abrirFinalizacao(context, jornadaAberta);
        },
        icon: Icon(jornadaAberta == null ? Icons.play_arrow : Icons.stop_circle_outlined),
        label: Text(jornadaAberta == null ? 'Iniciar jornada' : 'Fechar jornada'),
      ),
    );
  }

  Future<void> _abrirInicio(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final kmController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comecar agora',
                  style: CustomTheme.darkTheme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Informe a kilometragem atual da moto.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kmController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(fontSize: 20),
                  decoration: _inputDecoration('Km inicial'),
                  validator: (value) {
                    final km = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (km == null) {
                      return 'Informe um valor valido';
                    }
                    if (km < 0) {
                      return 'O km nao pode ser negativo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final kmInicial =
                          double.parse(kmController.text.replaceAll(',', '.'));
                      try {
                        await context.read<JornadaProvider>().iniciarJornada(kmInicial);
                        if (context.mounted) {
                          Navigator.of(sheetContext).pop();
                          _showMessage('Jornada iniciada');
                        }
                      } catch (error) {
                        _showMessage(error.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                    child: const Text('Iniciar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirFinalizacao(BuildContext context, Jornada jornada) async {
    final formKey = GlobalKey<FormState>();
    final kmController = TextEditingController();
    final ganhoController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fechar jornada',
                  style: CustomTheme.darkTheme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Confirme o km final e o ganho total do dia.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kmController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(fontSize: 20),
                  decoration: _inputDecoration('Km final'),
                  validator: (value) {
                    final km = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (km == null) {
                      return 'Informe um valor valido';
                    }
                    if (km < jornada.kmInicial) {
                      return 'O km final deve ser maior que o inicial';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ganhoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20),
                  decoration: _inputDecoration('Ganho total do dia'),
                  validator: (value) {
                    final ganho = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (ganho == null) {
                      return 'Informe um valor valido';
                    }
                    if (ganho < 0) {
                      return 'O ganho nao pode ser negativo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate() || jornada.id == null) {
                        return;
                      }
                      final jornadaProvider = context.read<JornadaProvider>();
                      final ganhoProvider = context.read<GanhoProvider>();
                      final kmFinal =
                          double.parse(kmController.text.replaceAll(',', '.'));
                      final ganhoTotal =
                          double.parse(ganhoController.text.replaceAll(',', '.'));
                      await jornadaProvider.finalizarJornada(jornada.id!, kmFinal);
                      await ganhoProvider.salvarGanhoPrincipal(
                            jornadaId: jornada.id!,
                            valor: ganhoTotal,
                          );
                      if (context.mounted) {
                        Navigator.of(sheetContext).pop();
                        _showMessage(
                          'Jornada fechada com ${_currency.format(ganhoTotal)}',
                        );
                      }
                    },
                    child: const Text('Fechar jornada'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.jornadaAberta,
    required this.timeFormat,
  });

  final Jornada? jornadaAberta;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        jornadaAberta == null ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jornadaAberta == null ? 'Sem jornada aberta' : 'Rodando agora',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            jornadaAberta == null
                ? 'Quando sair para trabalhar, toque em iniciar jornada.'
                : 'Inicio as ${timeFormat.format(jornadaAberta!.inicio)}  |  Km inicial ${jornadaAberta!.kmInicial.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JornadaTile extends StatelessWidget {
  const _JornadaTile({
    required this.jornada,
    required this.timeFormat,
    this.onFinish,
  });

  final Jornada jornada;
  final DateFormat timeFormat;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          jornada.fim == null
              ? 'Jornada em andamento'
              : 'Jornada encerrada',
        ),
        subtitle: Text(
          jornada.fim == null
              ? 'Inicio ${timeFormat.format(jornada.inicio)}  |  Km ${jornada.kmInicial.toStringAsFixed(1)}'
              : 'Inicio ${timeFormat.format(jornada.inicio)}  |  ${jornada.kmRodados?.toStringAsFixed(1) ?? '0.0'} km',
        ),
        trailing: onFinish == null
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : FilledButton(
                onPressed: onFinish,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Fechar'),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
          Icon(icon, size: 42, color: Colors.lightBlueAccent),
          const SizedBox(height: 12),
          Text(title, style: CustomTheme.darkTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
