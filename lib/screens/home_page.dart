import 'package:flutter/material.dart';
import 'package:motofinance/providers/navigation_provider.dart';
import 'package:motofinance/screens/despesas_page.dart';
import 'package:motofinance/screens/ganhos_page.dart';
import 'package:motofinance/screens/jornada_page.dart';
import 'package:motofinance/themes/custom_theme.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: CustomTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(

        backgroundColor: CustomTheme.darkTheme.appBarTheme.backgroundColor,
        title: Container(
          padding: EdgeInsets.all(8),

          child: Column(
            children: [
              Text("Painel do dia", style: CustomTheme.darkTheme.textTheme.bodyMedium,),
              Text(DateFormat("dd/MM/yyyy").format(DateTime.now()), style: CustomTheme.darkTheme.textTheme.bodySmall,),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(padding: EdgeInsets.all(16),

      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            height: MediaQuery.of(context).size.height/4,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/moto.png', height: 80, ),
                  ],
                ),
                SizedBox(width: 8,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Km rodados hoje',
                    style: CustomTheme.darkTheme.textTheme.bodyMedium ,),
                    Text('85 Km',
                      style: CustomTheme.darkTheme.textTheme.bodyLarge ,),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            Container(
              padding: EdgeInsets.all(8),

              height: MediaQuery.of(context).size.height/4,
              width: MediaQuery.of(context).size.width/2.3,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ganhos do dia', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
                  Text('R 450,00', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
                ],
              ),
            ),
            SizedBox(width: 16,),
            Container(
              padding: EdgeInsets.all(8),

              width: MediaQuery.of(context).size.width/2.3,
              height: MediaQuery.of(context).size.height/4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Despesas do dia', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
                  Text('R 120,00', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],),
          SizedBox(height: 16,),
          Container(
            padding: EdgeInsets.all(8),

            height: MediaQuery.of(context).size.height/4,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Saldo liquido do dia', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
                Text('R 345,00', style: CustomTheme.darkTheme.textTheme.bodyMedium,),
              ],
            ),
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(8),
          ),),
        ],
      ),
      ),


    );
  }
}
