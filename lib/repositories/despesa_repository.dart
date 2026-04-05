import 'package:motofinance/models/despesa_model.dart';
import 'package:sqflite/sqflite.dart';

class DespesaRepository {
  final Database db;

  DespesaRepository(this.db);

  Future<Despesa> inserirDespesa(Despesa despesa) async {
    final id = await db.insert('despesas', despesa.toMap());
    return Despesa(
      id: id,
      jornadaId: despesa.jornadaId,
      valor: despesa.valor,
      categoria: despesa.categoria,
    );
  }

  Future<List<Despesa>> listarDespesas() async {
    final maps = await db.query('despesas', orderBy: 'id DESC');
    return maps.map(Despesa.fromMap).toList();
  }

  Future<void> excluirDespesa(int id) async {
    await db.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> editarDespesa(Despesa despesa) async {
    await db.update(
      'despesas',
      despesa.toMap(),
      where: 'id = ?',
      whereArgs: [despesa.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
