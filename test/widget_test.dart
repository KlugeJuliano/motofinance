import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motofinance/models/despesa_model.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/repositories/despesa_repository.dart';
import 'package:motofinance/repositories/ganho_repository.dart';
import 'package:motofinance/repositories/jornada_repository.dart';
import 'package:motofinance/screens/home_page.dart';
import 'package:provider/provider.dart';

class FakeJornadaProvider extends ChangeNotifier implements JornadaProvider {
  @override
  final List<Jornada> jornadas;

  FakeJornadaProvider(this.jornadas);

  @override
  JornadaRepository get repository => throw UnimplementedError();

  @override
  Jornada? get jornadaAberta => null;

  @override
  Jornada? get jornadaAtualOuUltimaDoDia =>
      jornadas.isEmpty ? null : jornadas.first;

  @override
  Future<void> carregarJornadas() async {}

  @override
  Future<void> iniciarJornada(double kmInicial) async {}

  @override
  Future<void> finalizarJornada(int id, double kmFinal) async {}
}

class FakeGanhoProvider extends ChangeNotifier implements GanhoProvider {
  @override
  final List<Ganho> ganhos;

  FakeGanhoProvider(this.ganhos);

  @override
  GanhoRepository get repository => throw UnimplementedError();

  @override
  List<Ganho> get ganhosExtras =>
      ganhos.where((ganho) => ganho.tipo == 'extra').toList();

  @override
  List<Ganho> get ganhosPrincipais =>
      ganhos.where((ganho) => ganho.tipo == 'principal').toList();

  @override
  Future<void> carregarGanhos() async {}

  @override
  Future<void> adicionarGanho(Ganho ganho) async {}

  @override
  Future<void> removerGanho(int id) async {}

  @override
  Future<void> atualizarGanho(Ganho ganho) async {}

  @override
  Future<void> salvarGanhoPrincipal({
    required int jornadaId,
    required double valor,
  }) async {}
}

class FakeDespesaProvider extends ChangeNotifier implements DespesaProvider {
  @override
  final List<Despesa> despesas;

  FakeDespesaProvider(this.despesas);

  @override
  DespesaRepository get repository => throw UnimplementedError();

  @override
  Future<void> carregarDespesas() async {}

  @override
  Future<void> inserirDespesa(Despesa despesa) async {}

  @override
  Future<void> excluirDespesa(int id) async {}

  @override
  Future<void> atualizarDespesa(Despesa despesa) async {}
}

void main() {
  testWidgets('renderiza o resumo da home', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<JornadaProvider>(
            create: (_) => FakeJornadaProvider([
              Jornada(
                id: 1,
                inicio: DateTime.now(),
                fim: DateTime.now(),
                kmInicial: 100,
                kmFinal: 145,
                kmRodados: 45,
              ),
            ]),
          ),
          ChangeNotifierProvider<GanhoProvider>(
            create: (_) => FakeGanhoProvider([
              Ganho(
                id: 1,
                jornadaId: 1,
                valor: 120,
                descricao: 'Ganhos do dia',
                tipo: 'principal',
              ),
              Ganho(
                id: 2,
                jornadaId: 1,
                valor: 20,
                descricao: 'Bonus',
                tipo: 'extra',
              ),
            ]),
          ),
          ChangeNotifierProvider<DespesaProvider>(
            create: (_) => FakeDespesaProvider([
              Despesa(id: 1, jornadaId: 1, valor: 35, categoria: 'Combustivel'),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(loadData: false),
        ),
      ),
    );

    expect(find.text('Painel do dia'), findsOneWidget);
    expect(find.text('Ganho liquido'), findsOneWidget);
    expect(find.text('Ganho por km'), findsOneWidget);
    expect(find.text('Ganho por hora'), findsOneWidget);
  });
}
