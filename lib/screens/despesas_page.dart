// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';

class SpendingPage extends StatefulWidget {
  const SpendingPage({super.key});

  @override

  State<SpendingPage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<SpendingPage> {
  int index = 0;
  int items = 10;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despesas'),
          centerTitle: true,
        ),
        body: ListView.builder(
          itemCount: items,
          itemBuilder: (context, index) {
            return const ListTile(
              title: Text(
                'Despesas diversas',
                style: TextStyle(fontSize: 18),
              ),
              trailing: Text('9,99'),
              subtitle: Text('18/dez/2024'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Qual é a despesa?',
                              style: TextStyle(fontSize: 24),
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Qual é o valor?',
                              style: TextStyle(fontSize: 24),
                            ),
                            TextFormField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text(
                                'Adicionar',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ],
                        ));
                  });
            },
            label: const Text('Adicionar despesa')),
      ),
    );
  }
}
