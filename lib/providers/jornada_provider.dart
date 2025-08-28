import 'package:flutter/foundation.dart';
import 'package:motofinance/models/jornada_model.dart';

import '../repositories/jornada_repository.dart';

class JornadaProvider with ChangeNotifier {
  final JornadaRepository repository;

  JornadaProvider(this.repository);

  List<Jornada> _jornadas = [];

  List<Jornada> get jornadas => _jornadas;

  Future<void> carregarJornadas() async {
    _jornadas = await repository.listarJornadas();
    notifyListeners();
  }

  Future<void> iniciarJornada(double kmInicial) async {
    final jornada =
        Jornada(inicio: DateTime.now(), kmInicial: kmInicial, fim: null);
    await repository.inserirJornada(jornada);
    await carregarJornadas();
  }

  Future<void> finalizarJornada(int id, double kmFinal) async {
    await repository.finalizar(id, kmFinal);
    await carregarJornadas();
  }
}
