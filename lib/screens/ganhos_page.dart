import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

class GanhosPage extends StatefulWidget {
  const GanhosPage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<GanhosPage> createState() => _GanhosPageState();
}

class _GanhosPageState extends State<GanhosPage> {
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
    Future.microtask(() async {
      await jornadaProvider.carregarJornadas();
      await ganhoProvider.carregarGanhos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jornadaProvider = context.watch<JornadaProvider>();
    final ganhoProvider = context.watch<GanhoProvider>();
    final ganhosExtras = ganhoProvider.ganhosExtras;
    final totalExtras = ganhoProvider.totalGanhosExtras;

    return Scaffold(
      backgroundColor: CustomTheme.background,
      appBar: AppBar(
        title: const Text('Ganhos extras'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: CustomTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CustomTheme.success,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Entradas extras',
                  style: TextStyle(
                    color: CustomTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency.format(totalExtras),
                  style: const TextStyle(
                    color: CustomTheme.success,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use esta tela para bonus, taxa extra, caixinha ou qualquer valor fora do ganho principal do dia.',
                  style: TextStyle(
                    color: CustomTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (ganhosExtras.isEmpty)
            const _SimpleEmptyState(
              icon: Icons.attach_money,
              title: 'Sem ganhos extras',
              subtitle: 'Adicione somente valores extras do periodo.',
            )
          else
            ...ganhosExtras.map(
              (ganho) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GanhoTile(
                  ganho: ganho,
                  currency: _currency,
                  onDelete: () =>
                      context.read<GanhoProvider>().removerGanho(ganho.id!),
                ),
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CustomTheme.success,
        foregroundColor: Colors.black,
        onPressed: () => _abrirFormulario(context, jornadaProvider),
        label: const Text('Adicionar extra'),
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
      _showMessage('Inicie uma jornada para registrar um ganho extra');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final descricaoController = TextEditingController();
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
                  'Novo ganho extra',
                  style: CustomTheme.darkTheme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Exemplo: bonus, taxa de entrega ou caixinha.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descricaoController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration('Descricao'),
                  validator: (value) {
                    if ((value ?? '').trim().length < 3) {
                      return 'Descreva melhor esse ganho';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valorController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration('Valor'),
                  validator: (value) {
                    final valor =
                        double.tryParse((value ?? '').replaceAll(',', '.'));
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
                      backgroundColor: CustomTheme.success,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final valor = double.parse(
                          valorController.text.replaceAll(',', '.'));
                      await context.read<GanhoProvider>().adicionarGanho(
                            Ganho(
                              id: null,
                              jornadaId: jornada!.id!,
                              valor: valor,
                              descricao: descricaoController.text.trim(),
                              tipo: 'extra',
                            ),
                          );
                      if (context.mounted) {
                        Navigator.of(sheetContext).pop();
                        _showMessage('Ganho extra salvo');
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
      fillColor: CustomTheme.elevatedSurface,
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
        borderSide: const BorderSide(color: CustomTheme.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CustomTheme.success, width: 2),
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
        borderSide: const BorderSide(color: CustomTheme.border),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _GanhoTile extends StatelessWidget {
  const _GanhoTile({
    required this.ganho,
    required this.currency,
    required this.onDelete,
  });

  final Ganho ganho;
  final NumberFormat currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          ganho.descricao,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Segure para excluir',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          currency.format(ganho.valor),
          style: const TextStyle(
            color: CustomTheme.success,
            fontWeight: FontWeight.w800,
          ),
        ),
        onLongPress: onDelete,
      ),
    );
  }
}

class _SimpleEmptyState extends StatelessWidget {
  const _SimpleEmptyState({
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
        color: CustomTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CustomTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: CustomTheme.success),
          const SizedBox(height: 12),
          Text(title, style: CustomTheme.darkTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
