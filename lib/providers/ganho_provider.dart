import 'package:flutter/material.dart';

import '../models/ganho_model.dart';
import '../repositories/ganho_repository.dart';

class GanhoProvider with ChangeNotifier {
  GanhoProvider(this.repository);

  final GanhoRepository repository;

  List<Ganho> _ganhos = [];
  List<Ganho> get ganhos => _ganhos;
  List<Ganho> get ganhosExtras =>
      _ganhos.where((ganho) => ganho.tipo == 'extra').toList();
  List<Ganho> get ganhosPrincipais =>
      _ganhos.where((ganho) => ganho.tipo == 'principal').toList();
  double get totalGanhosExtras =>
      ganhosExtras.fold<double>(0, (total, ganho) => total + ganho.valor);

  Future<void> carregarGanhos() async {
    _ganhos = await repository.listarGanhos();
    notifyListeners();
  }

  Future<void> adicionarGanho(Ganho ganho) async {
    await repository.inserirGanho(ganho);
    await carregarGanhos();
  }

  Future<void> removerGanho(int id) async {
    await repository.excluirGanho(id);
    await carregarGanhos();
  }

  Future<void> atualizarGanho(Ganho ganho) async {
    await repository.editarGanho(ganho);
    await carregarGanhos();
  }

  Future<void> salvarGanhoPrincipal({
    required int jornadaId,
    required double valor,
  }) async {
    await repository.salvarGanhoPrincipal(jornadaId: jornadaId, valor: valor);
    await carregarGanhos();
  }
}
