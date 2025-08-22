import 'dart:convert';
import 'dart:io';
import 'package:dartt_integraforwood/Models/cadiredi.dart';
import 'package:dartt_integraforwood/Models/cadireta.dart';
import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:dartt_integraforwood/Models/xml_history.dart';
import 'package:dartt_integraforwood/Pages/homescreen/repository/home_screen_repository.dart';
import 'package:dartt_integraforwood/commom/commom_functions.dart';
import 'package:dartt_integraforwood/commom/pdf_service.dart';
import 'package:dartt_integraforwood/db/postgres_connection.dart';
import 'package:dartt_integraforwood/db/sqlserver_connection.dart';
import 'package:dartt_integraforwood/services/xml_importado_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Classes Outlite, ItemBox e ItemPecas (fornecidas anteriormente)

class HomeScreenController extends GetxController {
  final homeScreenRepository = HomeScreenRepository();
  final pdfService = PdfService();
  final xmlImportadoService = XmlImportadoService();

  bool databaseOn = false;
  bool databasePro = false;

  RxBool isLoading = false.obs;
  RxString statusMessage = ''.obs;
  RxBool isGeneratingReport = false.obs;
  RxBool saveCadiretaLoading = false.obs;
  RxList saveOKCadireta = [].obs;
  RxBool cadiretaSuccess = false.obs;

  // Status da conexão SQL Server
  RxBool sqlServerConnected = false.obs;
  RxString sqlServerStatus = 'Verificando conexão...'.obs;
  RxString sqlServerError = ''.obs;

  // Variáveis para armazenar dados enviados às tabelas PostgreSQL
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _sentCadiretaData = [];

  // Getters para acessar os dados enviados
  List<Map<String, dynamic>> get sentCadiretaData =>
      List.unmodifiable(_sentCadiretaData);

  @override
  void onInit() {
    super.onInit();
    _initializeConnections();
  }

  Future<void> _initializeConnections() async {
    await connectDatabase();
    await connectSqlServer();
  }

  onDispose() {
    super.dispose();
    PostgresConnection().close();
    SqlServerConnection.getInstance().close();
  }

  Future<void> connectDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('hostFW') ?? 'localhost';
    // Tentar obter porta como int primeiro (compatibilidade), depois como string
    int port;
    try {
      port = prefs.getInt('portFW') ?? 5432;
    } catch (e) {
      final portString = prefs.getString('portFW') ?? '5432';
      port = int.tryParse(portString) ?? 5432;
    }
    final database = prefs.getString('databaseFW') ?? '3F1B';
    final username = prefs.getString('userNameFW') ?? 'postgres';
    final password = prefs.getString('passwordFW') ?? 'postgres';

    final conected = await PostgresConnection().connect(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );
    setDatabaseon(conected);
  }

  Future<void> connectSqlServer() async {
    try {
      sqlServerStatus.value = 'Conectando ao SQL Server...';
      sqlServerError.value = '';

      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('hostSQL') ?? 'NOTEDARTT\\ECADPRO2019';
      // Tentar obter porta como int primeiro (compatibilidade), depois como string
      String port;
      try {
        final portInt = prefs.getInt('portSQL') ?? 1433;
        port = portInt.toString();
      } catch (e) {
        port = prefs.getString('portSQL') ?? '1433';
      }
      final database = prefs.getString('databaseSQL') ?? 'Moveis3F1B';
      final username = prefs.getString('userNameSQL') ?? 'sa';
      final password = prefs.getString('passwordSQL') ?? 'eCadPro2019';

      sqlServerStatus.value = 'Tentando conectar em $ip...';

      final conected = await SqlServerConnection.getInstance()
          .connectWithProgress(
            ip: ip,
            port: port,
            database: database,
            username: username,
            password: password,
            onProgress: (attempt, total, driver) {
              sqlServerStatus.value = 'Tentativa $attempt de $total: $driver';
            },
          );

      if (conected) {
        sqlServerConnected.value = true;
        sqlServerStatus.value = 'Conectado ao SQL Server ($ip)';
        sqlServerError.value = '';
      } else {
        sqlServerConnected.value = false;
        sqlServerStatus.value = 'Falha na conexão';
        sqlServerError.value =
            'Não foi possível conectar ao servidor $ip. Verifique:\n• Se o SQL Server está rodando\n• Se o serviço SQL Server Browser está ativo\n• Configurações de firewall\n• Nome da instância e credenciais';
      }

      setDatabasePro(conected);
    } catch (e) {
      sqlServerConnected.value = false;
      sqlServerStatus.value = 'Erro na conexão';
      sqlServerError.value = 'Erro: $e';
      setDatabasePro(false);
    }
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
    String codMestre = '';

    if (testas.isNotEmpty && righes.isNotEmpty) {
      final testa = testas.first;
      final righeElement = righes.first;

      // Ler CODPAIPED antes de criar o outlite
      codMestre =
          parsedXml.findAllElements('CODPAIPED').isNotEmpty
              ? parsedXml.findAllElements('CODPAIPED').first.innerText
              : 'CRIAR CÓDIGO';

      final outlite = Outlite(
        data:
            testa.findElements('DATA').isNotEmpty
                ? testa.findElements('DATA').first.innerText
                : null,
        numero:
            testa.findElements('NUMERO').isNotEmpty
                ? testa.findElements('NUMERO').first.innerText
                : null,
        numeroFabricacao: null,
        dataDesenho: null,
        rif:
            testa.findElements('RIF').isNotEmpty
                ? testa.findElements('RIF').first.innerText
                : 'SEM DESCRICAO',
        fileName: fileName,
        itembox: [],
        codpai: codMestre,
      );

      final List<ItemBox> itemBoxList = [];
      /*codMestre =
          parsedXml
              .findAllElements('CODPAIPED')
              // ignore: deprecated_member_use
              .map((node) => node.text)
              .first;*/

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
            itemPecas: await getItemPecas(
              distintatLines,
              codigo,
              testa.findElements('NUMERO').isNotEmpty
                  ? testa.findElements('NUMERO').first.innerText
                  : null,
              outlite, // Passar o objeto outlite
            ),
            itemPrice: await getPriceItems(
              dettprezzoLines,
              codigo,
              testa.findElements('NUMERO').isNotEmpty
                  ? testa.findElements('NUMERO').first.innerText
                  : null,
            ),
          ),
        );
      }

      outlite.itembox = itemBoxList;
      outliteData.value = outlite;
    }
  }

  Future<List<ItemPecas>> getItemPecas(
    RxMap<String, List<String>>? distintatLines,
    String? codigo,
    String? numeroXml,
    Outlite? outlite,
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
          // Extrair matrícula do último campo
          String? matricula;
          if (partes.isNotEmpty) {
            String ultimoCampo = partes.last;
            RegExp regexMatricula = RegExp(r'#M\d+/\d+/(\d+)');
            Match? match = regexMatricula.firstMatch(ultimoCampo);
            if (match != null) {
              String numeroMatricula = match.group(1)!;
              // Formatar matrícula com número de fabricação se disponível
              if (outlite?.numeroFabricacao != null) {
                matricula = formatMatricula(
                  outlite!.numeroFabricacao.toString(),
                  numeroMatricula,
                );
              } else {
                matricula = numeroMatricula;
              }
            }
          }

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
              matricula: matricula,

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
          );
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
      // Salvar no banco PostgreSQL (ForWood)
      await saveCadireta(outliteData.value!);

      // Se o salvamento foi bem-sucedido, salvar também no SQLite
      if (saveOKCadireta.isEmpty && cadiretaSuccess.value == true) {
        await _saveXmlToSqlite(outliteData.value!, xmlString);
      }
    }

    saveCadiretaLoading.value = false;
  }

  // Método para salvar XML e dados JSON no SQLite
  Future<void> _saveXmlToSqlite(Outlite outlite, String? xmlString) async {
    try {
      // Coletar dados JSON das tabelas
      final jsonCadiredi = await _collectCadirediData(outlite);
      final jsonCadireta = await _collectCadiretaData(outlite);
      final jsonCadproce = await _collectCadproceData(outlite);
      final jsonOutlite = await _collectOutliteData(outlite);

      final xmlImportado = XmlImportado(
        numero: outlite.numero ?? '',
        rif: outlite.rif,
        pai: outlite.codpai,
        data: outlite.dataDesenho ?? DateTime.now().toIso8601String(),
        numeroFabricacao: '', // Será preenchido pelo usuário posteriormente
        status: StatusXml.aguardando.value,
        jsonCadiredi: jsonCadiredi,
        jsonCadireta: jsonCadireta,
        jsonCadproce: jsonCadproce,
        jsonOutlite: jsonOutlite,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Tentar salvar no SQLite com verificação de duplicata
      try {
        await xmlImportadoService.insertOrUpdateXmlImportado(xmlImportado);
      } catch (e) {
        if (e.toString().contains('XML_ALREADY_EXISTS')) {
          // Mostrar diálogo de confirmação
          final shouldOverwrite = await _showOverwriteDialog(
            outlite.numero ?? '',
          );

          if (shouldOverwrite) {
            try {
              await xmlImportadoService.insertOrUpdateXmlImportado(
                xmlImportado,
                forceUpdate: true,
              );
              Get.snackbar(
                'Sucesso',
                'Nova revisão criada com sucesso!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            } catch (revisionError) {
              if (revisionError.toString().contains(
                'está em produção ou finalizado',
              )) {
                Get.snackbar(
                  'Erro',
                  'Não é possível criar nova revisão. O XML está em produção ou finalizado.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Erro',
                  'Erro ao criar nova revisão: $revisionError',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          } else {
            Get.snackbar(
              'Cancelado',
              'Operação cancelada pelo usuário.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar XML: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Método para mostrar diálogo de confirmação
  Future<bool> _showOverwriteDialog(String numeroXml) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('XML Duplicado'),
            content: Text(
              'Já existe um XML com o número "$numeroXml".\n\nDeseja criar uma nova revisão?\nAo criar uma nova revisão, os dados anteriores serão mantidos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Criar Nova Revisão'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Métodos para coletar dados JSON das tabelas

  Future<String> _collectCadirediData(Outlite outlite) async {
    try {
      return jsonEncode(outlite.toMap());
    } catch (e) {
      return '{}';
    }
  }

  Future<String> _collectCadiretaData(Outlite outlite) async {
    try {
      return jsonEncode(_sentCadiretaData);
    } catch (e) {
      return '[]';
    }
  }

  Future<String> _collectCadproceData(Outlite outlite) async {
    try {
      return jsonEncode(outlite.toMap());
    } catch (e) {
      return '{}';
    }
  }

  Future<String> _collectOutliteData(Outlite outlite) async {
    try {
      return jsonEncode(outlite.toMap());
    } catch (e) {
      return '{}';
    }
  }

  Future<List<ItemPrice>> getPriceItems(
    RxMap<String, List<String>> dettprezzoLines,
    String codigo,
    String? numeroXml, // Adicionar parâmetro para o número do XML
  ) async {
    List<ItemPrice> itemPrice = [];
    if (dettprezzoLines.isNotEmpty) {
      for (var lineDP in dettprezzoLines[codigo]!) {
        List<String> partesDP = lineDP.split(';');
        if (partesDP.length > 1) {
          // Extrair matrícula do último campo
          String? matricula;
          if (partesDP.isNotEmpty) {
            String ultimoCampo = partesDP.last;
            // Procurar por padrão #M8/71/NUMERO ou similar
            RegExp regexMatricula = RegExp(r'#M\d+/\d+/(\d+)');
            Match? match = regexMatricula.firstMatch(ultimoCampo);
            if (match != null) {
              String numeroMatricula =
                  match.group(1)!; // Captura o número da matrícula
              // Aplicar a formatação usando o número do XML e o número da matrícula
              matricula = formatMatricula(numeroXml, numeroMatricula);
            }
          }

          itemPrice.add(
            ItemPrice(
              codigo: partesDP[1],
              des: await homeScreenRepository.getDescricaoProduto(partesDP[1]),
              qtd: partesDP[6],
              matricula: matricula, // Adicionar a matrícula extraída
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
    // Limpar dados anteriores
    _sentCadiretaData.clear();

    await homeScreenRepository.deleteCadireta();
    await homeScreenRepository.deleteCadiredi();
    int contador = 0;
    int contadorItemPeca = 0;
    int contadorItemCompra = 0;

    // Obter o valor de codbatismomodulo do SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final codbatismocorte = prefs.getString('codbatismocorte') ?? '52';

    // Salva os dados do pai
    for (var oi in outlite.itembox!) {
      contador = contador + 1;
      // var codpai = oi.codigo ?? '';
      var despai = oi.des ?? '';
      var codpai = await executaEspecialESP0019(
        codbatismocorte,
        500,
        8,
        contador,
        'P',
      );
      Cadireta cadireta = Cadireta(
        cadcont: contador,
        cadpai: outlite.codpai,
        cadfilho: codpai,
        cadstatus: 'N',
        cadsuscad: 'IMP3CAD',
        cadpainome: outlite.rif,
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
        cadindter: 'S',
        caddimper: 0.00,
        cadapp: 'PDM',
      );
      final error = await homeScreenRepository.saveCadireta(
        cadireta,
        contadorItemPeca,
        'pai',
      );
      if (error == "") {
        // Adicionar aos dados enviados apenas se salvamento foi bem-sucedido
        _sentCadiretaData.add(cadireta.toMap());
      } else {
        saveOKCadireta.add(error);
      }
      // Salva os dados do filho (estrutura)
      for (var itemPeca in oi.itemPecas!) {
        contadorItemPeca = contadorItemPeca + 1;
        String codpeca = itemPeca.codpeca!;
        if (double.parse(itemPeca.comprimento!) >= 0 &&
            double.parse(itemPeca.largura!) >= 0 &&
            double.parse(itemPeca.espessura!) >= 0) {
          // Obter o valor de codbatismomodulo do SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final codbatismomodulo =
              prefs.getString('codbatismomodulo') ?? '4.1.';

          codpeca = await executaEspecialESP0019(
            codbatismomodulo,
            500,
            8,
            contadorItemPeca,
            'F',
          );
        }

        Cadireta cadireta = Cadireta(
          cadcont: contadorItemPeca,
          cadpai: codpai,
          cadfilho: codpeca,
          cadstatus: 'N',
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
          cadindter: 'S',
          caddimper: 0.00,
          cadapp: 'PDM',
        );

        final error = await homeScreenRepository.saveCadireta(
          cadireta,
          contadorItemPeca,
          'estrutura',
        );
        if (error == "") {
          // Adicionar aos dados enviados apenas se salvamento foi bem-sucedido
          _sentCadiretaData.add(cadireta.toMap());
        } else {
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
            cadstatus: 'N',
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
                fase == '20'
                    ? getCompBord(itemPeca)
                    : double.parse(itemPeca.comprimento!) > 0
                    ? double.parse(itemPeca.comprimento!)
                    : 0.00,
            cadlabr:
                fase == '20'
                    ? getLarBord(itemPeca)
                    : double.parse(itemPeca.largura!) > 0
                    ? double.parse(itemPeca.largura!)
                    : 0.00,
            cadesbr: 0.00,
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
            cadindter: 'N',
            caddimper: 0.00,
            cadapp: 'PDM',
            cadmatricula: itemPeca.matricula,
          );

              final error = await homeScreenRepository.saveCadireta(
                cadireta,
                contadorItemCompra,
                'comprado',
              );
              if (error == "") {
                // Adicionar aos dados enviados apenas se salvamento foi bem-sucedido
                _sentCadiretaData.add(cadireta.toMap());
              } else {
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

getLarBord(ItemPecas itemPeca) {
  var contafita = 0;
  if (itemPeca.fitaesq != null && itemPeca.fitaesq != 'N') {
    contafita++;
  }
  if (itemPeca.fitadir != null && itemPeca.fitadir != 'N') {
    contafita++;
  }
  if (contafita > 0) {
    return double.parse(itemPeca.largura!) * (contafita);
  } else {
    return 0.00;
  }
}

getCompBord(ItemPecas itemPeca) {
  var contafita = 0;
  if (itemPeca.fitafre != null && itemPeca.fitafre != 'N') {
    contafita++;
  }
  if (itemPeca.fitatra != null && itemPeca.fitatra != 'N') {
    contafita++;
  }
  if (contafita > 0) {
    return double.parse(itemPeca.comprimento!) * (contafita);
  } else {
    return 0.00;
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
  String type,
) async {
  String valorCodigo = '';
  // Obter o diretório ESP do SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final directory = prefs.getString('diretorioESP') ?? 'C:\\Industrial';
  // Remover a barra final se existir para garantir consistência
  final directoryPath =
      directory.endsWith('\\')
          ? directory.substring(0, directory.length - 1)
          : directory;
  final command = 'ESP0019.exe XX $batismo $grupo $subgrupo';

  try {
    // Executa o processo via cmd
    final process = await Process.start(
      'cmd.exe',
      ['/c', command],
      workingDirectory: directoryPath,
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
      return '$type"_"$sequencia';
    }
  } catch (e) {
    return 'C_$sequencia';
  }

  return valorCodigo;
}

Future<void> executaEspecialES05072(BuildContext context, int cadcont) async {
  // Obter o diretório ESP do SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final directory = prefs.getString('diretorioESP') ?? 'C:\\Industrial';
  // Remover a barra final se existir para garantir consistência
  final directoryPath =
      directory.endsWith('\\')
          ? directory.substring(0, directory.length - 1)
          : directory;
  final command = 'ES05072.exe $cadcont';

  try {
    final process = await Process.start(
      'cmd.exe',
      ['/c', command],
      workingDirectory: directoryPath,
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
