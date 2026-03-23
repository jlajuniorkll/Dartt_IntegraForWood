import 'dart:convert';
import 'dart:io';
import 'package:dartt_integraforwood/Models/cadire2.dart';
import 'package:dartt_integraforwood/Models/cadiredi.dart';
import 'package:dartt_integraforwood/Models/cadireta.dart';
import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:dartt_integraforwood/Models/xml_history.dart';
import 'package:dartt_integraforwood/Pages/common/progress_step.dart';
import 'package:dartt_integraforwood/Pages/homescreen/repository/home_screen_repository.dart';
import 'package:dartt_integraforwood/commom/commom_functions.dart';
import 'package:dartt_integraforwood/commom/pdf_service.dart';
import 'package:dartt_integraforwood/db/postgres_connection.dart';
import 'package:dartt_integraforwood/db/sqlserver_connection.dart';
import 'package:dartt_integraforwood/services/app_logger.dart';
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
  RxList<ProgressStep> loadProgressSteps = <ProgressStep>[].obs;
  RxBool isGeneratingReport = false.obs;
  RxBool saveCadiretaLoading = false.obs;
  RxList<ProgressStep> saveProgressSteps = <ProgressStep>[].obs;
  RxList saveOKCadireta = [].obs;
  RxBool cadiretaSuccess = false.obs;

  // Status da conexão SQL Server
  RxBool sqlServerConnected = false.obs;
  RxString sqlServerStatus = 'Verificando conexão...'.obs;
  RxString sqlServerError = ''.obs;

  // Variáveis para armazenar dados enviados às tabelas PostgreSQL
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _sentCadiretaData = [];
  String? _lastSavedCadire2Json;

  // Getters para acessar os dados enviados
  List<Map<String, dynamic>> get sentCadiretaData =>
      List.unmodifiable(_sentCadiretaData);
  String? get lastSavedCadire2Json => _lastSavedCadire2Json;

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
    if (conected) {
      AppLogger.i('ForWood', 'PostgreSQL conectado ($host:$port/$database)');
    } else {
      AppLogger.w('ForWood', 'PostgreSQL não conectou ($host:$port/$database)');
    }
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

  void _initLoadProgressSteps({int totalItems = 0}) {
    loadProgressSteps.value = [
      ProgressStep(label: 'Analisando XML', status: StepStatus.pending),
      ProgressStep(label: 'Extraindo dados', status: StepStatus.pending),
      ProgressStep(
        label: totalItems > 0 ? 'Processando item 0 de $totalItems' : 'Processando itens',
        status: StepStatus.pending,
      ),
      ProgressStep(
        label: 'Buscando descrições no PostgreSQL',
        status: StepStatus.pending,
      ),
      ProgressStep(label: 'Finalizando', status: StepStatus.pending),
    ];
  }

  void _updateLoadStep(int index, StepStatus status, {String? label}) {
    if (index >= 0 && index < loadProgressSteps.length) {
      final step = loadProgressSteps[index];
      loadProgressSteps[index] = step.copyWith(
        status: status,
        label: label ?? step.label,
      );
    }
  }

  void _initSaveProgressSteps({int totalModules = 0, bool includeCadire2 = false}) {
    saveProgressSteps.value = [
      ProgressStep(label: 'Verificando estrutur...', status: StepStatus.pending),
      ProgressStep(
        label: totalModules > 0
            ? 'Processando módulo 0 de $totalModules'
            : 'Processando módulos',
        status: StepStatus.pending,
      ),
      ProgressStep(
        label: 'Excluindo tabelas cadireta e cadiredi',
        status: StepStatus.pending,
      ),
      ProgressStep(
        label: 'Inserindo cadireta e cadiredi',
        status: StepStatus.pending,
      ),
      if (includeCadire2)
        ProgressStep(label: 'Inserindo cadire2', status: StepStatus.pending),
      ProgressStep(label: 'Finalizando', status: StepStatus.pending),
    ];
  }

  void _updateSaveStep(int index, StepStatus status, {String? label}) {
    if (index >= 0 && index < saveProgressSteps.length) {
      final step = saveProgressSteps[index];
      saveProgressSteps[index] = step.copyWith(
        status: status,
        label: label ?? step.label,
      );
    }
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

      // Obter total de itens para progresso
      final preParsed = XmlDocument.parse(xmlString);
      final righes = preParsed.findAllElements('RIGHE').toList();
      final totalItems = righes.isNotEmpty
          ? righes.first.children.whereType<XmlElement>().length
          : 0;

      _initLoadProgressSteps(totalItems: totalItems);

      _updateLoadStep(0, StepStatus.current); // Analisando XML
      _updateLoadStep(0, StepStatus.done);

      await extractData(preParsed, fileName);

      _updateLoadStep(4, StepStatus.done); // Finalizando
      statusMessage.value = 'Importado com sucesso...';
      isLoading.value = false;
      AppLogger.i('XML', 'Importado: $fileName');
    } catch (e) {
      AppLogger.e('XML', 'Falha ao carregar/analisar XML ($fileName)', error: e);
      isLoading.value = false;
    }
  }

  Future<void> extractData(XmlDocument parsedXml, String fileName) async {
    statusMessage.value = 'Extraindo dados do XML...';
    _updateLoadStep(1, StepStatus.current); // Extraindo dados

    final testas = parsedXml.findAllElements('TESTA');
    final righes = parsedXml.findAllElements('RIGHE').toList();
    String codMestre = '';

    if (testas.isNotEmpty && righes.isNotEmpty) {
      final testa = testas.first;
      final righeElement = righes.first;
      final righeList = righeElement.children.whereType<XmlElement>().toList();

      // Ler CODPAIPED antes de criar o outlite
      codMestre =
          parsedXml.findAllElements('CODPAIPED').isNotEmpty
              ? parsedXml.findAllElements('CODPAIPED').first.innerText
              : '6.8.0.0108';

      _updateLoadStep(1, StepStatus.done);
      _updateLoadStep(2, StepStatus.current); // Processando itens

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

      outlite.codpaiPedidoExisteNaEstrutur =
          await homeScreenRepository.estprodutoExisteEmEstrutur(outlite.codpai);

      final List<ItemBox> itemBoxList = [];
      /*codMestre =
          parsedXml
              .findAllElements('CODPAIPED')
              // ignore: deprecated_member_use
              .map((node) => node.text)
              .first;*/

      for (var i = 0; i < righeList.length; i++) {
        final riga = righeList[i];
        _updateLoadStep(
          2,
          StepStatus.current,
          label: 'Processando item ${i + 1} de ${righeList.length}',
        );
        _updateLoadStep(3, StepStatus.current); // Buscando descrições

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

      _updateLoadStep(2, StepStatus.done);
      _updateLoadStep(3, StepStatus.done);
      _updateLoadStep(4, StepStatus.current); // Finalizando

      outlite.itembox = itemBoxList;
      if (outlite.codpaiPedidoExisteNaEstrutur == false) {
        _limparFlagsPendenteCadastroForWood(outlite);
      }
      outliteData.value = outlite;
    } else {
      _updateLoadStep(1, StepStatus.done);
      _updateLoadStep(4, StepStatus.current);
    }
  }

  /// Sem CODPAIPED na estrutur: remove estado verde "Atualizar" (mantém texto de descrição).
  void _limparFlagsPendenteCadastroForWood(Outlite outlite) {
    for (final box in outlite.itembox ?? []) {
      for (final p in box.itemPecas ?? []) {
        if (p.precisaCadastroForWood) {
          p.precisaCadastroForWood = false;
        }
      }
      for (final ip in box.itemPrice ?? []) {
        if (ip.precisaCadastroForWood) {
          ip.precisaCadastroForWood = false;
        }
      }
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

          final resolved = await homeScreenRepository.resolveProdutoComDimensoes(
            partes[0],
            partes[3],
            partes[4],
            partes[5],
          );
          final codPg = resolved.codigoProdutoPostgres ?? partes[0];

          itemPecas.add(
            ItemPecas(
              codpeca: partes[0],
              idpeca: resolved.idpeca,
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
              codigoProdutoPostgres: resolved.codigoProdutoPostgres,
              precisaCadastroForWood: resolved.precisaCadastroForWood,
              descricaoSqlServer: resolved.descricaoSqlServer,

              grupo: await homeScreenRepository.getProdutoForId(
                codPg,
                'grupo_produto',
              ),
              subgrupo: await homeScreenRepository.getProdutoForId(
                codPg,
                'subgrupo_produto',
              ),
              um: await homeScreenRepository.getProdutoForId(
                codPg,
                'um_produto',
              ),
              origem: await homeScreenRepository.getProdutoForId(
                codPg,
                'origem_produto',
              ),
              status: await homeScreenRepository.getProdutoForId(
                codPg,
                'status_produto',
              ),
              fase: await homeScreenRepository.getProdutoForId(
                codPg,
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

  /// Envia Outlite para ForWood (cadireta, cadiredi e cadire2).
  /// Usado no Fluxo 5 (enviar para produção a partir da lista de XMLs importados).
  Future<bool> enviarOutliteParaForWood(Outlite outlite) async {
    saveCadiretaLoading.value = true;
    final totalModules = outlite.itembox?.length ?? 0;
    _initSaveProgressSteps(totalModules: totalModules, includeCadire2: true);

    final numeroPedido = outlite.numero ?? '';
    initPedidoLog(numeroPedido);
    AppLogger.i(
      'ForWood',
      'Enviar para produção: pedido $numeroPedido, fab ${outlite.numeroFabricacao ?? ""}',
    );

    try {
      await saveCadireta(
        outlite,
        progressAlreadyInited: true,
        skipFinalStep: true,
      );

      if (saveOKCadireta.isNotEmpty) {
        AppLogger.e(
          'ForWood',
          'enviarOutliteParaForWood abortado: ${saveOKCadireta.length} erro(s) cadireta',
        );
        saveCadiretaLoading.value = false;
        return false;
      }

      // Inserir CADIRE2 (informações de produção)
      _updateSaveStep(4, StepStatus.current, label: 'Inserindo cadire2');
      await _saveCadire2(outlite);
      _updateSaveStep(4, StepStatus.done);
      _updateSaveStep(5, StepStatus.done);

      saveCadiretaLoading.value = false;
      if (cadiretaSuccess.value) {
        AppLogger.i('ForWood', 'enviarOutliteParaForWood OK ($numeroPedido)');
      }
      return cadiretaSuccess.value;
    } catch (e) {
      saveCadiretaLoading.value = false;
      AppLogger.e('ForWood', 'enviarOutliteParaForWood exceção', error: e);
      rethrow;
    }
  }

  /// Aplica numeroFabricacao ao Outlite e atualiza matrículas nos ItemPecas/ItemPrice.
  void aplicarNumeroFabricacaoAoOutlite(Outlite outlite, String numeroFabricacao) {
    outlite.numeroFabricacao = numeroFabricacao;
    for (final box in outlite.itembox ?? []) {
      for (final pec in box.itemPecas ?? []) {
        if (pec.matricula != null && pec.matricula!.isNotEmpty) {
          pec.matricula = formatMatricula(
            numeroFabricacao,
            extractMatricola(pec.matricula),
          );
        }
      }
      for (final price in box.itemPrice ?? []) {
        if (price.matricula != null && price.matricula!.isNotEmpty) {
          price.matricula = formatMatricula(
            numeroFabricacao,
            extractMatricola(price.matricula),
          );
        }
      }
    }
  }

  /// Constrói e salva registros CADIRE2 a partir do Outlite (somente INSERT; não apaga a tabela nem o projeto).
  Future<void> _saveCadire2(Outlite outlite) async {
    final cadinfprod = outlite.numeroFabricacao ?? outlite.numero ?? '';
    if (cadinfprod.isEmpty) return;

    final maxCounters =
        await homeScreenRepository.getCadire2MaxCountersForProd(cadinfprod);
    final lista = _buildCadire2List(
      outlite,
      startCadinfseq: maxCounters.seq + 1,
      startCadinfcont: maxCounters.cont + 1,
    );
    _lastSavedCadire2Json = jsonEncode(lista.map((c) => c.toMap()).toList());
    int seq = 1;
    for (final c2 in lista) {
      final err = await homeScreenRepository.saveCadire2(c2, seq, 'cadire2');
      if (err.isNotEmpty) saveOKCadireta.add(err);
      seq++;
    }
  }

  /// Monta lista de Cadire2 a partir do Outlite (ItemBox -> ItemPecas).
  List<Cadire2> _buildCadire2List(
    Outlite outlite, {
    int startCadinfseq = 1,
    int startCadinfcont = 1,
  }) {
    final cadinfprod = outlite.numeroFabricacao ?? outlite.numero ?? '';
    final lista = <Cadire2>[];
    int cadinfcont = startCadinfcont;
    int cadinfseq = startCadinfseq;

    for (final box in outlite.itembox ?? []) {
      for (final pec in box.itemPecas ?? []) {
        lista.add(
          Cadire2(
            cadinfcont: cadinfcont,
            cadinfprod: cadinfprod,
            cadinfseq: cadinfseq,
            cadinfdes: pec.idpeca ?? pec.codpeca ?? '',
            cadinfinf: pec.codpeca ?? '',
          ),
        );
        cadinfcont++;
        cadinfseq++;
      }
    }
    return lista;
  }

  /// Se houver erros ou itens "Atualizar", pergunta se o usuário deseja enviar assim mesmo.
  /// Retorna `true` para prosseguir com o envio.
  Future<bool> confirmarEnvioParaForWoodSeNecessario(Outlite outlite) async {
    final nErros = outlite.totalErrosCount;
    final nAtualizar = outlite.totalPendentesCadastroCount;
    if (nErros == 0 && nAtualizar == 0) {
      return true;
    }

    final partes = <String>[];
    if (nErros > 0) {
      partes.add(
        '$nErros erro${nErros == 1 ? '' : 's'} (produto não encontrado ou falha na resolução)',
      );
    }
    if (nAtualizar > 0) {
      partes.add(
        '$nAtualizar atualização${nAtualizar == 1 ? '' : 'ões'} pendente${nAtualizar == 1 ? '' : 's'} no ForWood (cadastrar no PostgreSQL)',
      );
    }

    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Atenção antes de enviar'),
            content: Text(
              'Este pedido possui:\n• ${partes.join('\n• ')}\n\n'
              'Deseja enviar para o ForWood mesmo assim?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Enviar mesmo assim'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> saveDataBase({Outlite? outlite, String? xmlString}) async {
    saveCadiretaLoading.value = true;

    // Inicia arquivo de log do pedido ao enviar para ForWood
    final numeroPedido = outlite?.numero ?? '';
    initPedidoLog(numeroPedido);
    AppLogger.i('ForWood', 'Início envio cadireta/cadiredi pedido $numeroPedido');

    if (outliteData.value != null) {
      // Salvar no banco PostgreSQL (ForWood)
      await saveCadireta(outliteData.value!);

      // Se o salvamento foi bem-sucedido, salvar também no SQLite
      if (saveOKCadireta.isEmpty && cadiretaSuccess.value == true) {
        await _saveXmlToSqlite(outliteData.value!, xmlString);
        AppLogger.i('ForWood', 'Envio concluído com sucesso ($numeroPedido)');
      } else if (saveOKCadireta.isNotEmpty) {
        AppLogger.e(
          'ForWood',
          'Envio com erros ($numeroPedido): ${saveOKCadireta.length} falha(s)',
        );
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

      // Registra a tentativa de salvar cadproce
      final jsonCadproceMap = jsonDecode(jsonCadproce) as Map<String, dynamic>;
      appendPedidoLog('cadproce', jsonCadproceMap);

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
      AppLogger.e('SQLite', 'Erro ao salvar XML importado', error: e);
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

          final resolvedCompra =
              await homeScreenRepository.resolveProdutoCodigoCompra(partesDP[1]);

          itemPrice.add(
            ItemPrice(
              codigo: partesDP[1],
              des: resolvedCompra.idpeca,
              qtd: partesDP[6],
              matricula: matricula,
              codigoProdutoPostgres: resolvedCompra.codigoProdutoPostgres,
              precisaCadastroForWood: resolvedCompra.precisaCadastroForWood,
              descricaoSqlServer: resolvedCompra.descricaoSqlServer,
            ),
          );
        }
      }
      return itemPrice;
    } else {
      return [];
    }
  }

  String _estruturMultisetKey(
    String cod,
    String comp,
    String larg,
    String esp,
  ) {
    double normDim(String? s) {
      return double.tryParse(s?.replaceAll(',', '.').trim() ?? '') ?? 0.0;
    }

    final c = normDim(comp);
    final l = normDim(larg);
    final e = normDim(esp);
    return '${cod.trim().toUpperCase()}|${c.toStringAsFixed(4)}|${l.toStringAsFixed(4)}|${e.toStringAsFixed(4)}';
  }

  Map<String, double> _aggregateMultisetEstrutur(
    List<EstruturFilhoDetalhe> rows,
  ) {
    final map = <String, double>{};
    for (final r in rows) {
      final k = _estruturMultisetKey(
        r.estfilho,
        r.comprimento,
        r.largura,
        r.espessura,
      );
      map[k] = (map[k] ?? 0) + 1.0;
    }
    return map;
  }

  bool _multisetQtyIguais(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final vb = b[e.key];
      if (vb == null) return false;
      if ((e.value - vb).abs() > 1e-4) return false;
    }
    return true;
  }

  /// Filhos esperados: códigos PostgreSQL + dimensões + quantidades (DISTINTAT + CODFIG).
  Future<Map<String, double>> _getExpectedFilhosMultiset(ItemBox oi) async {
    final map = <String, double>{};

    for (final itemPeca in oi.itemPecas ?? []) {
      final comp = itemPeca.comprimento ?? '0';
      final larg = itemPeca.largura ?? '0';
      final esp = itemPeca.espessura ?? '0';
      final codResolved =
          (itemPeca.codigoProdutoPostgres ?? itemPeca.codpeca ?? '').trim();
      if (codResolved.isEmpty) continue;

      final q =
          double.tryParse(itemPeca.qta?.replaceAll(',', '.') ?? '0') ?? 0.0;
      final k = _estruturMultisetKey(codResolved, comp, larg, esp);
      map[k] = (map[k] ?? 0) + q;

      if (itemPeca.codpeca != null &&
          itemPeca.codpeca!.isNotEmpty &&
          double.tryParse(itemPeca.comprimento ?? '') != null &&
          double.tryParse(itemPeca.largura ?? '') != null &&
          double.tryParse(itemPeca.espessura ?? '') != null &&
          double.parse(itemPeca.comprimento!) >= 0 &&
          double.parse(itemPeca.largura!) >= 0 &&
          double.parse(itemPeca.espessura!) >= 0) {
        final result = await getEstruturaExpandida(
          itemPeca.codpeca!,
          itemPeca.variaveis ?? '',
          itemPeca.comprimento!,
          itemPeca.largura!,
          itemPeca.espessura!,
        );
        if (result.isNotEmpty && result != 'Erro') {
          try {
            final estrutura =
                List<Map<String, dynamic>>.from(json.decode(result));
            for (final item in estrutura) {
              final codfig = item['CODFIG']?.toString().trim() ?? '';
              if (codfig.isEmpty) continue;
              final qtyStr = item['QTA']?.toString() ?? '0';
              final qty =
                  double.tryParse(qtyStr.replaceAll(',', '.')) ?? 0.0;
              final resFig =
                  await homeScreenRepository.resolveProdutoComDimensoes(
                codfig,
                comp,
                larg,
                esp,
              );
              final codPg = resFig.codigoProdutoPostgres ?? codfig;
              final k2 = _estruturMultisetKey(codPg, comp, larg, esp);
              map[k2] = (map[k2] ?? 0) + qty;
            }
          } catch (_) {}
        }
      }
    }

    return map;
  }

  Future<void> saveCadireta(
    Outlite outlite, {
    bool progressAlreadyInited = false,
    bool skipFinalStep = false,
  }) async {
    // Limpar dados anteriores
    _sentCadiretaData.clear();

    final totalModules = outlite.itembox?.length ?? 0;
    if (!progressAlreadyInited) {
      _initSaveProgressSteps(totalModules: totalModules);
    }

    _updateSaveStep(0, StepStatus.current); // Verificando estrutur

    final prefs = await SharedPreferences.getInstance();
    final codbatismocorte = prefs.getString('codbatismocorte') ?? '4.1.';
    final codbatismomodulo = prefs.getString('codbatismomodulo') ?? '52';

    // Fase 1: Determinar codpai para cada ItemBox (reutilizar ou ESP0019)
    final List<String> codpaiPorModulo = [];

    var pedidoTemEstruturNaPg = outlite.codpaiPedidoExisteNaEstrutur;
    pedidoTemEstruturNaPg ??=
        await homeScreenRepository.estprodutoExisteEmEstrutur(outlite.codpai);
    outlite.codpaiPedidoExisteNaEstrutur = pedidoTemEstruturNaPg;
    if (pedidoTemEstruturNaPg != true) {
      _limparFlagsPendenteCadastroForWood(outlite);
    }

    for (var i = 0; i < (outlite.itembox ?? []).length; i++) {
      final oi = outlite.itembox![i];
      _updateSaveStep(
        1,
        StepStatus.current,
        label: 'Processando módulo ${i + 1} de $totalModules',
      );

      String codpai;
      if (pedidoTemEstruturNaPg != true) {
        codpai = await executaEspecialESP0019(
          codbatismocorte,
          500,
          8,
          i + 1,
          'P',
        );
      } else {
        final expectedMultiset = await _getExpectedFilhosMultiset(oi);
        final estParent =
            await homeScreenRepository.resolveEstprodutoParaEstrutur(
          codigoRiga: oi.codigo,
          desModulo: oi.des,
          l: oi.l,
          a: oi.a,
          p: oi.p,
        );

        if (estParent != null) {
          final dbRows =
              await homeScreenRepository.getFilhosEstruturDetalhado(estParent);
          final dbMultiset = _aggregateMultisetEstrutur(dbRows);
          if (_multisetQtyIguais(expectedMultiset, dbMultiset)) {
            codpai = estParent;
          } else {
            codpai = await executaEspecialESP0019(
              codbatismocorte,
              500,
              8,
              i + 1,
              'P',
            );
          }
        } else {
          codpai = await executaEspecialESP0019(
            codbatismocorte,
            500,
            8,
            i + 1,
            'P',
          );
        }
      }
      codpaiPorModulo.add(codpai);
    }

    _updateSaveStep(0, StepStatus.done);
    _updateSaveStep(1, StepStatus.done);
    _updateSaveStep(2, StepStatus.current); // Excluindo tabelas

    await homeScreenRepository.deleteCadireta();
    await homeScreenRepository.deleteCadiredi();

    _updateSaveStep(2, StepStatus.done);
    _updateSaveStep(3, StepStatus.current); // Inserindo cadireta e cadiredi

    int contadorPai = 0;
    int contadorFilho = 0;
    int contadorItemPeca = 1;
    int contadorItemCompra = 2;
    int contadorItemFilho = contadorItemPeca;
    String codpaiOld = '';
    String codfilhoOld = '';

    List<Cadireta> listPaiPedido = [];
    List<Cadireta> listPai = [];
    List<Cadireta> listFilho = [];
    List<Map<String, dynamic>> listaPaiMap = [];

    // Salva os dados do pai
    for (var idx = 0; idx < (outlite.itembox ?? []).length; idx++) {
      final oi = outlite.itembox![idx];
      contadorPai = contadorPai + 1;
      var despai = oi.des ?? '';
      final codpai = codpaiPorModulo[idx];
      Cadireta cadiretaPaiPedido = Cadireta(
        cadcont: 1,
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
      listPaiPedido.add(cadiretaPaiPedido);
      final error = await homeScreenRepository.saveCadireta(
        cadiretaPaiPedido,
        contadorItemPeca,
        'pai',
      );
      if (error == "") {
        // Adicionar aos dados enviados apenas se salvamento foi bem-sucedido
        _sentCadiretaData.add(cadiretaPaiPedido.toMap());
      } else {
        saveOKCadireta.add(error);
      }
      // Salva os dados do filho (estrutura)
      for (var itemPeca in oi.itemPecas!) {
        contadorFilho = contadorFilho + 1;
        String codpeca = itemPeca.codpeca!;
        if (double.parse(itemPeca.comprimento!) >= 0 &&
            double.parse(itemPeca.largura!) >= 0 &&
            double.parse(itemPeca.espessura!) >= 0) {
          codpeca = await executaEspecialESP0019(
            codbatismomodulo,
            500,
            8,
            contadorFilho,
            'F',
          );
        }
        if (codpaiOld != codpai) {
          contadorItemPeca = contadorItemPeca + 1;
        }
        codpaiOld = codpai;
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
        listPai.add(cadireta);
        listaPaiMap.add({...itemPeca.toMap(), 'codpai': codpeca});
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
      }
    }
    contadorItemFilho = contadorItemPeca + 1;
    for (var lp in listaPaiMap) {
      final result = await getEstruturaExpandida(
        lp['codpeca'], // certo
        lp['variaveis'], // certo
        lp['comprimento'], // certo
        lp['largura'], // certo
        lp['espessura'], // certo
      );
      if (result == "Erro") {
        // saveOKCadireta.add(result);
        // aqui não é um erro, ele somente não carrega estrutura no item pai
      } else {
        List<Map<String, dynamic>> estrutura = List<Map<String, dynamic>>.from(
          json.decode(result),
        );
        for (var item in estrutura) {
          var fase = item['FASE'];
          if (fase != '') {
            contadorItemCompra = contadorItemCompra + 1;
            if (codfilhoOld != lp['codpai']) {
              contadorItemFilho = contadorItemFilho + 1;
            }
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
            codfilhoOld = lp['codpai'];
            final items = ItemPecas.fromMap(lp);
            Cadireta cadireta = Cadireta(
              cadcont: contadorItemFilho,
              cadpai: lp['codpai'],
              cadfilho: nome,
              cadstatus: 'N',
              cadsuscad: 'IMP3CAD',
              cadpainome: lp['idpeca'],
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
              cadgrpai: int.tryParse(lp['grupo'] ?? '') ?? 400,
              cadsgpai: int.tryParse(lp['subgrupo'] ?? '') ?? 2,
              cadsgrfil: int.tryParse(grupo) ?? 100, // TODO: buscar do banco
              cadsgfil: int.tryParse(subgrupo) ?? 1, // TODO: buscar do banco
              cadoriemb: 0,
              cadproj: 'IMP3CAD',
              cadarquivo: '',
              cadcobr:
                  fase == '20'
                      ? getCompBord(items)
                      : double.parse(lp['comprimento']) > 0
                      ? double.parse(lp['comprimento'])
                      : 0.00,
              cadlabr:
                  fase == '20'
                      ? getLarBord(items)
                      : double.parse(lp['largura']) > 0
                      ? double.parse(lp['largura'])
                      : 0.00,
              cadesbr: 0.00,
              cadclass: '',
              cadplcor:
                  lp['largura'] != null && double.parse(lp['largura']) > 0
                      ? 'S'
                      : 'N',
              cadusamed: 'N',
              cadborint: 'N',
              cadbordsup:
                  lp['fitatra'] != null && lp['fitatra'] != 'N' ? 'S' : 'N',
              cadbordinf:
                  lp['fitafre'] != null && lp['fitafre'] != 'N' ? 'S' : 'N',
              cadboresq:
                  lp['fitaesq'] != null && lp['fitaesq'] != 'N' ? 'S' : 'N',
              cadbordir:
                  lp['fitadir'] != null && lp['fitadir'] != 'N' ? 'S' : 'N',
              cadpaiarea: 0.0,
              cadtpfil: '',
              cadpembpr: 0,
              cadpembpp: 0,
              cadindter: 'N',
              caddimper: 0.00,
              cadapp: 'PDM',
              cadmatricula: lp['matricula'],
            );
            listFilho.add(cadireta);
          }
        }
      }
    }

    ///// AGRUPA OS ITENS FILHOS PARA EVITAR DUPLICIDADE /////

    // Chama a função que agrupa por cadcont, cadpai e cadfilho, somando caduso
    final List<Cadireta> cadiretaFilhosAgrupados = agruparCadiretas(listFilho);

    // Agora salva apenas os registros agrupados
    for (final cadireta in cadiretaFilhosAgrupados) {
      final error = await homeScreenRepository.saveCadireta(
        cadireta,
        contadorItemCompra,
        'comprado',
      );

      if (error == "") {
        _sentCadiretaData.add(cadireta.toMap());
      } else {
        saveOKCadireta.add(error);
      }

      Cadiredi cadiredi = Cadiredi(
        cadcont: cadireta.cadcont,
        cadpai: cadireta.cadpai,
        cadfilho: cadireta.cadfilho,
        caddseq: 0,
        caddcom: cadireta.cadcomp,
        caddlar: cadireta.cadlarg,
        caddesp: cadireta.cadesp,
        caddcob: cadireta.cadcobr,
        caddlab: cadireta.cadlabr,
        caddesb: cadireta.cadesbr,
        cadcor: cadireta.cadfase == 40 ? "S" : "N",
        caddbint: "N",
        caddbsup: cadireta.cadbordsup,
        caddbinf: cadireta.cadbordinf,
        caddbesq: cadireta.cadboresq,
        caddbdir: cadireta.cadbordir,
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

    // List<Cadireta> listaCompleta = [...listPaiPedido, ...listPai, ...listFilho];

    _updateSaveStep(3, StepStatus.done);
    if (!skipFinalStep) {
      _updateSaveStep(4, StepStatus.done); // Finalizando
    }

    if (saveOKCadireta.isNotEmpty) {
      cadiretaSuccess.value = false;
    } else {
      cadiretaSuccess.value = true;
    }
  }

  List<Cadireta> agruparCadiretas(List<Cadireta> lista) {
    final Map<String, Cadireta> agrupados = {};

    for (final item in lista) {
      final chave = '${item.cadcont}_${item.cadpai}_${item.cadfilho}';

      if (agrupados.containsKey(chave)) {
        // Atualiza somando o caduso
        final atual = agrupados[chave]!;
        agrupados[chave] = atual.copyWith(caduso: atual.caduso + item.caduso);
      } else {
        agrupados[chave] = item;
      }
    }

    return agrupados.values.toList();
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

  void sync3Cad() {}
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
      // Se o arquivo existe mas não retornou código, usa a sequência da linha
      if (valorCodigo.isEmpty) {
        return '$type"_"$sequencia';
      }
    } else {
      // Se não gerou arquivo, usa a sequência da linha
      return '$type"_"$sequencia';
    }
  } catch (e) {
    // Em erro, usa a sequência da linha onde ocorreu o problema, não o codcont
    return '$type"_"$sequencia';
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
