import 'dart:convert';

import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:dartt_integraforwood/Pages/common/widget_loader.dart';
import 'package:dartt_integraforwood/Pages/homescreen/controller/home_screen_controller.dart';
import 'package:dartt_integraforwood/Routes/app_routes.dart';
import 'package:dartt_integraforwood/commom/commom_functions.dart';
import 'package:dartt_integraforwood/commom/desenha_bordas.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class DetailsScreen extends StatelessWidget {
  DetailsScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());
  String? xmlString;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Integra ForWood'),
        actions: [
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Atualizar'),
                      onTap: () {
                        controller.sync3Cad();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Configurações'),
                      onTap: () {
                        Get.toNamed(PageRoutes.settings);
                      },
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Status da conexão SQL Server
              Obx(() => Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: controller.sqlServerConnected.value 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                  border: Border.all(
                    color: controller.sqlServerConnected.value 
                      ? Colors.green 
                      : Colors.red,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          controller.sqlServerConnected.value 
                            ? Icons.check_circle 
                            : Icons.error,
                          color: controller.sqlServerConnected.value 
                            ? Colors.green 
                            : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SQL Server: ${controller.sqlServerStatus.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: controller.sqlServerConnected.value 
                                ? Colors.green.shade800 
                                : Colors.red.shade800,
                            ),
                          ),
                        ),
                        if (!controller.sqlServerConnected.value)
                          TextButton(
                            onPressed: () => controller.connectSqlServer(),
                            child: Text('Tentar Novamente'),
                          ),
                      ],
                    ),
                    if (controller.sqlServerError.value.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          controller.sqlServerError.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
              Center(
                child: Wrap(
                  spacing: 8.0, // Espaçamento horizontal entre os botões
                  runSpacing:
                      8.0, // Espaçamento vertical entre as linhas de botões
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        controller.cadiretaSuccess.value = false;
                        controller.saveOKCadireta.clear();
                        controller.outliteData.value = null;
                        final prefs = await SharedPreferences.getInstance();
                        final diretorio = prefs.getString('diretorioXML') ?? 'T:\\xml';
                        final XFile? file = await openFile(
                          initialDirectory: diretorio,
                          acceptedTypeGroups: [
                            XTypeGroup(extensions: ['xml']),
                          ],
                        ); // Use openFile do file_selector

                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          xmlString = utf8.decode(bytes);
                          controller.loadXML(xmlString!, file.name);
                        }
                      },
                      icon: Icon(Icons.file_open),
                      label: Text('Selecionar arquivo XML'),
                    ),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            controller.outliteData.value == null
                                ? null
                                : () async {
                                  controller.saveDataBase(
                                    outlite: controller.outliteData.value!,
                                    xmlString: xmlString,
                                  );
                                },
                        icon: Icon(Icons.send),
                        label: Text('Enviar para ForWood'),
                      ),
                    ),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            controller.outliteData.value == null
                                ? null
                                : () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            'Selecione o tipo de impressão',
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: Icon(
                                                  Icons.shopping_cart,
                                                ),
                                                title: Text('Itens Comprados'),
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                  controller
                                                      .generateCompradosReport();
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.build),
                                                title: Text('Itens Fabricados'),
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                  controller
                                                      .generateFabricadosReport();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                        icon: Icon(Icons.print),
                        label: Text('Imprimir'),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.history),
                      label: Text('Enviados'),
                    ),
                    GetBuilder<HomeScreenController>(
                      builder: (ctl) {
                        if (ctl.databaseOn) {
                          return const Text(
                            'FW On: 🟢',
                            style: TextStyle(fontSize: 12.0),
                          );
                        } else {
                          return const Text(
                            'FW Off: 🔴',
                            style: TextStyle(fontSize: 12.0),
                          );
                        }
                      },
                    ),
                    GetBuilder<HomeScreenController>(
                      builder: (ctl) {
                        if (ctl.databasePro) {
                          return const Text(
                            '3Cad On: 🟢',
                            style: TextStyle(fontSize: 12.0),
                          );
                        } else {
                          return const Text(
                            '3Cad Off: 🔴',
                            style: TextStyle(fontSize: 12.0),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Obx(() {
                final outlite = controller.outliteData.value;
                if (controller.isLoading.value) {
                  // return Center(child: CircularProgressIndicator());
                  return Center(
                    child: LoadingWidget(
                      message: controller.statusMessage.value,
                    ),
                  );
                }
                if (controller.saveCadiretaLoading.value) {
                  // return Center(child: CircularProgressIndicator());
                  return Center(
                    child: LoadingWidget(
                      message: "Importando dados para o ForWood...",
                    ),
                  );
                }
                if (controller.saveOKCadireta.isNotEmpty) {
                  // return Center(child: CircularProgressIndicator());
                  controller.saveCadiretaLoading.value = false;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.dangerous, color: Colors.red),
                          label: Text(
                            "Erro ao importar dados para o ForWood! Clique para retornar!",
                          ),
                          onPressed: () {
                            controller.saveOKCadireta.clear();
                          },
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.saveOKCadireta.length,
                          itemBuilder: (_, index) {
                            return ListTile(
                              title: Text(controller.saveOKCadireta[index]),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }
                if (controller.saveOKCadireta.isEmpty &&
                    controller.cadiretaSuccess.value == true) {
                  controller.saveCadiretaLoading.value = false;
                  return TextButton.icon(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    label: Text(
                      "Dados importados com sucesso! Importe um novo XML!",
                    ),
                    onPressed: () {},
                  );
                }
                if (outlite != null && controller.saveOKCadireta.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${outlite.data ?? 'N/A'}'),
                      Text('Número: ${outlite.numero ?? 'N/A'}'),
                      Text('RIF: ${outlite.rif}'),
                      if (outlite.itembox != null)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: outlite.itembox!.length,
                          itemBuilder: (_, index) {
                            final qtdfinal = multiplicaQtd(
                              outlite.itembox![index].qta!,
                              outlite.itembox![index].pz!,
                            );
                            return Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text(
                                      'Pai: ${outlite.itembox![index].codigo} - ${outlite.itembox![index].des ?? 'N/A'} - ${qtdfinal ?? 'N/A'} - Dim: ${outlite.itembox![index].l ?? 'N/A'}x${outlite.itembox![index].a ?? 'N/A'}x${outlite.itembox![index].p ?? 'N/A'}',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        TextButton(
                                          child: const Text('PRODUZIDOS'),
                                          onPressed: () {
                                            widgetproduzidos(
                                              context,
                                              outlite,
                                              index,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          child: const Text('COMPRADOS'),
                                          onPressed: () {
                                            widgetcomprados(
                                              context,
                                              outlite,
                                              index,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  void widgetcomprados(BuildContext context, Outlite outlite, int index) {
    showDialog<String>(
      context: context,
      builder:
          (BuildContext context) => Dialog.fullscreen(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Text(
                        "Itens Comprados",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (outlite
                        .itembox![index]
                        .itemPrice!
                        .isEmpty) // Verifica se há linhas para este código
                      Column(children: [Text("Erro ao carregar peças")]),
                    if (outlite
                        .itembox![index]
                        .itemPrice!
                        .isNotEmpty) // Verifica se há linhas para este código
                      for (var itemPrice in outlite.itembox![index].itemPrice!)
                        Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            // Exibe as linhas de DISTINTAT
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Table(
                                      border: TableBorder.all(),
                                      columnWidths:
                                          const <int, TableColumnWidth>{
                                            0: IntrinsicColumnWidth(),
                                            1: IntrinsicColumnWidth(),
                                            2: IntrinsicColumnWidth(),
                                          },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: <TableRow>[
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[70],
                                          ),
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Código'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Descrição'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Qtd'),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                          ),
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPrice.codigo ?? '',
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(itemPrice.des ?? ''),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(itemPrice.qtd ?? ''),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    /*Text(
                                      'Cod: ${itemPrice.codigo}, ${itemPrice.qtd}',
                                    ),*/
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<String?> widgetproduzidos(
    BuildContext context,
    Outlite outlite,
    int index,
  ) {
    return showDialog<String>(
      context: context,
      builder:
          (BuildContext context) => Dialog.fullscreen(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Text(
                        "Itens Fabricados",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (outlite
                        .itembox![index]
                        .itemPecas!
                        .isEmpty) // Verifica se há linhas para este código
                      Column(children: [Text("Erro ao carregar peças")]),
                    if (outlite
                        .itembox![index]
                        .itemPecas!
                        .isNotEmpty) // Verifica se há linhas para este código
                      for (var itemPecas in outlite.itembox![index].itemPecas!)
                        Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            // Exibe as linhas de DISTINTAT
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Table(
                                      border: TableBorder.all(),
                                      columnWidths:
                                          const <int, TableColumnWidth>{
                                            0: IntrinsicColumnWidth(),
                                            1: IntrinsicColumnWidth(),
                                            2: IntrinsicColumnWidth(),
                                            3: IntrinsicColumnWidth(),
                                            4: IntrinsicColumnWidth(),
                                            5: IntrinsicColumnWidth(),
                                          },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: <TableRow>[
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[70],
                                          ),
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Código'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Descrição'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Qtd'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Comprimento'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Largura'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text('Espessura'),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                          ),
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPecas.codpeca ?? '',
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPecas.idpeca ?? '',
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(itemPecas.qta ?? ''),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPecas.comprimento ?? '',
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPecas.largura ?? '',
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                itemPecas.espessura ?? '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    /*Text(
                                      'Cod: ${itemPecas.codpeca}, ${itemPecas.qta}, ${itemPecas.comprimento}, ${itemPecas.largura}, ${itemPecas.espessura}, ${itemPecas.fitaesq}, ${itemPecas.fitadir}, ${itemPecas.fitafre}, ${itemPecas.fitatra}, ${itemPecas.trabalhoesq}, ${itemPecas.trabalhodir}, ${itemPecas.trabalhofre}, ${itemPecas.trabalhotra}',
                                    ),*/
                                    SizedBox(width: 32),
                                    CustomPaint(
                                      size: Size(
                                        double.parse(
                                              itemPecas.comprimento ?? '',
                                            ) /
                                            10,
                                        double.parse(itemPecas.largura ?? '') /
                                            10,
                                      ),
                                      painter: BordaColoridaPainter(
                                        bordaesq: itemPecas.fitaesq ?? 'N',
                                        bordadir: itemPecas.fitadir ?? 'N',
                                        bordafre: itemPecas.fitafre ?? 'N',
                                        bordatra: itemPecas.fitatra ?? 'N',
                                      ),
                                    ),
                                    SizedBox(width: 32),
                                    IconButton(
                                      onPressed: () async {
                                        final result = await controller
                                            .getEstruturaExpandida(
                                              itemPecas.codpeca!,
                                              itemPecas.variaveis!,
                                              itemPecas.comprimento!,
                                              itemPecas.largura!,
                                              itemPecas.espessura!,
                                            );
                                        if (result.isEmpty ||
                                            result == "Erro") {
                                          _mostrarDialogComResultados(
                                            // ignore: use_build_context_synchronously
                                            context,
                                            [],
                                          );
                                        } else {
                                          List<Map<String, dynamic>>
                                          resultados =
                                              List<Map<String, dynamic>>.from(
                                                json.decode(result),
                                              );
                                          _mostrarDialogComResultados(
                                            // ignore: use_build_context_synchronously
                                            context,
                                            resultados,
                                          );
                                        }
                                      },
                                      icon: Icon(Icons.add_box),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

void _mostrarDialogComResultados(
  BuildContext context,
  List<Map<String, dynamic>> resultados,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Resultados da Distinta"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child:
              resultados.isEmpty
                  ? const Center(child: Text("Nenhum dado carregado."))
                  : ListView.builder(
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      final item = resultados[index];
                      return ListTile(
                        title: Text(item['CODFIG'] ?? ''),
                        subtitle: Text(item['DESCRICAO'] ?? ''),
                        trailing: SizedBox(
                          width: 180,
                          child:
                              item['FASE'] != ''
                                  ? Text(
                                    "QTA: ${item['QTA']} - Setor: ${item['FASE'] ?? ''}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                  : Text(
                                    "Setor",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fechar"),
          ),
        ],
      );
    },
  );
}
