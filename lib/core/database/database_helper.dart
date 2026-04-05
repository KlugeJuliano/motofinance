import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
  static const _databaseVersion = 2;

  static Database? _database;

  /// Singleton pattern to ensure only one connection is active.
  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await getDatabase(inMemory: false);
    return _database!;
  }

  /// Abre uma conexão com o banco de dados, em memória ou em arquivo.
  static Future<Database> getDatabase({bool inMemory = true}) async {
    try {
      final factory = _databaseFactory;

      if (inMemory) {
        // Em testes, cada chamada em memoria deve retornar uma instancia isolada.
        final db = await factory.openDatabase(
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
        return db;
      }
      _database = await factory.openDatabase(
        join(await getDatabasesPath(), _databaseName),
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
          },
        ),
      );
      return _database!;
    } catch (e) {
      throw DatabaseHelperException('Erro ao abrir o banco de dados: $e');
    }
  }

  static DatabaseFactory get _databaseFactory {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  /// Fecha a conexão com o banco de dados.
  static Future<void> close() async {
    await _database?.close();
    _database = null;
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

  static Future<void> _migrateToV2(Database db) async {
    final despesasSchema = await db.rawQuery('PRAGMA table_info(despesas)');
    final hasCategoria = despesasSchema.any(
      (column) => column['name'] == 'categoria',
    );
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
}
