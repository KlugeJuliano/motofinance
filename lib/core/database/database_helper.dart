import 'package:sqflite/sqflite.dart';
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
  static const _databaseVersion = 1;

  /// Abre uma conexão com o banco de dados, em memória ou em arquivo.
  static Future<Database> getDatabase({bool inMemory = false}) async {
    try {
      if (inMemory) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        return await databaseFactoryFfi.openDatabase(
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
      }
      return await openDatabase(
        join(await getDatabasesPath(), _databaseName),
        version: _databaseVersion,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Implementar lógica de atualização de esquema, se necessário
        },
      );
    } catch (e) {
      throw DatabaseHelperException('Erro ao abrir o banco de dados: $e');
    }
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
          FOREIGN KEY (jornada_id) REFERENCES jornadas(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE despesas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          jornada_id INTEGER,
          valor REAL CHECK(valor >= 0),
          FOREIGN KEY (jornada_id) REFERENCES jornadas(id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      throw DatabaseHelperException('Erro ao criar tabelas: $e');
    }
  }
}