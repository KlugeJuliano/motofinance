import 'package:flutter_test/flutter_test.dart';
import 'package:motofinance/core/database/database_helper.dart';
import 'package:motofinance/models/ganho_model.dart';
import 'package:motofinance/repositories/ganho_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Ganhos repository', () {
    late Database db;
    late GanhoRepository repository;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await DatabaseHelper.getDatabase(inMemory: true);
      repository = GanhoRepository(db);
      await db.insert('jornadas', {
        'inicio': DateTime(2025, 1, 1, 8, 0).toIso8601String(),
        'km_inicial': 1000.0,
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('deve inserir um ganho corretamente', () async {
      final ganho = await repository.inserirGanho(
        Ganho(
          id: null,
          descricao: 'Frete',
          valor: 50.0,
          jornadaId: 1,
        ),
      );

      expect(ganho.descricao, 'Frete');
      expect(ganho.valor, 50.0);
      expect(ganho.jornadaId, 1);
      expect(ganho.id, isNotNull);
    });

    test('deve listar ganhos persistidos', () async {
      await repository.inserirGanho(
        Ganho(
          id: null,
          descricao: 'Entrega',
          valor: 35.0,
          jornadaId: 1,
        ),
      );

      final ganhos = await repository.listarGanhos();

      expect(ganhos, hasLength(1));
      expect(ganhos.first.descricao, 'Entrega');
    });

    test('deve salvar ganho principal da jornada', () async {
      await repository.salvarGanhoPrincipal(jornadaId: 1, valor: 180.0);

      final ganhos = await repository.listarGanhos();

      expect(ganhos, hasLength(1));
      expect(ganhos.first.tipo, 'principal');
      expect(ganhos.first.valor, 180.0);
    });
  });
}
