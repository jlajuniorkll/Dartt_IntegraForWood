import 'package:dartt_integraforwood/Pages/system_log/controller/system_log_controller.dart';
import 'package:dartt_integraforwood/services/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SystemLogScreen extends StatelessWidget {
  const SystemLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SystemLogController>();

    Color levelColor(AppLogLevel l) {
      switch (l) {
        case AppLogLevel.debug:
          return Colors.blueGrey;
        case AppLogLevel.info:
          return Colors.blue.shade700;
        case AppLogLevel.warning:
          return Colors.orange.shade800;
        case AppLogLevel.error:
          return Colors.red.shade800;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log do sistema'),
        actions: [
          IconButton(
            tooltip: 'Ir para o fim',
            onPressed: c.jumpToLatest,
            icon: const Icon(Icons.vertical_align_bottom),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'copy') {
                await c.copyAllVisible();
              } else if (v == 'path') {
                await c.copyLogPath();
              } else if (v == 'clearMem') {
                await c.confirmClearMemory();
              } else if (v == 'clearFile') {
                await c.confirmClearFile();
              }
            },
            itemBuilder:
                (ctx) => [
                  const PopupMenuItem(value: 'copy', child: Text('Copiar visíveis')),
                  const PopupMenuItem(
                    value: 'path',
                    child: Text('Copiar caminho do arquivo'),
                  ),
                  const PopupMenuItem(
                    value: 'clearMem',
                    child: Text('Limpar memória'),
                  ),
                  const PopupMenuItem(
                    value: 'clearFile',
                    child: Text('Apagar arquivo de hoje'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Obx(() {
              final path = c.logger.logFilePath ?? '(não disponível)';
              return Text(
                'Arquivo: $path',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: c.searchController,
              decoration: const InputDecoration(
                hintText: 'Filtrar por texto (tag, mensagem, stack)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() {
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: c.levelFilter.value == null,
                    onSelected: (_) => c.levelFilter.value = null,
                  ),
                  ...AppLogLevel.values.map(
                    (lv) => FilterChip(
                      label: Text(lv.label),
                      selected: c.levelFilter.value == lv,
                      onSelected: (sel) {
                        c.levelFilter.value = sel ? lv : null;
                      },
                    ),
                  ),
                  FilterChip(
                    avatar:
                        c.followTail.value
                            ? const Icon(Icons.check, size: 18)
                            : null,
                    label: const Text('Seguir último'),
                    selected: c.followTail.value,
                    onSelected: (v) => c.followTail.value = v,
                  ),
                ],
              );
            }),
          ),
          const Divider(height: 16),
          Expanded(
            child: Obx(() {
              final list = c.filtered;
              if (list.isEmpty) {
                return const Center(child: Text('Nenhum registro'));
              }
              return ListView.builder(
                key: ValueKey(
                  (
                    c.logUiRevision.value,
                    c.searchText.value,
                    c.levelFilter.value,
                  ),
                ),
                controller: c.scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                cacheExtent: 320,
                addAutomaticKeepAlives: false,
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final e = list[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor(e.level).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.level.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: levelColor(e.level),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.tag,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm:ss.SSS').format(e.time),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            e.message,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (e.stackTrace != null &&
                              e.stackTrace!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SelectableText(
                              e.stackTrace!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
