import 'package:motofinance/models/ganho_model.dart';
import 'package:sqflite/sqflite.dart';

class GanhoRepository {
  final Database db;

  GanhoRepository(this.db);

  Future<Ganho> inserirGanho(Ganho ganho) async {
    final id = await db.insert('ganhos', ganho.toMap());
    return Ganho(
      id: id,
      jornadaId: ganho.jornadaId,
      valor: ganho.valor,
      descricao: ganho.descricao,
      tipo: ganho.tipo,
    );
  }

  Future<List<Ganho>> listarGanhos() async {
    final maps = await db.query('ganhos', orderBy: 'id DESC');
    return maps.map(Ganho.fromMap).toList();
  }

  Future<void> excluirGanho(int id) async {
    await db.delete('ganhos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> editarGanho(Ganho ganho) async {
    await db.update(
      'ganhos',
      ganho.toMap(),
      where: 'id = ?',
      whereArgs: [ganho.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> salvarGanhoPrincipal({
    required int jornadaId,
    required double valor,
  }) async {
    final existente = await db.query(
      'ganhos',
      where: 'jornada_id = ? AND tipo = ?',
      whereArgs: [jornadaId, 'principal'],
      limit: 1,
    );

    final payload = {
      'jornada_id': jornadaId,
      'valor': valor,
      'descricao': 'Ganhos do dia',
      'tipo': 'principal',
    };

    if (existente.isEmpty) {
      await db.insert('ganhos', payload);
      return;
    }

    await db.update(
      'ganhos',
      payload,
      where: 'id = ?',
      whereArgs: [existente.first['id']],
    );
  }
}
