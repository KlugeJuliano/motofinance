import 'package:flutter/material.dart';

import '../models/despesa_model.dart';
import '../repositories/despesa_repository.dart';

class DespesaProvider with ChangeNotifier {
  DespesaProvider(this.repository);

  final DespesaRepository repository;

  List<Despesa> _despesas = [];
  List<Despesa> get despesas => _despesas;
  double get totalDespesas =>
      _despesas.fold<double>(0, (total, despesa) => total + despesa.valor);

  Future<void> carregarDespesas() async {
    _despesas = await repository.listarDespesas();
    notifyListeners();
  }

  Future<void> inserirDespesa(Despesa despesa) async {
    await repository.inserirDespesa(despesa);
    await carregarDespesas();
  }

  Future<void> excluirDespesa(int id) async {
    await repository.excluirDespesa(id);
    await carregarDespesas();
  }

  Future<void> atualizarDespesa(Despesa despesa) async {
    await repository.editarDespesa(despesa);
    await carregarDespesas();
  }
}
