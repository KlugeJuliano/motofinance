import 'package:flutter/material.dart';
import 'package:motofinance/screens/home_page.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import 'despesas_page.dart';
import 'ganhos_page.dart';
import 'jornada_page.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final List<Widget> _telas = [
      HomePage(),
      JornadaPage(),
      GanhosPage(),
      SpendingPage()
    ];
    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: navigation.currentIndex,
        children: _telas,
      ),
      bottomNavigationBar: BottomNavigationBar(

        currentIndex: navigation.currentIndex,
        onTap: (index) => navigation.setCurrentIndex(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início', backgroundColor: Colors.black12
          ),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Ganhos'),
          BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'Despesas'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
        ],
        selectedItemColor: Colors.amber[800],
      ),
    );
  }
}
