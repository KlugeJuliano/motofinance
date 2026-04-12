import 'package:flutter/material.dart';
import 'package:motofinance/core/database/database_helper.dart';
import 'package:motofinance/providers/despesa_provider.dart';
import 'package:motofinance/providers/ganho_provider.dart';
import 'package:motofinance/providers/jornada_provider.dart';
import 'package:motofinance/providers/navigation_provider.dart';
import 'package:motofinance/repositories/despesa_repository.dart';
import 'package:motofinance/repositories/ganho_repository.dart';
import 'package:motofinance/repositories/jornada_repository.dart';
import 'package:motofinance/screens/dashboard_page.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.instance;

  runApp(MultiProvider(
    providers: [
      Provider<Database>(create: (_) => db),
      Provider<JornadaRepository>(create: (_) => JornadaRepository(db)),
      Provider<GanhoRepository>(create: (_) => GanhoRepository(db)),
      Provider<DespesaRepository>(create: (_) => DespesaRepository(db)),
      ChangeNotifierProvider(
        create: (context) => JornadaProvider(context.read<JornadaRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => GanhoProvider(context.read<GanhoRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => DespesaProvider(context.read<DespesaRepository>()),
      ),
      ChangeNotifierProvider(create: (context) => NavigationProvider()),
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
      theme: CustomTheme.darkTheme,
      home: const DashboardPage(),
    );
  }
}
