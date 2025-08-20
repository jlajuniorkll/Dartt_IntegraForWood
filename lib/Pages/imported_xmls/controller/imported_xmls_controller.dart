import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../Models/xml_history.dart';
import '../../../services/xml_importado_service.dart';
import '../view/json_comparison_screen.dart';
// Novos imports necessários
import '../../../Models/outlite.dart';
import '../../../Models/cadire2.dart';
import '../../homescreen/repository/home_screen_repository.dart';
// Adicionar este import
import '../../../commom/commom_functions.dart';

class ImportedXmlsController extends GetxController {
  final XmlImportadoService _xmlService = XmlImportadoService();
  // Adicionar instância do repositório
  final HomeScreenRepository _homeScreenRepository = HomeScreenRepository();

  // Lista observável de XMLs importados
  final RxList<XmlImportado> xmlsImportados = <XmlImportado>[].obs;
  final RxList<XmlImportado> _allXmls =
      <XmlImportado>[].obs; // Lista completa para filtros
  final RxList<XmlImportado> _filteredXmls =
      <XmlImportado>[].obs; // Lista filtrada

  // Estado de carregamento
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Variáveis de paginação
  final int itemsPerPage = 20;
  final RxInt currentPage = 0.obs;
  final RxBool hasMoreItems = true.obs;

  // Contadores por status
  final RxMap<String, int> statusCount = <String, int>{}.obs;

  // Filtro por status
  final RxString selectedStatusFilter = 'todos'.obs;

  // Variáveis para busca e ordenação
  final RxString searchQuery = ''.obs;
  final RxBool isAscending = true.obs;
  final RxString sortBy = 'createdAt'.obs; // createdAt, numero, rif, pai

  @override
  void onInit() {
    super.onInit();
    loadXmlsImportados();
    loadStatusCount();
  }

  // Carregar todos os XMLs importados
  Future<void> loadXmlsImportados() async {
    try {
      isLoading.value = true;

      List<XmlImportado> xmls;
      if (selectedStatusFilter.value == 'todos') {
        xmls = await _xmlService.getAllXmlsImportados();
      } else {
        xmls = await _xmlService.getXmlsByStatus(selectedStatusFilter.value);
      }

      _allXmls.value = xmls;
      _applyFiltersAndSort();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar XMLs importados: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar contadores por status
  Future<void> loadStatusCount() async {
    try {
      final count = await _xmlService.getStatusCount();
      statusCount.value = count;
    } catch (e) {
      print('Erro ao carregar contadores: $e');
    }
  }

  // Atualizar status do XML
  Future<void> updateXmlStatus(int id, String newStatus) async {
    // Se o novo status for 'Em Produção', mostrar alerta de confirmação
    if (newStatus == 'em_producao') {
      bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Confirmação'),
          content: Text(
            'Os arquivos de produção não foram gerados. Deseja mesmo enviar sem os arquivos de produção?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Não'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Sim'),
            ),
          ],
        ),
      );

      // Se não confirmou, não altera o status
      if (confirmed != true) {
        return;
      }
    }

    try {
      await _xmlService.updateStatus(id, newStatus);

      // Atualizar a lista local
      final index = xmlsImportados.indexWhere((xml) => xml.id == id);
      if (index != -1) {
        xmlsImportados[index] = xmlsImportados[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Recarregar contadores
      await loadStatusCount();

      Get.snackbar(
        'Sucesso',
        'Status atualizado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Atualizar número de fabricação
  Future<void> updateNumeroFabricacao(int id, String numeroFabricacao) async {
    try {
      await _xmlService.updateNumeroFabricacao(id, numeroFabricacao);

      // Atualizar a lista local
      final index = xmlsImportados.indexWhere((xml) => xml.id == id);
      if (index != -1) {
        xmlsImportados[index] = xmlsImportados[index].copyWith(
          numeroFabricacao: numeroFabricacao,
          updatedAt: DateTime.now(),
        );
      }

      Get.snackbar(
        'Sucesso',
        'Número de fabricação atualizado!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar número de fabricação: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Enviar para Produção (renomeado de enviarParaForWood)
  // Adicionar variável de controle no controller
  bool _enviandoParaProducao = false;

  Future<void> enviarParaProducao(XmlImportado xmlSelecionado) async {
    // Verificar se já está processando
    if (_enviandoParaProducao) {
      print('Envio já em andamento, ignorando clique duplo');
      return;
    }

    _enviandoParaProducao = true;

    try {
      // Mostrar loading
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Salvando dados na tabela cadire2...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // 1. VALIDAÇÃO: Verificar se o número de fabricação está preenchido
      if (xmlSelecionado.numeroFabricacao == null ||
          xmlSelecionado.numeroFabricacao!.trim().isEmpty) {
        Get.snackbar(
          'Erro',
          'Não é possível enviar para produção. O número de fabricação deve estar preenchido.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 2. Verificar se pode criar nova revisão
      bool canCreate = await _xmlService.canCreateNewRevision(
        xmlSelecionado.numero,
      );
      if (!canCreate) {
        Get.snackbar(
          'Erro',
          'Não é possível enviar para produção. O XML já está em produção ou finalizado.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 3. Buscar todas as revisões disponíveis para seleção
      List<XmlImportado> revisoesDisponiveis = await _xmlService
          .getXmlsByNumero(xmlSelecionado.numero);

      // Filtrar apenas revisões que podem ser enviadas (não em produção ou finalizadas)
      revisoesDisponiveis =
          revisoesDisponiveis
              .where(
                (rev) =>
                    rev.status != 'em_producao' && rev.status != 'finalizado',
              )
              .toList();

      if (revisoesDisponiveis.isEmpty) {
        Get.snackbar(
          'Erro',
          'Nenhuma revisão disponível para envio.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 4. Mostrar dialog para seleção da revisão
      XmlImportado? revisaoSelecionada = await _mostrarDialogSelecaoRevisao(
        revisoesDisponiveis,
      );

      if (revisaoSelecionada == null) {
        // Usuário cancelou a seleção
        return;
      }

      // 5. Confirmar envio da revisão selecionada
      bool? confirmado = await _mostrarDialogConfirmacaoEnvio(
        revisaoSelecionada,
      );

      if (confirmado != true) {
        return;
      }

      // 6. NOVA FUNCIONALIDADE: Alimentar tabela cadire2 antes de atualizar status
      try {
        await _alimentarTabelaCadire2(revisaoSelecionada);
      } catch (e) {
        // Fechar loading
        Get.back();

        // Fazer rollback - limpar dados inseridos na cadire2
        try {
          await _homeScreenRepository.deleteCadire2();
          print('Rollback executado: dados da cadire2 removidos');
        } catch (rollbackError) {
          print('Erro no rollback: $rollbackError');
        }

        // Mostrar erro específico
        Get.snackbar(
          'Erro ao Salvar',
          'Erro ao alimentar tabela cadire2: $e\n\nOs dados não foram salvos. Corrija o erro e tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 8),
        );

        // Não continuar com a atualização do status
        return;
      }

      // 7. Atualizar status da revisão selecionada para 'em_producao' APENAS se não houve erro
      await _xmlService.updateStatus(revisaoSelecionada.id!, 'em_producao');

      // Fechar loading
      Get.back();

      // 8. Recarregar a lista de XMLs para mostrar a atualização
      await loadXmlsImportados();
      await loadStatusCount();

      Get.snackbar(
        'Sucesso',
        'Revisão ${revisaoSelecionada.revisao} do XML ${revisaoSelecionada.numero} enviada para produção!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Fechar loading em caso de erro
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Erro',
        'Erro ao enviar para produção: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Método para alimentar a tabela cadire2 ao enviar para produção
  Future<void> _alimentarTabelaCadire2(XmlImportado xmlSelecionado) async {
    print('=== INÍCIO DEBUG DUPLICAÇÃO ===');
    print('Timestamp: ${DateTime.now()}');
    print('XML: ${xmlSelecionado.numero}');

    // Lista para armazenar os dados que tentamos salvar
    List<Map<String, dynamic>> dadosCadire2Tentados = [];

    try {
      print(
        'Iniciando alimentação da tabela cadire2 para XML: ${xmlSelecionado.numero}',
      );

      // 1. Verificar se existe jsonCadireta na revisão selecionada
      if (xmlSelecionado.jsonCadireta == null ||
          xmlSelecionado.jsonCadireta!.isEmpty) {
        print('Nenhum dado cadireta encontrado para este XML');
        return;
      }

      // 2. Processar jsonCadire2 para obter matrículas se existir
      Map<String, String> matriculasPorFilho = {};
      if (xmlSelecionado.jsonCadire2 != null && xmlSelecionado.jsonCadire2!.isNotEmpty) {
        try {
          List<dynamic> jsonCadire2List = json.decode(xmlSelecionado.jsonCadire2!);
          print('Processando ${jsonCadire2List.length} registros do jsonCadire2 para extrair matrículas');
          
          for (var cadire2Item in jsonCadire2List) {
            String cadinfinf = cadire2Item['cadinfinf'] ?? '';
            String cadmatricula = cadire2Item['cadmatricula'] ?? '';
            
            if (cadinfinf.isNotEmpty && cadmatricula.isNotEmpty) {
              matriculasPorFilho[cadinfinf] = cadmatricula;
              print('Matrícula encontrada: $cadinfinf -> $cadmatricula');
            }
          }
        } catch (e) {
          print('Erro ao processar jsonCadire2: $e');
        }
      }

      // 2. Converter JSON da cadireta para lista de objetos
      List<dynamic> jsonCadiretaList = json.decode(
        xmlSelecionado.jsonCadireta!,
      );

      print(
        'Encontrados ${jsonCadiretaList.length} registros cadireta para processar',
      );

      // === NOVO DEBUG PARA VERIFICAR DUPLICAÇÃO ===
      print('=== ANÁLISE DE DUPLICAÇÃO NO JSON ===');
      print('JSON Cadireta completo: ${xmlSelecionado.jsonCadireta}');

      // Verificar registros únicos por cadpai
      print('\n=== VERIFICAÇÃO DE PROJETOS ÚNICOS ===');
      Set<String> projetosUnicos = {};
      Map<String, int> contadorProjetos = {};

      for (int i = 0; i < jsonCadiretaList.length; i++) {
        var item = jsonCadiretaList[i];
        String cadpai = item['cadpai'] ?? '';
        String cadfilho = item['cadfilho'] ?? '';
        String cadpainome = item['cadpainome'] ?? '';
        int cadcont = item['cadcont'] ?? (i + 1);

        print(
          'Registro $i: cadpai="$cadpai", cadfilho="$cadfilho", cadpainome="$cadpainome", cadcont=$cadcont',
        );

        // Contar ocorrências de cada projeto
        contadorProjetos[cadpai] = (contadorProjetos[cadpai] ?? 0) + 1;

        if (projetosUnicos.contains(cadpai)) {
          print(
            '  ⚠️  DUPLICADO ENCONTRADO: Projeto "$cadpai" já foi processado!',
          );
        } else {
          projetosUnicos.add(cadpai);
          print('  ✅ Projeto único: "$cadpai"');
        }
      }

      print('\n=== RESUMO DE DUPLICAÇÃO ===');
      contadorProjetos.forEach((projeto, count) {
        if (count > 1) {
          print('🔴 PROJETO DUPLICADO: "$projeto" aparece $count vezes');
        } else {
          print('🟢 Projeto único: "$projeto" aparece $count vez');
        }
      });

      print('Total de projetos únicos: ${projetosUnicos.length}');
      print('Total de registros: ${jsonCadiretaList.length}');

      if (projetosUnicos.length != jsonCadiretaList.length) {
        print('🚨 CONFIRMADO: Há duplicação no JSON da cadireta!');
      } else {
        print('✅ Não há duplicação no JSON da cadireta');
      }
      print('=== FIM ANÁLISE DE DUPLICAÇÃO ===\n');

      // 3. Limpar dados existentes da cadire2 APENAS para este projeto
      Set<String> projetosProcessados = {};

      int contador = 0;

      // 4. Processar cada registro da cadireta
      for (var cadiretaItem in jsonCadiretaList) {
        try {
          contador++;

          // Extrair dados da cadireta
          int cadcont = cadiretaItem['cadcont'] ?? contador;
          String cadpai = cadiretaItem['cadpai'] ?? '';
          String cadfilho = cadiretaItem['cadfilho'] ?? '';
          String cadpainome = cadiretaItem['cadpainome'] ?? '';
          int cadfase = cadiretaItem['cadfase'] ?? 40;
          String cadfilnome = cadiretaItem['cadfilnome'] ?? '';

          // === DEBUG ADICIONAL PARA CADA REGISTRO ===
          print('\n=== PROCESSANDO REGISTRO $contador ===');
          print('  - cadpai: "$cadpai"');
          print('  - cadcont: $cadcont');
          print('  - cadfilho: "$cadfilho"');
          print('  - cadpainome: "$cadpainome"');
          print('  - cadfase: $cadfase');
          print('  - cadfilnome: "$cadfilnome"');
          print(
            '  - Projeto já processado: ${projetosProcessados.contains(cadpai)}',
          );

          // Limpar dados existentes apenas na primeira vez para cada projeto
          if (!projetosProcessados.contains(cadpai)) {
            await _homeScreenRepository.deleteCadire2ByProject(cadpai);
            projetosProcessados.add(cadpai);
            print('Dados existentes da cadire2 limpos para projeto: $cadpai');
          }

          // Extrair matrícula do cadfilnome usando a mesma regex do getItemPecas
          String? cadmatricula;
          if (cadfilnome.isNotEmpty) {
            RegExp regexMatricula = RegExp(r'#M\d+/\d+/(\d+)');
            Match? match = regexMatricula.firstMatch(cadfilnome);
            if (match != null) {
              String numeroMatricula = match.group(1)!;
              // Formatar matrícula com número de fabricação se disponível
              if (xmlSelecionado.numeroFabricacao != null) {
                cadmatricula = formatMatricula(
                  xmlSelecionado.numeroFabricacao!,
                  numeroMatricula,
                );
              } else {
                cadmatricula = numeroMatricula;
              }
              print('Matrícula extraída do cadfilnome: $cadmatricula');
            }
          }

          // 5. SEMPRE salvar o item pai (cadinfseq = 2)
          final cadire2Pai = Cadire2(
            cadinfcont: cadcont,
            cadinfprod: cadpai,
            cadinfseq: 2,
            cadinfdes: cadpainome,
            cadinfinf: cadfilho,
            cadmatricula: cadmatricula, // Adicionar a matrícula extraída
          );

          // Adicionar aos dados tentados ANTES de salvar
          dadosCadire2Tentados.add({
            'tipo': 'pai',
            'cadinfcont': cadcont,
            'cadinfprod': cadpai,
            'cadinfseq': 2,
            'cadinfdes': cadpainome,
            'cadinfinf': cadfilho,
            'cadfase': cadfase,
            'cadfilnome': cadfilnome,
            'cadmatricula': cadmatricula, // Adicionar também aos dados tentados
          });

          String resultadoPai = await _homeScreenRepository.saveCadire2(
            cadire2Pai,
            contador,
            'cadire2',
          );

          if (resultadoPai.isNotEmpty) {
            print('Erro ao salvar cadire2 pai: $resultadoPai');
            throw Exception(
              'Erro ao salvar registro pai ($cadpai): $resultadoPai',
            );
          } else {
            print('Registro cadire2 pai salvo: $cadpai');
          }

          // 6. Verificar se possui numeroFabricacao para buscar PRG1 e PRG2
          print('=== DEBUG NUMERO FABRICACAO ===');
          print('numeroFabricacao: "${xmlSelecionado.numeroFabricacao ?? ""}"');
          print(
            'numeroFabricacao preenchido: ${(xmlSelecionado.numeroFabricacao != null && xmlSelecionado.numeroFabricacao!.trim().isNotEmpty)}',
          );

          // Declarar variáveis
          String nomePRG1 = '';
          String nomePRG2 = '';

          // Executar apenas se numeroFabricacao estiver preenchido
          if (xmlSelecionado.numeroFabricacao != null &&
              xmlSelecionado.numeroFabricacao!.trim().isNotEmpty) {
            print('✅ EXECUTANDO consulta - numeroFabricacao preenchido');

            try {
              print('🔍 CHAMANDO consultarListaCorte com:');
              print(
                '  - numeroFabricacao: "${xmlSelecionado.numeroFabricacao}"',
              );
              
              // NOVA LÓGICA: Usar cadmatricula do Cadire2 se disponível
              String matriculaParaConsulta = '';
              if (matriculasPorFilho.containsKey(cadfilho)) {
                matriculaParaConsulta = matriculasPorFilho[cadfilho]!;
                print('  - Usando cadmatricula do Cadire2: "$matriculaParaConsulta"');
              } else {
                // Fallback: usar formatação do cadfilnome
                matriculaParaConsulta = formatMatriculaComFabricacao(
                  xmlSelecionado.numeroFabricacao!,
                  cadfilnome,
                );
                print('  - Usando cadfilnome formatado: "$matriculaParaConsulta"');
              }

              print('  - matriculaParaConsulta: "$matriculaParaConsulta"');

              // Usar numeroFabricacao do XML e matrícula do Cadire2 para buscar PRG1 e PRG2
              Map<String, String> resultadoCorte = await consultarListaCorte(
                xmlSelecionado.numeroFabricacao!,
                matriculaParaConsulta,
              );

              print('📋 RESULTADO consultarListaCorte: $resultadoCorte');

              nomePRG1 = resultadoCorte['PRG1'] ?? '';
              nomePRG2 = resultadoCorte['PRG2'] ?? '';

              print('  - nomePRG1: "$nomePRG1"');
              print('  - nomePRG2: "$nomePRG2"');
            } catch (e) {
              print('❌ Erro ao consultar Lista_corte: $e');
            }

            // 7. Salvar nomePRG1 se não estiver vazio (cadinfseq = 3)
            if (nomePRG1.isNotEmpty) {
              final cadire2PRG1 = Cadire2(
                cadinfcont: cadcont,
                cadinfprod: cadpai,
                cadinfseq: 3,
                cadinfdes: nomePRG1,
                cadinfinf: cadfilho,
              );

              // Adicionar aos dados tentados ANTES de salvar
              dadosCadire2Tentados.add({
                'tipo': 'PRG1',
                'cadinfcont': cadcont,
                'cadinfprod': cadpai,
                'cadinfseq': 3,
                'cadinfdes': nomePRG1,
                'cadinfinf': cadfilho,
                'cadfase': cadfase,
                'cadfilnome': cadfilnome,
              });

              String resultadoPRG1 = await _homeScreenRepository.saveCadire2(
                cadire2PRG1,
                contador,
                'cadire2',
              );

              if (resultadoPRG1.isNotEmpty) {
                print('Erro ao salvar cadire2 PRG1: $resultadoPRG1');
                throw Exception(
                  'Erro ao salvar PRG1 ($nomePRG1): $resultadoPRG1',
                );
              } else {
                print('Registro cadire2 PRG1 salvo: $nomePRG1');
              }
            }

            // 8. Salvar nomePRG2 se não estiver vazio (cadinfseq = 4)
            if (nomePRG2.isNotEmpty) {
              final cadire2PRG2 = Cadire2(
                cadinfcont: cadcont,
                cadinfprod: cadpai,
                cadinfseq: 4,
                cadinfdes: nomePRG2,
                cadinfinf: cadfilho,
              );

              // Adicionar aos dados tentados ANTES de salvar
              dadosCadire2Tentados.add({
                'tipo': 'PRG2',
                'cadinfcont': cadcont,
                'cadinfprod': cadpai,
                'cadinfseq': 4,
                'cadinfdes': nomePRG2,
                'cadinfinf': cadfilho,
                'cadfase': cadfase,
                'cadfilnome': cadfilnome,
              });

              String resultadoPRG2 = await _homeScreenRepository.saveCadire2(
                cadire2PRG2,
                contador,
                'cadire2',
              );

              if (resultadoPRG2.isNotEmpty) {
                print('Erro ao salvar cadire2 PRG2: $resultadoPRG2');
                throw Exception(
                  'Erro ao salvar PRG2 ($nomePRG2): $resultadoPRG2',
                );
              } else {
                print('Registro cadire2 PRG2 salvo: $nomePRG2');
              }
            }
          } else {
            print('❌ NÃO EXECUTANDO consulta - numeroFabricacao vazio ou nulo');
          }
        } catch (e) {
          print('Erro ao processar registro cadireta $contador: $e');
          // Incluir dados tentados no erro
          throw Exception(
            'Erro no registro $contador: $e\n\nDados tentados de salvar na cadire2:\n${jsonEncode(dadosCadire2Tentados)}',
          );
        }
      }

      // Atualizar o JSON da cadire2 no XML com os dados que foram salvos com sucesso
      if (dadosCadire2Tentados.isNotEmpty) {
        String jsonCadire2Atualizado = jsonEncode(dadosCadire2Tentados);
        await _xmlService.updateJsons(
          xmlSelecionado.id!,
          jsonCadire2: jsonCadire2Atualizado,
        );
        print(
          'JSON da cadire2 atualizado no XML com ${dadosCadire2Tentados.length} registros',
        );
      }

      print('Alimentação da tabela cadire2 concluída com sucesso');
    } catch (e) {
      print('Erro ao alimentar tabela cadire2: $e');
      // Se houve erro e temos dados tentados, incluir no erro
      if (dadosCadire2Tentados.isNotEmpty) {
        throw Exception(
          'Erro ao alimentar tabela cadire2: $e\n\nDados tentados de salvar na cadire2:\n${jsonEncode(dadosCadire2Tentados)}',
        );
      } else {
        throw Exception('Erro ao alimentar tabela cadire2: $e');
      }
    }
  }

  // Método para consultar a tabela Lista_corte (similar ao do home_screen_controller)
  Future<Map<String, String?>> _consultarListaCorte(
    String matricula,
    double espessura,
    double comprimento,
    double largura,
  ) async {
    try {
      // Usar a função global ao invés do método do repository
      Map<String, String> resultado = await consultarListaCorte(
        matricula, // numeroFabricacao
        '', // idpeca - você pode precisar ajustar este parâmetro
      );
      return {'nomePRG1': resultado['PRG1'], 'nomePRG2': resultado['PRG2']};
    } catch (e) {
      print('Erro ao consultar Lista_corte: $e');
      return {'nomePRG1': null, 'nomePRG2': null};
    }
  }

  // Visualizar JSONs das tabelas
  Future<void> visualizarJsons(XmlImportado xml) async {
    try {
      // Verificar se existem múltiplas revisões para este XML
      final revisoes = await _xmlService.getXmlsByNumero(xml.numero);

      if (revisoes.length > 1) {
        // Se há múltiplas revisões, abrir tela de comparação
        Get.to(() => JsonComparisonScreen(xmlNumero: xml.numero));
      } else {
        // Se há apenas uma revisão, mostrar o diálogo atual
        _mostrarDialogoJsonsSimples(xml);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao verificar revisões: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Método auxiliar para mostrar o diálogo simples (código atual)
  void _mostrarDialogoJsonsSimples(XmlImportado xml) {
    Get.dialog(
      AlertDialog(
        title: Text('JSONs das Tabelas - ${xml.numero}'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.blue,
                  tabs: [
                    Tab(text: 'CADIREDI'),
                    Tab(text: 'CADIRETA'),
                    Tab(text: 'CADPROCE'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildJsonTab(xml.jsonCadiredi),
                      _buildJsonTab(xml.jsonCadireta),
                      _buildJsonTab(xml.jsonCadproce),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Fechar')),
        ],
      ),
    );
  }

  Widget _buildJsonSection(String title, String? jsonData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            jsonData != null && jsonData.isNotEmpty
                ? _formatJson(jsonData)
                : 'Nenhum dado disponível',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatJson(String jsonString) {
    try {
      final dynamic jsonData = json.decode(jsonString);
      return JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      return jsonString; // Retorna o original se não conseguir formatar
    }
  }

  // Aplicar filtros e ordenação
  void _applyFiltersAndSort() {
    List<XmlImportado> filteredXmls = List.from(_allXmls);

    // Aplicar filtro de busca
    if (searchQuery.value.isNotEmpty) {
      filteredXmls =
          filteredXmls.where((xml) {
            final query = searchQuery.value.toLowerCase();
            return xml.numero.toLowerCase().contains(query) ||
                xml.rif.toLowerCase().contains(query) ||
                xml.pai.toLowerCase().contains(query);
          }).toList();
    }

    // Aplicar ordenação
    filteredXmls.sort((a, b) {
      int comparison = 0;

      switch (sortBy.value) {
        case 'numero':
          comparison = a.numero.compareTo(b.numero);
          break;
        case 'rif':
          comparison = a.rif.compareTo(b.rif);
          break;
        case 'pai':
          comparison = a.pai.compareTo(b.pai);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return isAscending.value ? comparison : -comparison;
    });

    _filteredXmls.value = filteredXmls;

    // Reset pagination
    currentPage.value = 0;
    hasMoreItems.value = _filteredXmls.length > itemsPerPage;

    // Load first page
    _loadPage();
  }

  // Carregar página específica
  void _loadPage() {
    final startIndex = currentPage.value * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, _filteredXmls.length);

    if (currentPage.value == 0) {
      // Primeira página - substitui a lista
      xmlsImportados.value = _filteredXmls.sublist(startIndex, endIndex);
    } else {
      // Páginas seguintes - adiciona à lista existente
      xmlsImportados.addAll(_filteredXmls.sublist(startIndex, endIndex));
    }

    hasMoreItems.value = endIndex < _filteredXmls.length;
  }

  // Carregar próxima página
  Future<void> loadMoreItems() async {
    if (isLoadingMore.value || !hasMoreItems.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;
      _loadPage();
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Resetar paginação (para busca/filtros)
  void resetPagination() {
    currentPage.value = 0;
    xmlsImportados.clear();
    _applyFiltersAndSort();
  }

  // Buscar XMLs
  void searchXmls(String query) {
    searchQuery.value = query;
    resetPagination();
  }

  // Alternar ordem de classificação
  void toggleSortOrder() {
    isAscending.value = !isAscending.value;
    resetPagination();
  }

  // Alterar critério de ordenação
  void changeSortBy(String newSortBy) {
    sortBy.value = newSortBy;
    resetPagination();
  }

  void filterByStatus(String status) {
    selectedStatusFilter.value = status;
    loadXmlsImportados();
  }

  // Deletar XML (todas as revisões)
  Future<void> deleteXml(String numero) async {
    try {
      await _xmlService.deleteAllRevisionsByNumero(numero);
      xmlsImportados.removeWhere((xml) => xml.numero == numero);
      await loadStatusCount();

      Get.snackbar(
        'Sucesso',
        'Todas as revisões do XML $numero foram removidas com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao remover XML: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Confirmar exclusão
  void confirmDelete(XmlImportado xml) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja realmente excluir o pedido ${xml.numero}?'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: Todas as revisões deste pedido serão excluídas permanentemente.',
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteXml(xml.numero);
            },
            child: Text('Excluir Todas', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para construir uma aba de JSON
  Widget _buildJsonTab(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return Center(
        child: Text(
          'Nenhum dado disponível',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          _formatJson(jsonString),
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  // Método auxiliar para mostrar dialog de seleção de revisão
  Future<XmlImportado?> _mostrarDialogSelecaoRevisao(
    List<XmlImportado> revisoesDisponiveis,
  ) async {
    return await Get.dialog<XmlImportado>(
      AlertDialog(
        title: Text('Selecionar Revisão'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione a revisão que deseja enviar para produção:'),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: revisoesDisponiveis.length,
                  itemBuilder: (context, index) {
                    final revisao = revisoesDisponiveis[index];
                    return ListTile(
                      title: Text('Revisão ${revisao.revisao}'),
                      subtitle: Text(
                        'Status: ${revisao.status}\n'
                        'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(revisao.createdAt)}',
                      ),
                      onTap: () {
                        Get.back(result: revisao);
                      },
                      trailing: Icon(Icons.arrow_forward_ios),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
        ],
      ),
    );
  }

  // Método auxiliar para mostrar dialog de confirmação de envio
  Future<bool?> _mostrarDialogConfirmacaoEnvio(
    XmlImportado revisaoSelecionada,
  ) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirmar Envio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirma o envio para produção?'),
            SizedBox(height: 16),
            Text(
              'XML: ${revisaoSelecionada.numero}\n'
              'Revisão: ${revisaoSelecionada.revisao}\n'
              'Número de Fabricação: ${revisaoSelecionada.numeroFabricacao}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: Após o envio, não será possível alterar a revisão para este pedido.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmar Envio'),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
