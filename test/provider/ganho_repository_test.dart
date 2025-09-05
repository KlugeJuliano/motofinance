import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:motofinance/core/database/database_helper.dart';
import 'package:motofinance/models/jornada_model.dart';
import 'package:motofinance/repositories/ganho_repository.dart';

void main(){
  group('Ganhos repostiory', (){
    late Database db;
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
  });
    setUp(()async{
    db = await DatabaseHelper.getDatabase(inMemory: true);
    });
    tearDown(()async{
      await db.close();
    });
    test('deve inserir um ganho corretamente', () async {
      final ganho = await GanhoRepository.inserirGanho(Ganho(
        descricao: 'Frete',
        valor: 50.0,
        data: DateTime(2024, 6, 1),
      ));
      expect(ganho.descricao, 'Frete');
      expect(ganho.valor, 50.0);
      expect(ganho., DateTime(2024, 6, 1));
    });
}