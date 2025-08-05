import 'dart:convert';

import 'package:dartt_integraforwood/Pages/homescreen/controller/home_screen_controller.dart';
import 'package:dartt_integraforwood/config/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_selector/file_selector.dart';

class DetailsScreen extends StatelessWidget {
  DetailsScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Integra ForWood')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final XFile? file = await openFile(
                        initialDirectory: diretorioXML,
                        acceptedTypeGroups: [
                          XTypeGroup(extensions: ['xml']),
                        ],
                      ); // Use openFile do file_selector

                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final xmlString = utf8.decode(bytes);
                        controller.loadXML(xmlString);
                      }
                    },
                    child: Text('Selecionar arquivo XML'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      controller.saveDataBase();
                    },
                    child: Text('Enviar para ForWood'),
                  ),

                  GetBuilder<HomeScreenController>(
                    builder: (ctl) {
                      if (ctl.databaseOn) {
                        return const Text(
                          'Conectado: 🟢',
                          style: TextStyle(fontSize: 12.0),
                        );
                      } else {
                        return const Text(
                          'Desconectado: 🔴',
                          style: TextStyle(fontSize: 12.0),
                        );
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Obx(() {
                final outlite = controller.outliteData.value;

                if (outlite != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${outlite.data ?? 'N/A'}'),
                      Text('Número: ${outlite.numero ?? 'N/A'}'),
                      Text('RIF: ${outlite.rif}'),
                      if (outlite.itembox != null)
                        for (var itemBox in outlite.itembox!)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pai: ${itemBox.codigo ?? 'N/A'}; ${itemBox.des ?? 'N/A'}; ${itemBox.qta ?? 'N/A'}; Dim: ${itemBox.l ?? 'N/A'}x${itemBox.a ?? 'N/A'}x${itemBox.p ?? 'N/A'}',
                              ),
                              if (itemBox
                                  .itemPecas!
                                  .isEmpty) // Verifica se há linhas para este código
                                Column(
                                  children: [Text("Erro ao carregar peças")],
                                ),
                              if (itemBox
                                  .itemPecas!
                                  .isNotEmpty) // Verifica se há linhas para este código
                                for (var itemPecas in itemBox.itemPecas!)
                                  Column(
                                    // Exibe as linhas de DISTINTAT
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cod: ${itemPecas.codpeca}, ${itemPecas.qta}, ${itemPecas.comprimento}, ${itemPecas.largura}, ${itemPecas.espessura}, ${itemPecas.fitaesq}, ${itemPecas.fitadir}, ${itemPecas.fitafre}, ${itemPecas.fitatra}, ${itemPecas.trabalhoesq}, ${itemPecas.trabalhodir}, ${itemPecas.trabalhofre}, ${itemPecas.trabalhotra}',
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                    ],
                  );
                } else {
                  return Text('Nenhum dado XML carregado.');
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
