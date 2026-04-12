import 'package:motofinance/models/jornada_model.dart';
import 'package:sqflite/sqflite.dart';

class JornadaRepository {
  final Database db;

  JornadaRepository(this.db);

  Future<List<Jornada>> listarJornadas() async {
    final List<Map<String, dynamic>> maps =
        await db.query('jornadas', orderBy: 'inicio DESC');
    return maps.map((map) => Jornada.fromMap(map)).toList();
  }

  Future<void> inserirJornada(Jornada jornada) async {
    await db.insert('jornadas', jornada.toMap());
  }

  Future<void> finalizar(int id, double kmFinal) async {
    final result = await db.query('jornadas', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) {
      throw Exception('Jornada ID $id não encontrada');
    }
    final kmInicial = result.first['km_inicial'] as num;
    await db.update(
      'jornadas',
      {
        'fim': DateTime.now().toIso8601String(),
        'km_final': kmFinal,
        'km_rodados': kmFinal - kmInicial.toDouble(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> limparBanco() async {
    await db.transaction((txn) async {
      await txn.delete('ganhos');
      await txn.delete('despesas');
      await txn.delete('jornadas');
    });
  }
}
