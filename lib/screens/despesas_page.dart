import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/models/despesa_model.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

class SpendingPage extends StatefulWidget {
  const SpendingPage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<SpendingPage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<SpendingPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

  @override
  void initState() {
    super.initState();
    if (!widget.loadData) {
      return;
    }
    final jornadaProvider = context.read<JornadaProvider>();
    final despesaProvider = context.read<DespesaProvider>();
    Future.microtask(() async {
      await jornadaProvider.carregarJornadas();
      await despesaProvider.carregarDespesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jornadaProvider = context.watch<JornadaProvider>();
    final despesas = context.watch<DespesaProvider>().despesas;
    final totalDespesas = despesas.fold<double>(
      0,
      (total, despesa) => total + despesa.valor,
    );

    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Despesas'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Despesas do periodo',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency.format(totalDespesas),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Exemplo: gasolina, refeicao, estacionamento ou manutencao.',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (despesas.isEmpty)
            const _EmptyState(
              icon: Icons.money_off,
              title: 'Sem despesas lancadas',
              subtitle: 'Registre apenas o valor e a categoria.',
            )
          else
            ...despesas.map(
                  (despesa) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DespesaTile(
                      despesa: despesa,
                      currency: _currency,
                      onDelete: () => context
                          .read<DespesaProvider>()
                          .excluirDespesa(despesa.id!),
                    ),
                  ),
                ),
          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        onPressed: () => _abrirFormulario(context, jornadaProvider),
        label: const Text('Adicionar despesa'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context,
    JornadaProvider jornadaProvider,
  ) async {
    final jornada = jornadaProvider.jornadaAtualOuUltimaDoDia;
    if (jornada?.id == null) {
      _showMessage('Inicie uma jornada para registrar despesas');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final categoriaController = TextEditingController();
    final valorController = TextEditingController();

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
                  'Nova despesa',
                  style: CustomTheme.darkTheme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Nao precisa informar corrida ou jornada.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoriaController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration('Categoria'),
                  validator: (value) {
                    if ((value ?? '').trim().length < 3) {
                      return 'Informe a categoria da despesa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration('Valor'),
                  validator: (value) {
                    final valor = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (valor == null) {
                      return 'Informe um valor valido';
                    }
                    if (valor <= 0) {
                      return 'O valor deve ser maior que zero';
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
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final valor =
                          double.parse(valorController.text.replaceAll(',', '.'));
                      await context.read<DespesaProvider>().inserirDespesa(
                            Despesa(
                              id: null,
                              jornadaId: jornada!.id!,
                              valor: valor,
                              categoria: categoriaController.text.trim(),
                            ),
                          );
                      if (context.mounted) {
                        Navigator.of(sheetContext).pop();
                        _showMessage('Despesa salva');
                      }
                    },
                    child: const Text('Salvar'),
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
      fillColor: Colors.white12,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DespesaTile extends StatelessWidget {
  const _DespesaTile({
    required this.despesa,
    required this.currency,
    required this.onDelete,
  });

  final Despesa despesa;
  final NumberFormat currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(despesa.categoria),
        subtitle: const Text('Segure para excluir'),
        trailing: Text(
          currency.format(despesa.valor),
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
        onLongPress: onDelete,
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
          Icon(icon, size: 42, color: Colors.orangeAccent),
          const SizedBox(height: 12),
          Text(title, style: CustomTheme.darkTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
