import 'package:flutter/foundation.dart';
import 'package:motofinance/models/jornada_model.dart';

import '../repositories/jornada_repository.dart';

class JornadaProvider with ChangeNotifier {
  final JornadaRepository repository;

  JornadaProvider(this.repository);

  List<Jornada> _jornadas = [];

  List<Jornada> get jornadas => _jornadas;
  Jornada? get jornadaAberta {
    for (final jornada in _jornadas) {
      if (jornada.fim == null) {
        return jornada;
      }
    }
    return null;
  }

  Jornada? get jornadaAtualOuUltimaDoDia {
    final aberta = jornadaAberta;
    if (aberta != null) {
      return aberta;
    }

    final now = DateTime.now();
    for (final jornada in _jornadas) {
      if (jornada.inicio.year == now.year &&
          jornada.inicio.month == now.month &&
          jornada.inicio.day == now.day) {
        return jornada;
      }
    }
    return null;
  }

  Future<void> carregarJornadas() async {
    _jornadas = await repository.listarJornadas();
    notifyListeners();
  }

  Future<void> iniciarJornada(double kmInicial) async {
    if (jornadaAberta != null) {
      throw Exception('Ja existe uma jornada aberta');
    }
    final jornada =
        Jornada(inicio: DateTime.now(), kmInicial: kmInicial, fim: null);
    await repository.inserirJornada(jornada);
    await carregarJornadas();
  }

  Future<void> finalizarJornada(int id, double kmFinal) async {
    await repository.finalizar(id, kmFinal);
    await carregarJornadas();
  }

  Future<void> limparBanco() async {
    await repository.limparBanco();
    _jornadas = [];
    notifyListeners();
  }
}
