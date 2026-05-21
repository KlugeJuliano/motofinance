import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Exceção personalizada para erros do banco de dados
class DatabaseHelperException implements Exception {
  final String message;

  DatabaseHelperException(this.message);

  @override
  String toString() => 'DatabaseHelperException: $message';
}

class DatabaseHelper {
  static const _databaseName = 'motofinance.db';
  static const _databaseVersion = 3;

  static Database? _database;

  /// Completer usado para evitar inicialização concorrente do banco.
  static Completer<Database>? _completer;

  /// Singleton seguro contra acesso concorrente.
  /// Retorna a instância existente ou aguarda a inicialização em andamento.
  static Future<Database> get instance async {
    if (_database != null) return _database!;

    if (_completer != null) return _completer!.future;

    _completer = Completer<Database>();
    try {
      final db = await _openDatabase();
      _database = db;
      _completer!.complete(db);
    } catch (e) {
      _completer!.completeError(e);
      _completer = null;
      rethrow;
    }
    return _database!;
  }

  /// API explícita para testes e integrações locais.
  static Future<Database> getDatabase({
    bool inMemory = false,
    String? pathOverride,
  }) async {
    if (inMemory) {
      return openInMemoryDatabase();
    }

    if (pathOverride != null) {
      return _openDatabase(pathOverride: pathOverride);
    }

    return instance;
  }

  /// Abre o banco de dados em arquivo (produção).
  static Future<Database> _openDatabase({String? pathOverride}) async {
    try {
      final factory = _databaseFactory;
      final path =
          pathOverride ?? join(await getDatabasesPath(), _databaseName);

      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: (db, version) async {
            await _createTables(db);
          },
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON;');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await _migrateToV2(db);
            }
            if (oldVersion < 3) {
              await _migrateToV3(db);
            }
          },
        ),
      );
    } catch (e) {
      throw DatabaseHelperException('Erro ao abrir o banco de dados: $e');
    }
  }

  /// Abre um banco de dados em memória isolado — ideal para testes.
  static Future<Database> openInMemoryDatabase() async {
    try {
      final factory = _databaseFactory;
      return await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: (db, version) async {
            await _createTables(db);
          },
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON;');
          },
        ),
      );
    } catch (e) {
      throw DatabaseHelperException(
          'Erro ao abrir banco de dados em memória: $e');
    }
  }

  /// Retorna a factory correta dependendo da plataforma.
  static DatabaseFactory get _databaseFactory {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  /// Fecha a conexão com o banco de dados e reseta o estado interno.
  static Future<void> close() async {
    final db = _database;
    _database = null;
    _completer = null;
    await db?.close();
  }

  static Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), _databaseName);
  }

  /// Cria as tabelas do banco de dados: jornadas, ganhos e despesas.
  static Future<void> _createTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE jornadas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          descricao TEXT,
          inicio TEXT,
          fim TEXT,
          km_inicial REAL CHECK(km_inicial >= 0),
          km_final REAL CHECK(km_final >= 0),
          km_rodados REAL CHECK(km_rodados >= 0)
        )
      ''');

      await db.execute('''
        CREATE TABLE ganhos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          jornada_id INTEGER,
          valor REAL CHECK(valor >= 0),
          descricao TEXT,
          tipo TEXT NOT NULL DEFAULT 'extra',
          FOREIGN KEY (jornada_id) REFERENCES jornadas(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE despesas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          jornada_id INTEGER,
          valor REAL CHECK(valor >= 0),
          categoria TEXT,
          FOREIGN KEY (jornada_id) REFERENCES jornadas(id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      throw DatabaseHelperException('Erro ao criar tabelas: $e');
    }
  }

  /// Migração da versão 1 para a versão 2 do esquema.
  static Future<void> _migrateToV2(Database db) async {
    final despesasSchema = await db.rawQuery('PRAGMA table_info(despesas)');
    final hasCategoria =
        despesasSchema.any((column) => column['name'] == 'categoria');
    if (!hasCategoria) {
      await db.execute('ALTER TABLE despesas ADD COLUMN categoria TEXT');
    }

    final ganhosSchema = await db.rawQuery('PRAGMA table_info(ganhos)');
    final hasTipo = ganhosSchema.any((column) => column['name'] == 'tipo');
    if (!hasTipo) {
      await db.execute(
        "ALTER TABLE ganhos ADD COLUMN tipo TEXT NOT NULL DEFAULT 'extra'",
      );
    }
  }

  /// Migração da versão 2 para a versão 3.
  /// Recria as tabelas para garantir que km_inicial aceite zero.
  static Future<void> _migrateToV3(Database db) async {
    final jornadas = await db.query('jornadas');
    final ganhos = await db.query('ganhos');
    final despesas = await db.query('despesas');

    await db.execute('DROP TABLE IF EXISTS despesas');
    await db.execute('DROP TABLE IF EXISTS ganhos');
    await db.execute('DROP TABLE IF EXISTS jornadas');
    await _createTables(db);

    for (final jornada in jornadas) {
      await db.insert('jornadas', jornada);
    }

    for (final ganho in ganhos) {
      await db.insert('ganhos', ganho);
    }

    for (final despesa in despesas) {
      await db.insert('despesas', despesa);
    }
  }
}
