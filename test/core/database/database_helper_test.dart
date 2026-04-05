import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:motofinance/core/database/database_helper.dart';

void main() {
  group("DatabaseHelper", () {
    late Database db;

    setUpAll(() {
      // Inicializa sqflite_common_ffi uma vez para todos os testes
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await DatabaseHelper.getDatabase(inMemory: true);
    });

    tearDown(() async {
      await db.close();
    });

    test("deve habilitar chaves estrangeiras", () async {
      final result = await db.rawQuery('PRAGMA foreign_keys;');
      expect(result.first['foreign_keys'], 1);
    });
    test("deve impedir inserção em ganhos sem jornada_id válido", () async {
      // Insere uma jornada válida
      final jornadaId = await db.insert("jornadas", {
        "inicio": DateTime(2025, 1, 1, 8, 0).toIso8601String(),
        "fim": DateTime(2025, 1, 1, 18, 0).toIso8601String(),
        "km_inicial": 1000.0,
        "km_final": 1100.0,
        "km_rodados": 100.0,
      });

      // Tenta inserir com um jornada_id inválido
      expect(
        () async => await db.insert("ganhos", {
          "jornada_id": 999,
          "valor": 100.0,
          "descricao": "Teste",
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Verifica inserção válida
      final validInsert = await db.insert("ganhos", {
        "jornada_id": jornadaId,
        "valor": 100.0,
        "descricao": "Teste válido",
      });
      expect(validInsert, 1);
    });

    test("deve criar as tabelas jornadas, ganhos e despesas", () async {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
      final nomesTabelas = tables
          .map((t) => t['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      expect(nomesTabelas, containsAll(["jornadas", "ganhos", "despesas"]));
    });

    test("deve verificar o esquema da tabela jornadas", () async {
      final schema = await db.rawQuery("PRAGMA table_info(jornadas)");
      final columnNames = schema.map((col) => col['name'] as String).toList();
      expect(
          columnNames,
          containsAll([
            "id",
            "descricao",
            "inicio",
            "fim",
            "km_inicial",
            "km_final",
            "km_rodados"
          ]));
    });

    test("deve inserir e recuperar uma jornada com km_final correto", () async {
      final inicio = DateTime(2025, 1, 1, 8, 0);
      await db.insert("jornadas", {
        "inicio": inicio.toIso8601String(),
        "fim": DateTime(2025, 1, 1, 18, 0).toIso8601String(),
        "km_inicial": 1000.0,
        "km_final": 1100.0,
        "km_rodados": 100.0,
      });

      final result = await db.query("jornadas");
      expect(result.length, 1);
      expect((result.first["km_final"] as num).toDouble(), 1100.0);
      expect(DateTime.parse(result.first["inicio"] as String), inicio);
    });

    test("deve criar categoria na tabela despesas", () async {
      final schema = await db.rawQuery("PRAGMA table_info(despesas)");
      final columnNames = schema.map((col) => col['name'] as String).toList();
      expect(columnNames, containsAll(["id", "jornada_id", "valor", "categoria"]));
    });

    test("deve criar tipo na tabela ganhos", () async {
      final schema = await db.rawQuery("PRAGMA table_info(ganhos)");
      final columnNames = schema.map((col) => col['name'] as String).toList();
      expect(
        columnNames,
        containsAll(["id", "jornada_id", "valor", "descricao", "tipo"]),
      );
    });

    test("deve lançar erro ao inserir km_final negativo", () async {
      expect(
        () async => await db.insert("jornadas", {
          "inicio": DateTime(2025, 1, 1, 8, 0).toIso8601String(),
          "fim": DateTime(2025, 1, 1, 18, 0).toIso8601String(),
          "km_inicial": 1000.0,
          "km_final": -1100.0,
          "km_rodados": -2100.0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
