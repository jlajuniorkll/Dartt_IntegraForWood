import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/outlite.dart';
import '../../../Models/xml_history.dart';
import '../../../Pages/common/widget_loader.dart';
import '../../../Pages/homescreen/controller/home_screen_controller.dart';
import '../../../services/xml_importado_service.dart';

import '../view/json_comparison_screen.dart';

class ImportedXmlsController extends GetxController {
  final XmlImportadoService _xmlService = XmlImportadoService();

  // Listas e estados reativos
  final RxList<XmlImportado> xmlsImportados = <XmlImportado>[].obs;
  final RxList<XmlImportado> _allXmls = <XmlImportado>[].obs;
  final RxList<XmlImportado> _filteredXmls = <XmlImportado>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Paginação
  final int itemsPerPage = 20;
  final RxInt currentPage = 0.obs;
  final RxBool hasMoreItems = true.obs;

  // Filtros e ordenação
  final RxMap<String, int> statusCount = <String, int>{}.obs;
  final RxString selectedStatusFilter = 'todos'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isAscending = true.obs;
  final RxString sortBy = 'createdAt'.obs; // createdAt, numero, rif, pai

  @override
  void onInit() {
    super.onInit();
    loadXmlsImportados();
    // Recalcula lista ao mudar busca, status ou ordenação
    ever(searchQuery, (_) => _recomputeAndResetPagination());
    ever(selectedStatusFilter, (_) => _recomputeAndResetPagination());
    ever(sortBy, (_) => _recomputeAndResetPagination());
    ever(isAscending, (_) => _recomputeAndResetPagination());
  }

  Future<void> loadXmlsImportados() async {
    isLoading.value = true;
    try {
      final all = await _xmlService.getAllXmlsImportados();
      _allXmls.assignAll(all);
      _updateStatusCount();
      _recomputeAndResetPagination();
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao carregar XMLs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreXmls() async {
    if (isLoadingMore.value || !hasMoreItems.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final slice = _pageSlice(nextPage);
      if (slice.isNotEmpty) {
        xmlsImportados.addAll(slice);
        currentPage.value = nextPage;
        hasMoreItems.value = _filteredXmls.length > xmlsImportados.length;
      } else {
        hasMoreItems.value = false;
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  void toggleSortOrder() {
    isAscending.value = !isAscending.value;
  }

  void filterByStatus(String status) {
    selectedStatusFilter.value = status;
  }

  void _recomputeAndResetPagination() {
    _applyFiltersAndSorting();
    currentPage.value = 0;
    xmlsImportados.assignAll(_pageSlice(0));
    hasMoreItems.value = _filteredXmls.length > xmlsImportados.length;
  }

  void _applyFiltersAndSorting() {
    final q = searchQuery.value.trim().toLowerCase();
    final filtered =
        _allXmls.where((x) {
          final matchesQuery =
              q.isEmpty ||
              [
                x.numero,
                x.rif,
                x.pai,
                x.status,
                x.numeroFabricacao ?? '',
              ].any((s) => s.toString().toLowerCase().contains(q));
          final matchesStatus =
              selectedStatusFilter.value == 'todos' ||
              x.status == selectedStatusFilter.value;
          return matchesQuery && matchesStatus;
        }).toList();

    final dir = isAscending.value ? 1 : -1;
    filtered.sort((a, b) {
      int cmp;
      switch (sortBy.value) {
        case 'numero':
          cmp = a.numero.compareTo(b.numero);
          break;
        case 'rif':
          cmp = a.rif.compareTo(b.rif);
          break;
        case 'pai':
          cmp = a.pai.compareTo(b.pai);
          break;
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return cmp * dir;
    });

    _filteredXmls.assignAll(filtered);
  }

  List<XmlImportado> _pageSlice(int page) {
    final start = page * itemsPerPage;
    final end =
        (start + itemsPerPage) > _filteredXmls.length
            ? _filteredXmls.length
            : (start + itemsPerPage);
    return _filteredXmls.sublist(start, end);
  }

  void _updateStatusCount() {
    final map = <String, int>{};
    for (final x in _allXmls) {
      map[x.status] = (map[x.status] ?? 0) + 1;
    }
    statusCount.assignAll(map);
  }

  Future<void> updateNumeroFabricacao(int id, String numeroFabricacao) async {
    try {
      await _xmlService.updateNumeroFabricacao(id, numeroFabricacao);
      // Atualizar na lista em memória
      final idx = _allXmls.indexWhere((x) => x.id == id);
      if (idx != -1) {
        _allXmls[idx] = _allXmls[idx].copyWith(
          numeroFabricacao: numeroFabricacao,
          updatedAt: DateTime.now(),
        );
        _recomputeAndResetPagination();
      }
      Get.snackbar('Sucesso', 'Número de fabricação atualizado');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao atualizar Nº fabricação: $e');
    }
  }

  Future<void> updateXmlStatus(int id, String newStatus) async {
    try {
      await _xmlService.updateStatus(id, newStatus);
      // Atualizar na lista em memória
      final idx = _allXmls.indexWhere((x) => x.id == id);
      if (idx != -1) {
        _allXmls[idx] = _allXmls[idx].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        _updateStatusCount();
        _recomputeAndResetPagination();
      }
      Get.snackbar('Sucesso', 'Status atualizado para "$newStatus"');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao atualizar status: $e');
    }
  }

  void visualizarJsons(XmlImportado xml) {
    Get.to(() => JsonComparisonScreen(xmlNumero: xml.numero));
  }

  Future<void> confirmDelete(XmlImportado xml) async {
    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Excluir XML'),
            content: Text(
              'Deseja excluir a revisão ${xml.revisao} do XML ${xml.numero}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await _xmlService.deleteXmlImportado(xml.id!);
      _allXmls.removeWhere((x) => x.id == xml.id);
      _updateStatusCount();
      _recomputeAndResetPagination();
      Get.snackbar('Sucesso', 'XML excluído');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao excluir XML: $e');
    }
  }

  Future<void> enviarParaProducao(XmlImportado xml) async {
    try {
      if ((xml.numeroFabricacao ?? '').trim().isEmpty) {
        Get.snackbar('Atenção', 'Preencha o número de fabricação');
        return;
      }

      final jsonOutlite = xml.jsonOutlite;
      if (jsonOutlite == null || jsonOutlite.trim().isEmpty) {
        Get.snackbar('Erro', 'XML sem dados Outlite para envio');
        return;
      }

      Outlite outlite;
      try {
        outlite = Outlite.fromJson(jsonOutlite);
      } catch (e) {
        Get.snackbar('Erro', 'Falha ao reconstruir dados: $e');
        return;
      }

      final numeroFabricacao = xml.numeroFabricacao!.trim();
      final homeController = Get.find<HomeScreenController>();
      homeController.aplicarNumeroFabricacaoAoOutlite(outlite, numeroFabricacao);

      final podeEnviar =
          await homeController.confirmarEnvioParaForWoodSeNecessario(outlite);
      if (!podeEnviar) {
        return;
      }

      Get.dialog(
        PopScope(
          canPop: false,
          child: Obx(
            () => LoadingWidget(
              steps: homeController.saveProgressSteps,
            ),
          ),
        ),
        barrierDismissible: false,
      );

      bool sucesso = false;
      try {
        sucesso = await homeController.enviarOutliteParaForWood(outlite);
      } finally {
        Get.back();
      }

      if (!sucesso) {
        final erros = homeController.saveOKCadireta;
        Get.snackbar(
          'Erro',
          'Falha ao enviar: ${erros.isNotEmpty ? erros.join('; ') : 'verifique os dados'}',
        );
        return;
      }

      await _xmlService.updateStatus(xml.id!, 'em_producao');
      final idx = _allXmls.indexWhere((x) => x.id == xml.id);
      if (idx != -1) {
        final jsonOutliteAtualizado = jsonEncode(outlite.toMap());
        await _xmlService.updateJsons(
          xml.id!,
          jsonOutlite: jsonOutliteAtualizado,
          jsonCadire2: homeController.lastSavedCadire2Json,
        );
        _allXmls[idx] = _allXmls[idx].copyWith(
          status: 'em_producao',
          updatedAt: DateTime.now(),
        );
        _updateStatusCount();
        _recomputeAndResetPagination();
      }

      Get.snackbar('Sucesso', 'XML enviado para produção');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao enviar para produção: $e');
    }
  }
}
