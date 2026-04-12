import 'package:flutter/material.dart';
import 'package:motofinance/screens/home_page.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import 'despesas_page.dart';
import 'ganhos_page.dart';
import 'jornada_page.dart';
import 'relatorios_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final List<Widget> telas = [
      HomePage(loadData: widget.loadData),
      JornadaPage(loadData: widget.loadData),
      GanhosPage(loadData: widget.loadData),
      SpendingPage(loadData: widget.loadData),
      RelatoriosPage(loadData: widget.loadData),
    ];
    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: navigation.currentIndex,
        children: telas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigation.currentIndex,
        onTap: (index) => navigation.setCurrentIndex(index),
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
              backgroundColor: Colors.black12),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Jornada'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Ganhos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.money_off), label: 'Despesas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Relatorios'),
        ],
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
