import 'dart:convert';
import 'dart:io';

import 'package:dartt_integraforwood/Models/cadiredi.dart';
import 'package:dartt_integraforwood/Models/cadireta.dart';
import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:dartt_integraforwood/Pages/homescreen/repository/home_screen_repository.dart';
import 'package:dartt_integraforwood/commom/pdf_service.dart';
import 'package:dartt_integraforwood/config/consts.dart';
import 'package:dartt_integraforwood/db/postgres_connection.dart';
import 'package:dartt_integraforwood/db/sqlserver_connection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:get/get.dart';

// Classes Outlite, ItemBox e ItemPecas (fornecidas anteriormente)

class HomeScreenController extends GetxController {
  final homeScreenRepository = HomeScreenRepository();
  final pdfService = PdfService();

  bool databaseOn = false;
  bool databasePro = false;

  RxBool isLoading = false.obs;
  RxString statusMessage = ''.obs;
  RxBool isGeneratingReport = false.obs;
  RxBool saveCadiretaLoading = false.obs;
  RxList saveOKCadireta = [].obs;
  RxBool cadiretaSuccess = false.obs;

  @override
  void onInit() async {
    await connectDatabase();
    await connectSqlServer();
    super.onInit();
  }

  onDispose() {
    super.dispose();
    PostgresConnection().close();
    SqlServerConnection().close();
  }

  Future<void> connectDatabase() async {
    final conected = await PostgresConnection().connect(
      host: hostFW,
      port: portFW,
      database: databaseFW,
      username: userNameFW,
      password: passwordFW,
    );
    setDatabaseon(conected);
  }

  Future<void> connectSqlServer() async {
    final conected = await SqlServerConnection().connect(
      ip: hostSQL,
      port: portSQL,
      database: databaseSQL,
      username: userNameSQL,
      password: passwordSQL,
    );
    setDatabasePro(conected);
  }

  void setDatabaseon(bool value) {
    databaseOn = value;
    update();
  }

  void setDatabasePro(bool value) {
    databasePro = value;
    update();
  }

  var outliteData = Rxn<Outlite>();
  var distintatLines =
      RxMap<
        String,
        List<String>
      >(); // Usa um Map para armazenar as linhas de DISTINTAT por código

  var dettprezzoLines = RxMap<String, List<String>>();

  Future<void> loadXML(String xmlString, String fileName) async {
    try {
      isLoading.value = true;
      statusMessage.value = 'Analisando arquivo XML...';
      final parsedXml = XmlDocument.parse(xmlString);
      await extractData(parsedXml, fileName);
      statusMessage.value = 'Importado com sucesso...';
      isLoading.value = false;
    } catch (e) {
      //TODO: Criar gestão caso não leia o xml
    }
  }

  Future<void> extractData(XmlDocument parsedXml, String fileName) async {
    statusMessage.value = 'Extraindo dados do XML...';
    final testas = parsedXml.findAllElements('TESTA');
    final righes = parsedXml.findAllElements('RIGHE').toList();

    if (testas.isNotEmpty && righes.isNotEmpty) {
      final testa = testas.first;
      final righeElement = righes.first;

      final List<ItemBox> itemBoxList = [];

      for (final riga in righeElement.children.whereType<XmlElement>()) {
        final distintatElement = riga.findElements('DISTINTAT');
        final dettprezzoElement = riga.findElements('DETTPREZZO');
        final codigo =
            riga.findElements('COD').isNotEmpty
                ? riga.findElements('COD').first.innerText
                : '';

        if (dettprezzoElement.isNotEmpty) {
          final dettprezzoText = dettprezzoElement.first.innerText;
          final dettprezzolines = dettprezzoText.split('{RT16}');
          dettprezzoLines[codigo] = dettprezzolines;
        }

        if (distintatElement.isNotEmpty) {
          final distintatText = distintatElement.first.innerText;
          final lines = distintatText.split(RegExp(r'&#13;&#10;|\n'));
          distintatLines[codigo] = lines;
        }

        itemBoxList.add(
          ItemBox(
            riga: int.tryParse(codigo),
            codigo: codigo,
            des:
                riga.findElements('DES').isNotEmpty
                    ? riga.findElements('DES').first.innerText
                    : null,
            pz:
                riga.findElements('PZ').isNotEmpty
                    ? riga.findElements('PZ').first.innerText
                    : null,
            qta:
                riga.findElements('QTA').isNotEmpty
                    ? riga.findElements('QTA').first.innerText
                    : null,
            l:
                riga.findElements('L').isNotEmpty
                    ? riga.findElements('L').first.innerText
                    : null,
            a:
                riga.findElements('A').isNotEmpty
                    ? riga.findElements('A').first.innerText
                    : null,
            p:
                riga.findElements('P').isNotEmpty
                    ? riga.findElements('P').first.innerText
                    : null,
            itemPecas: await getItemPecas(distintatLines, codigo),
            itemPrice: await getPriceItems(dettprezzoLines, codigo),
          ),
        );
      }

      final outlite = Outlite(
        data:
            testa.findElements('DATA').isNotEmpty
                ? testa.findElements('DATA').first.innerText
                : null,
        numero:
            testa.findElements('NUMERO').isNotEmpty
                ? testa.findElements('NUMERO').first.innerText
                : null,
        dataDesenho: null,
        rif:
            testa.findElements('RIF').isNotEmpty
                ? testa.findElements('RIF').first.innerText
                : '',
        fileName: fileName,
        itembox: itemBoxList,
      );

      outliteData.value = outlite;
    }
  }

  Future<List<ItemPecas>> getItemPecas(
    RxMap<String, List<String>>? distintatLines,
    String? codigo,
  ) async {
    List<ItemPecas> itemPecas = [];
    List<String> distintatSplited = [];
    String trabalhoesq = "N";
    String trabalhodir = "N";
    String trabalhofre = "N";
    String trabalhotra = "N";
    String fitaesq = "N";
    String fitadir = "N";
    String fitafre = "N";
    String fitatra = "N";

    if (distintatLines!.isNotEmpty | codigo!.isNotEmpty) {
      for (var line in distintatLines[codigo]!) {
        List<String> partes = line.split(',');
        if (partes.length > 1) {
          // Verifica se a linha tem pelo menos dois campos
          if (partes[7].isNotEmpty) {
            trabalhoesq = partes[7].split('/')[0];
            trabalhodir = partes[7].split('/')[1];
            trabalhofre = partes[7].split('/')[2];
            trabalhotra = partes[7].split('/')[3];
            fitaesq = partes[7].split('/')[4];
            fitadir = partes[7].split('/')[5];
            fitafre = partes[7].split('/')[6];
            fitatra = partes[7].split('/')[7];
          }
          itemPecas.add(
            ItemPecas(
              codpeca: partes[0],
              idpeca: await homeScreenRepository.getDescricaoProduto(partes[0]),
              qta: partes[1],
              comprimento: partes[3],
              largura: partes[4],
              espessura: partes[5],
              nbox: partes[6],
              variaveis: partes[2],
              trabalhoesq: trabalhoesq,
              trabalhodir: trabalhodir,
              trabalhofre: trabalhofre,
              trabalhotra: trabalhotra,
              fitaesq: fitaesq,
              fitadir: fitadir,
              fitafre: fitafre,
              fitatra: fitatra,
              grupo: await homeScreenRepository.getProdutoForId(
                partes[0],
                'grupo_produto',
              ),
              subgrupo: await homeScreenRepository.getProdutoForId(
                partes[0],
                'subgrupo_produto',
              ),
              um: await homeScreenRepository.getProdutoForId(
                partes[0],
                'um_produto',
              ),
              origem: await homeScreenRepository.getProdutoForId(
                partes[0],
                'origem_produto',
              ),
              status: await homeScreenRepository.getProdutoForId(
                partes[0],
                'status_produto',
              ),
              fase: await homeScreenRepository.getProdutoForId(
                partes[0],
                'fase_padrao_consumo',
              ),
            ),
          ); // Imprime o segundo campo (o valor)
        } else {
          //TODO: 'Linha inválida: $line', Lida com linhas que não têm o formato esperado
        }
      }
    }
    distintatSplited.clear();
    return itemPecas;
  }

  Future<void> saveDataBase({Outlite? outlite, String? xmlString}) async {
    saveCadiretaLoading.value = true;
    if (outliteData.value != null) {
      await saveCadireta(outliteData.value!);
    }
    saveCadiretaLoading.value = false;
  }

  Future<List<ItemPrice>> getPriceItems(
    RxMap<String, List<String>> dettprezzoLines,
    String codigo,
  ) async {
    List<ItemPrice> itemPrice = [];
    if (dettprezzoLines.isNotEmpty) {
      for (var lineDP in dettprezzoLines[codigo]!) {
        List<String> partesDP = lineDP.split(';');
        if (partesDP.length > 1) {
          itemPrice.add(
            ItemPrice(
              codigo: partesDP[1],
              des: await homeScreenRepository.getDescricaoProduto(partesDP[1]),
              qtd: partesDP[6],
            ),
          );
        }
      }
      return itemPrice;
    } else {
      return [];
    }
  }

  Future<void> saveCadireta(Outlite outlite) async {
    int contador = 0; // Defina o valor de cadcont conforme necessário
    int contadorItemPeca = 0; // Defina o valor de cadcont conforme necessário
    int contadorItemCompra = 0; // Defina o valor de cadcont conforme necessário

    // Salva os dados do pai
    for (var oi in outlite.itembox!) {
      contador = contador + 1;
      // var codpai = oi.codigo ?? '';
      var despai = oi.des ?? '';
      var codpai = await executaEspecialESP0019(
        codbatismomodulo,
        500,
        8,
        contador,
      );
      Cadireta cadireta = Cadireta(
        cadcont: contador,
        cadpai: '5.8.9999',
        cadfilho: codpai,
        cadstatus: 'C',
        cadsuscad: 'IMP3CAD',
        cadpainome: 'ITEMBOX_TESTE',
        cadfilnome: despai,
        cadpaium: 'UN',
        cadfilum: 'UN',
        caduso: double.parse(oi.qta!) * double.parse(oi.pz!),
        cadcomp: 0,
        cadlarg: 0,
        cadesp: 0,
        cadpeso: 0.0,
        cadfase: 40,
        cadgrav: getDateFormated(DateTime.now()),
        cadhora: DateFormat.Hms().format(DateTime.now()),
        cadimpdt: getDateFormated(DateTime.now()),
        cadimphr: '',
        cadusuimp: '',
        cadlocal: '',
        cadgrpai: 500, // TODO: busca do cadpai
        cadsgpai: 8, // TODO: busca do cadpai
        cadsgrfil: 400, // TODO: busca do cadfilho
        cadsgfil: 1, // TODO: busca do cadfilho
        cadoriemb: 0,
        cadproj: 'IMP3CAD',
        cadarquivo: '',
        cadcobr: 0.00,
        cadlabr: 0.00,
        cadesbr: 0.00,
        cadclass: '',
        cadplcor: 'N',
        cadusamed: 'N',
        cadborint: 'N',
        cadbordsup: 'N',
        cadbordinf: 'N',
        cadboresq: 'N',
        cadbordir: 'N',
        cadpaiarea: 0.0,
        cadtpfil: '',
        cadpembpr: 0,
        cadpembpp: 0,
        cadindter: 'N',
        caddimper: 0.00,
        cadapp: 'PDM',
      );
      final error = await homeScreenRepository.saveCadireta(
        cadireta,
        contadorItemPeca,
        'pai',
      );
      if (error != "") {
        saveOKCadireta.add(error);
      }
      // Salva os dados do filho (estrutura)
      for (var itemPeca in oi.itemPecas!) {
        contadorItemPeca = contadorItemPeca + 1;
        String codpeca = itemPeca.codpeca!;
        if (double.parse(itemPeca.comprimento!) >= 0 &&
            double.parse(itemPeca.largura!) >= 0 &&
            double.parse(itemPeca.espessura!) >= 0) {
          codpeca = await executaEspecialESP0019(
            codbatismomodulo,
            500,
            8,
            contadorItemPeca,
          );
        }

        Cadireta cadireta = Cadireta(
          cadcont: contador,
          cadpai: codpai,
          cadfilho: codpeca,
          cadstatus: 'C',
          cadsuscad: 'IMP3CAD',
          cadpainome: despai,
          cadfilnome: itemPeca.idpeca!,
          cadpaium: 'UN',
          cadfilum: 'UN',
          caduso: double.parse(itemPeca.qta!),
          cadcomp: 0,
          cadlarg: 0,
          cadesp: 0,
          cadpeso: 0.0,
          cadfase: int.tryParse(itemPeca.fase ?? '') ?? 40,
          cadgrav: getDateFormated(DateTime.now()),
          cadhora: DateFormat.Hms().format(DateTime.now()),
          cadimpdt: getDateFormated(DateTime.now()),
          cadimphr: '',
          cadusuimp: '',
          cadlocal: '',
          cadgrpai: 400, // TODO: busca do cadpai
          cadsgpai: 1, // TODO: busca do cadpai
          cadsgrfil: int.tryParse(itemPeca.grupo ?? '') ?? 400,
          cadsgfil: int.tryParse(itemPeca.subgrupo ?? '') ?? 2,
          cadoriemb: 0,
          cadproj: 'IMP3CAD',
          cadarquivo: '',
          cadcobr:
              double.parse(itemPeca.comprimento!) > 0
                  ? double.parse(itemPeca.comprimento!)
                  : 0.00,
          cadlabr:
              double.parse(itemPeca.largura!) > 0
                  ? double.parse(itemPeca.largura!)
                  : 0.00,
          cadesbr:
              double.parse(itemPeca.espessura!) > 0
                  ? double.parse(itemPeca.espessura!)
                  : 0.00,
          cadclass: '',
          cadplcor:
              itemPeca.largura != null && double.parse(itemPeca.largura!) > 0
                  ? 'S'
                  : 'N',
          cadusamed: 'N',
          cadborint: 'N',
          cadbordsup:
              itemPeca.fitatra != null && itemPeca.fitatra != 'N' ? 'S' : 'N',
          cadbordinf:
              itemPeca.fitafre != null && itemPeca.fitafre != 'N' ? 'S' : 'N',
          cadboresq:
              itemPeca.fitaesq != null && itemPeca.fitaesq != 'N' ? 'S' : 'N',
          cadbordir:
              itemPeca.fitadir != null && itemPeca.fitadir != 'N' ? 'S' : 'N',
          cadpaiarea: 0.0,
          cadtpfil: '',
          cadpembpr: 0,
          cadpembpp: 0,
          cadindter: 'S',
          caddimper: 0.00,
          cadapp: 'PDM',
        );
        final error = await homeScreenRepository.saveCadireta(
          cadireta,
          contadorItemPeca,
          'estrutura',
        );
        if (error != "") {
          saveOKCadireta.add(error);
        }

        final result = await getEstruturaExpandida(
          itemPeca.codpeca!,
          itemPeca.variaveis!,
          itemPeca.comprimento!,
          itemPeca.largura!,
          itemPeca.espessura!,
        );
        if (result == "Erro") {
          // saveOKCadireta.add(result);
          // aqui não é um erro, ele somente não carrega estrutura no item pai
        } else {
          List<Map<String, dynamic>> estrutura =
              List<Map<String, dynamic>>.from(json.decode(result));

          for (var item in estrutura) {
            var fase = item['FASE'];
            if (fase != '') {
              contadorItemCompra = contadorItemCompra + 1;
              var nome = item['CODFIG'];
              var des = item['DESCRICAO'];
              var qta = item['QTA'];
              var grupo = await homeScreenRepository.getProdutoForId(
                nome,
                'grupo_produto',
              );
              var subgrupo = await homeScreenRepository.getProdutoForId(
                nome,
                'subgrupo_produto',
              );
              var um = await homeScreenRepository.getProdutoForId(
                nome,
                'um_produto',
              );
              //var origem = await homeScreenRepository.getProdutoForId(nome, 'origem_produto');
              //var status = await homeScreenRepository.getProdutoForId(nome, 'status_produto');
              var fase = await homeScreenRepository.getProdutoForId(
                nome,
                'fase_padrao_consumo',
              );
              Cadireta cadireta = Cadireta(
                cadcont: contadorItemPeca,
                cadpai: codpeca,
                cadfilho: nome,
                cadstatus: 'C',
                cadsuscad: 'IMP3CAD',
                cadpainome: itemPeca.idpeca!,
                cadfilnome: des,
                cadpaium: 'UN',
                cadfilum: um,
                caduso: double.parse(qta),
                cadcomp: 0,
                cadlarg: 0,
                cadesp: 0,
                cadpeso: 0.0,
                cadfase: int.tryParse(fase) ?? 40,
                cadgrav: getDateFormated(DateTime.now()),
                cadhora: DateFormat.Hms().format(DateTime.now()),
                cadimpdt: getDateFormated(DateTime.now()),
                cadimphr: '',
                cadusuimp: '',
                cadlocal: '',
                cadgrpai: int.tryParse(itemPeca.grupo ?? '') ?? 400,
                cadsgpai: int.tryParse(itemPeca.subgrupo ?? '') ?? 2,
                cadsgrfil: int.tryParse(grupo) ?? 100, // TODO: buscar do banco
                cadsgfil: int.tryParse(subgrupo) ?? 1, // TODO: buscar do banco
                cadoriemb: 0,
                cadproj: 'IMP3CAD',
                cadarquivo: '',
                cadcobr:
                    double.parse(itemPeca.comprimento!) > 0
                        ? double.parse(itemPeca.comprimento!)
                        : 0.00,
                cadlabr:
                    double.parse(itemPeca.largura!) > 0
                        ? double.parse(itemPeca.largura!)
                        : 0.00,
                cadesbr:
                    double.parse(itemPeca.espessura!) > 0
                        ? double.parse(itemPeca.espessura!)
                        : 0.00,
                cadclass: '',
                cadplcor:
                    itemPeca.largura != null &&
                            double.parse(itemPeca.largura!) > 0
                        ? 'S'
                        : 'N',
                cadusamed: 'N',
                cadborint: 'N',
                cadbordsup:
                    itemPeca.fitatra != null && itemPeca.fitatra != 'N'
                        ? 'S'
                        : 'N',
                cadbordinf:
                    itemPeca.fitafre != null && itemPeca.fitafre != 'N'
                        ? 'S'
                        : 'N',
                cadboresq:
                    itemPeca.fitaesq != null && itemPeca.fitaesq != 'N'
                        ? 'S'
                        : 'N',
                cadbordir:
                    itemPeca.fitadir != null && itemPeca.fitadir != 'N'
                        ? 'S'
                        : 'N',
                cadpaiarea: 0.0,
                cadtpfil: '',
                cadpembpr: 0,
                cadpembpp: 0,
                cadindter: 'S',
                caddimper: 0.00,
                cadapp: 'PDM',
              );
              final error = await homeScreenRepository.saveCadireta(
                cadireta,
                contadorItemCompra,
                'comprado',
              );
              if (error != "") {
                saveOKCadireta.add(error);
              }
              Cadiredi cadiredi = Cadiredi(
                cadcont: contadorItemPeca,
                cadpai: codpeca,
                cadfilho: nome,
                caddseq: 0,
                caddcom: double.tryParse(itemPeca.comprimento ?? '') ?? 0.0,
                caddlar: double.tryParse(itemPeca.largura ?? '') ?? 0.0,
                caddesp: double.tryParse(itemPeca.espessura ?? '') ?? 0.0,
                caddcob: double.tryParse(itemPeca.comprimento ?? '') ?? 0.0,
                caddlab: double.tryParse(itemPeca.largura ?? '') ?? 0.0,
                caddesb: double.tryParse(itemPeca.espessura ?? '') ?? 0.0,
                cadcor: fase == "40" ? "S" : "N",
                caddbint: "N",
                caddbsup:
                    (itemPeca.fitatra?.trim().toUpperCase() == 'S') ? 'S' : 'N',
                caddbinf:
                    (itemPeca.fitafre?.trim().toUpperCase() == 'S') ? 'S' : 'N',
                caddbesq:
                    (itemPeca.fitaesq?.trim().toUpperCase() == 'S') ? 'S' : 'N',
                caddbdir:
                    (itemPeca.fitadir?.trim().toUpperCase() == 'S') ? 'S' : 'N',
                caddpdes: '',
              );
              final errorCadiredi = await homeScreenRepository.saveCadiredi(
                cadiredi,
                contadorItemCompra,
                'cadiredi',
              );
              if (errorCadiredi != "") {
                saveOKCadireta.add(errorCadiredi);
              }
            }
          }
        }
      }
    }
    if (saveOKCadireta.isNotEmpty) {
      cadiretaSuccess.value = false;
    } else {
      cadiretaSuccess.value = true;
    }
  }

  Future<String> getEstruturaExpandida(
    String codPeca,
    String variaveis,
    String comp,
    String larg,
    String esp,
  ) async {
    final result = await homeScreenRepository.getEstruturaExpandida(
      codPeca,
      variaveis,
      double.parse(comp),
      double.parse(larg),
      double.parse(esp),
    );
    if (result.isEmpty) {
      return "Erro";
    } else {
      return result;
    }
  }

  void sync3Cad() {}

  Future<void> generateCompradosReport() async {
    await pdfService.printCompradosReport(outliteData.value!);
  }

  Future<void> generateFabricadosReport() async {
    isGeneratingReport.value = true;
    try {
      final Map<String, Map<String, double>> fabricados = {};

      for (var itembox in outliteData.value!.itembox!) {
        for (var itemPecas in itembox.itemPecas!) {
          final result = await getEstruturaExpandida(
            itemPecas.codpeca!,
            itemPecas.variaveis!,
            itemPecas.comprimento!,
            itemPecas.largura!,
            itemPecas.espessura!,
          );
          if (result.isNotEmpty && result != "Erro") {
            List<Map<String, dynamic>> resultados =
                List<Map<String, dynamic>>.from(json.decode(result));
            for (var item in resultados) {
              final fase = item['FASE'] ?? 'Sem Fase';
              final key = '${item['CODFIG']} - ${item['DESCRICAO']}';
              if (!fabricados.containsKey(fase)) {
                fabricados[fase] = {};
              }
              fabricados[fase]![key] =
                  (fabricados[fase]![key] ?? 0) + double.parse(item['QTA']);
            }
          }
        }
      }
      await pdfService.printFabricadosReport(outliteData.value!, fabricados);
    } finally {
      isGeneratingReport.value = false;
    }
  }
}

getDateFormated(DateTime dateTime) {
  final formatter = DateFormat('yyyy-MM-dd');
  String formattedTime = formatter.format(dateTime);
  return DateTime.parse(formattedTime);
}

Future<String> executaEspecialESP0019(
  String batismo,
  int grupo,
  int subgrupo,
  int sequencia,
) async {
  String valorCodigo = '';
  final directory = 'C:\\Industrial';
  final command = 'ESP0019.exe XX $batismo $grupo $subgrupo';

  try {
    // Executa o processo via cmd
    final process = await Process.start(
      'cmd.exe',
      ['/c', command],
      workingDirectory: directory,
      runInShell: true,
      mode: ProcessStartMode.normal, // ou .detached se quiser ocultar
    );

    // Aguarda o término
    await process.exitCode;

    // Lê o arquivo gerado
    final caminhoArquivo = '${Directory.systemTemp.path}\\tprodcad.con';
    final file = File(caminhoArquivo);

    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (final linha in lines) {
        if (linha.contains('&ultproduto')) {
          valorCodigo = linha.substring(linha.indexOf(' ') + 1).trim();
          break;
        }
      }
    } else {
      return 'E_$sequencia';
    }
  } catch (e) {
    return 'C_$sequencia';
  }

  return valorCodigo;
}

Future<void> executaEspecialES05072(BuildContext context, int cadcont) async {
  final directory = 'C:\\Industrial';
  final command = 'ES05072.exe $cadcont';

  try {
    final process = await Process.start(
      'cmd.exe',
      ['/c', command],
      workingDirectory: directory,
      runInShell: true,
      mode: ProcessStartMode.normal, // ou .detached para ocultar
    );

    await process.exitCode;
  } catch (e) {
    // Exibe um diálogo de erro no Flutter
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Erro'),
            content: Text('Erro ao executar o ES05072:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
