import 'package:flutter/material.dart';
import 'package:motofinance/core/database/database_helper.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/providers/navigation_provider.dart';
import 'package:motofinance/repositories/jornada_repository.dart';
import 'package:motofinance/screens/dashboard_page.dart';
import 'package:motofinance/screens/home_page.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.getDatabase();

  runApp(MultiProvider(
    providers: [
      Provider<Database>(create: (_) => db),
      ChangeNotifierProvider(create: (context) => JornadaProvider(JornadaRepository(db))),
      ChangeNotifierProvider(create: (_) => GahnoProvider()),
      ChangeNotifierProvider(create: (_) => DespesaProvider()),
      ChangeNotifierProvider(create: (context)=> NavigationProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotoFinance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DashboardPage(),
    );
  }
}
