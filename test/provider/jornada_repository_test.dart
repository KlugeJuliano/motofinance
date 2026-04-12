import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:motofinance/core/database/database_helper.dart';
import 'package:motofinance/repositories/jornada_repository.dart';
import 'package:motofinance/models/jornada_model.dart';

void main() {
  group("JornadaRepository", () {
    late Database db;
    late JornadaRepository jornadaRepository;
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });
    setUp(() async {
      db = await DatabaseHelper.getDatabase(inMemory: true);
      jornadaRepository = JornadaRepository(db);
    });
    tearDown(() async {
      await db.close();
    });

    test("deve listar jornadas corretamente", () async {
      await jornadaRepository.inserirJornada(Jornada(
          inicio: DateTime(2025, 1, 1, 18, 0),
          fim: DateTime(2025, 1, 1, 18, 0),
          kmInicial: 1000.0));
      final jornadas = await jornadaRepository.listarJornadas();

      expect(jornadas.length, 1);
      expect(jornadas[0].inicio, DateTime(2025, 1, 1, 18, 0));
      expect(jornadas[0].kmInicial, 1000.0);
    });

    test('deve inserir uma jornada corretamente', () async {
      final jornada = Jornada(
          inicio: DateTime(2025, 1, 1, 1, 8, 0),
          kmInicial: 1000.0,
          fim: DateTime(2025, 1, 1, 18, 0));

      await jornadaRepository.inserirJornada(jornada);

      final result = await jornadaRepository.listarJornadas();
      expect(result.length, 1);
      expect(result.first.inicio, jornada.inicio);
      expect(result.first.kmInicial, jornada.kmInicial);
    });

    test('deve finalizar uma jornada corretamente', () async {
      final jornadaId = await db.insert('jornadas', {
        "inicio": DateTime(2025, 1, 1, 8, 0).toIso8601String(),
        "km_inicial": 1000.0,
      });
      await jornadaRepository.finalizar(jornadaId, 1100.0);
      final result =
          await db.query('jornadas', where: 'id = ?', whereArgs: [jornadaId]);
      expect(result.length, 1);
      expect(result.first['fim'], isNotNull);
      expect(result.first['km_rodados'], 100.0);
      expect(result.first['km_final'], 1100.0);
    });

    test('deve limpar todas as tabelas do banco', () async {
      final jornadaId = await db.insert('jornadas', {
        "inicio": DateTime(2025, 1, 1, 8, 0).toIso8601String(),
        "km_inicial": 1000.0,
      });
      await db.insert('ganhos', {
        'jornada_id': jornadaId,
        'valor': 100.0,
        'descricao': 'Teste',
        'tipo': 'principal',
      });
      await db.insert('despesas', {
        'jornada_id': jornadaId,
        'valor': 25.0,
        'categoria': 'Combustivel',
      });

      await jornadaRepository.limparBanco();

      expect(await db.query('jornadas'), isEmpty);
      expect(await db.query('ganhos'), isEmpty);
      expect(await db.query('despesas'), isEmpty);
    });

/*  test('deve lançar erro ao finalizar jornada inexistente', ()async{

    expect(
          () async => await jornadaRepository.finalizar(999, 1100.0),
      throwsA(isA<Exception>()),
    );
  });*/
  });
}
