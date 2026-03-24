import 'package:dartt_integraforwood/services/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SystemLogController extends GetxController {
  final AppLogger logger = Get.find<AppLogger>();

  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  final Rxn<AppLogLevel> levelFilter = Rxn<AppLogLevel>();
  final ScrollController scrollController = ScrollController();
  final RxBool followTail = true.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
    ever(logger.logVersion, (_) {
      if (!followTail.value) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  List<LogEntryModel> get filtered {
    final q = searchText.value.trim().toLowerCase();
    final lv = levelFilter.value;
    return logger.entries.where((e) {
      if (lv != null && e.level != lv) return false;
      if (q.isEmpty) return true;
      return e.tag.toLowerCase().contains(q) ||
          e.message.toLowerCase().contains(q) ||
          (e.stackTrace?.toLowerCase().contains(q) ?? false) ||
          e.line.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> copyAllVisible() async {
    final text = logger.exportEntries(filtered);
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Área de transferência', '${filtered.length} registro(s) copiados');
  }

  Future<void> copyLogPath() async {
    final p = logger.logFilePath;
    if (p == null || p.isEmpty) {
      Get.snackbar('Log', 'Caminho do arquivo indisponível');
      return;
    }
    await Clipboard.setData(ClipboardData(text: p));
    Get.snackbar('Área de transferência', 'Caminho do log copiado');
  }

  Future<void> confirmClearMemory() async {
    final ok = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Limpar log em memória'),
            content: const Text(
              'Os registros serão removidos apenas da tela/memória. '
              'O arquivo em disco não será apagado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Limpar'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      logger.clearMemory();
      Get.snackbar('Log', 'Memória limpa');
    }
  }

  Future<void> confirmClearFile() async {
    final ok = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Apagar arquivo de log de hoje'),
            content: const Text(
              'O arquivo de log do dia atual será esvaziado. '
              'Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Apagar arquivo'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await logger.clearTodaysFile();
      Get.snackbar('Log', 'Arquivo de hoje esvaziado');
    }
  }

  void jumpToLatest() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }
}
