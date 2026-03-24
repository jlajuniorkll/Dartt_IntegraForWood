import 'package:dartt_integraforwood/Routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/imported_xmls_controller.dart';
import '../../../Models/xml_history.dart';

const double _kImportedXmlsRadius = 12;

class ImportedXmlsScreen extends StatefulWidget {
  const ImportedXmlsScreen({super.key});

  @override
  State<ImportedXmlsScreen> createState() => _ImportedXmlsScreenState();
}

class _ImportedXmlsScreenState extends State<ImportedXmlsScreen> {
  final ImportedXmlsController controller = Get.find<ImportedXmlsController>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreXmls();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XMLs importados'),
        actions: [
          IconButton(
            tooltip: 'Log do sistema',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Get.toNamed(PageRoutes.systemLog),
          ),
          IconButton(
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadXmlsImportados(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => controller.searchQuery.value = v,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      hintText: 'Buscar por número, RIF ou pai…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _SearchClearSuffix(
                        rxQuery: controller.searchQuery,
                        textController: _searchController,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_kImportedXmlsRadius),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_kImportedXmlsRadius),
                        borderSide: BorderSide(
                          color: cs.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_kImportedXmlsRadius),
                        borderSide: BorderSide(
                          color: cs.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Ordenar por',
                  icon: const Icon(Icons.sort),
                  onSelected: (value) => controller.sortBy.value = value,
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'createdAt',
                          child: Text('Data de criação'),
                        ),
                        const PopupMenuItem(
                          value: 'numero',
                          child: Text('Número'),
                        ),
                        const PopupMenuItem(
                          value: 'rif',
                          child: Text('RIF'),
                        ),
                        const PopupMenuItem(
                          value: 'pai',
                          child: Text('Pai'),
                        ),
                      ],
                ),
                Obx(
                  () => IconButton(
                    tooltip:
                        controller.isAscending.value
                            ? 'Ordem crescente'
                            : 'Ordem decrescente',
                    onPressed: () => controller.toggleSortOrder(),
                    icon: Icon(
                      controller.isAscending.value
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusSummary(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: cs.primary),
                );
              }

              if (controller.xmlsImportados.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'Nenhum XML encontrado para “${controller.searchQuery.value}”.'
                              : 'Nenhum XML importado.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                cacheExtent: 380,
                itemCount:
                    controller.xmlsImportados.length +
                    (controller.hasMoreItems.value ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == controller.xmlsImportados.length) {
                    return Obx(
                      () =>
                          controller.isLoadingMore.value
                              ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : const SizedBox.shrink(),
                    );
                  }

                  final xml = controller.xmlsImportados[index];
                  return RepaintBoundary(
                    child: _ImportedXmlCard(
                      key: ValueKey('xml_${xml.id}_${xml.revisao}'),
                      xml: xml,
                      controller: controller,
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

  Widget _buildStatusSummary(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Definição estática dos filtros (fora do Obx).
    final filters = <({
      String label,
      String value,
      Color fg,
      Color selectedBg,
      Color outline,
    })>[
      (
        label: 'Aguardando',
        value: 'aguardando',
        fg: cs.tertiary,
        selectedBg: cs.tertiaryContainer,
        outline: cs.tertiary,
      ),
      (
        label: 'Orçado',
        value: 'orcado',
        fg: cs.primary,
        selectedBg: cs.primaryContainer,
        outline: cs.primary,
      ),
      (
        label: 'Produzir',
        value: 'produzir',
        fg: cs.secondary,
        selectedBg: cs.secondaryContainer,
        outline: cs.secondary,
      ),
      (
        label: 'Em produção',
        value: 'em_producao',
        fg: cs.primary,
        selectedBg: cs.surfaceContainerHigh,
        outline: cs.primary,
      ),
      (
        label: 'Finalizado',
        value: 'finalizado',
        fg: cs.primary,
        selectedBg: cs.surfaceContainerHighest,
        outline: cs.outline,
      ),
    ];

    // Um único Obx: o GetX exige leitura direta de .obs neste closure.
    // Obx aninhado + `count` local fazia o exterior não subscrever nada → erro.
    return Obx(() {
      final selected = controller.selectedStatusFilter.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in filters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: selected == f.value,
                    showCheckmark: false,
                    label: Text(
                      '${f.label}: ${controller.statusCount[f.value] ?? 0}',
                    ),
                    onSelected: (_) {
                      controller.filterByStatus(
                        selected == f.value ? 'todos' : f.value,
                      );
                    },
                    selectedColor: f.selectedBg,
                    checkmarkColor: f.fg,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color:
                          selected == f.value ? f.fg : cs.onSurfaceVariant,
                      fontWeight:
                          selected == f.value
                              ? FontWeight.w600
                              : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color:
                          selected == f.value
                              ? f.outline
                              : cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(_kImportedXmlsRadius),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Cartão com estado local para o campo Nº fabricação (evita recriar controller a cada build).
class _ImportedXmlCard extends StatefulWidget {
  const _ImportedXmlCard({
    super.key,
    required this.xml,
    required this.controller,
  });

  final XmlImportado xml;
  final ImportedXmlsController controller;

  @override
  State<_ImportedXmlCard> createState() => _ImportedXmlCardState();
}

class _ImportedXmlCardState extends State<_ImportedXmlCard> {
  late final TextEditingController _numFabController;

  XmlImportado get xml => widget.xml;

  @override
  void initState() {
    super.initState();
    _numFabController = TextEditingController(
      text: xml.numeroFabricacao ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ImportedXmlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xml.id != xml.id ||
        oldWidget.xml.numeroFabricacao != xml.numeroFabricacao) {
      _numFabController.text = xml.numeroFabricacao ?? '';
    }
  }

  @override
  void dispose() {
    _numFabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFmt = DateFormat('dd/MM/yy HH:mm');

    final podeEnviarProducao =
        xml.status == 'produzir' &&
        xml.numeroFabricacao != null &&
        xml.numeroFabricacao!.trim().isNotEmpty;

    final statusItems =
        StatusXml.values
            .map((status) {
              if (xml.status == 'em_producao' &&
                  status.value != 'em_producao' &&
                  status.value != 'finalizado') {
                return null;
              }
              if (xml.status == 'finalizado' &&
                  status.value != 'finalizado') {
                return null;
              }
              return DropdownMenuItem<String>(
                value: status.value,
                child: Text(status.label),
              );
            })
            .whereType<DropdownMenuItem<String>>()
            .toList();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kImportedXmlsRadius),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'XML ${xml.numero} (rev. ${xml.revisao})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(status: xml.status),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                final metaRows = <Widget>[
                  _MetaLine(label: 'RIF', value: xml.rif, theme: theme, cs: cs),
                  _MetaLine(label: 'Pai', value: xml.pai, theme: theme, cs: cs),
                  _MetaLine(
                    label: 'Data XML',
                    value: xml.data,
                    theme: theme,
                    cs: cs,
                  ),
                  _MetaLine(
                    label: 'Criado',
                    value: dateFmt.format(xml.createdAt),
                    theme: theme,
                    cs: cs,
                  ),
                  if (xml.updatedAt != null)
                    _MetaLine(
                      label: 'Atualizado',
                      value: dateFmt.format(xml.updatedAt!),
                      theme: theme,
                      cs: cs,
                    ),
                ];
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final w in metaRows) ...[w, const SizedBox(height: 6)],
                    ],
                  );
                }
                final half = (metaRows.length / 2).ceil();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < half; i++) ...[
                            if (i > 0) const SizedBox(height: 6),
                            metaRows[i],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = half; i < metaRows.length; i++) ...[
                            if (i > half) const SizedBox(height: 6),
                            metaRows[i],
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numFabController,
              decoration: InputDecoration(
                labelText: 'Número de fabricação',
                hintText: 'Obrigatório para enviar à produção',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                final t = value.trim();
                if (t.isNotEmpty && xml.id != null) {
                  widget.controller.updateNumeroFabricacao(xml.id!, t);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // Sincroniza com o modelo após atualização no repositório.
              // ignore: deprecated_member_use
              value: xml.status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              isExpanded: true,
              items: statusItems,
              onChanged: (newStatus) {
                if (newStatus != null && newStatus != xml.status) {
                  widget.controller.updateXmlStatus(xml.id!, newStatus);
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed:
                      podeEnviarProducao
                          ? () => widget.controller.enviarParaProducao(xml)
                          : null,
                  icon: const Icon(Icons.send_outlined, size: 20),
                  label: const Text('Produção'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                ),
                if (xml.status == 'produzir' && !podeEnviarProducao)
                  Tooltip(
                    message: 'Preencha o número de fabricação para enviar.',
                    child: Icon(
                      Icons.info_outline,
                      color: cs.tertiary,
                      size: 22,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => widget.controller.abrirCompararVersoes(xml),
                  icon: const Icon(Icons.compare_arrows, size: 20),
                  label: const Text('Comparar versões'),
                ),
                const SizedBox(width: 4),
                Obx(() {
                  final busy =
                      widget.controller.deletingXmlId.value == xml.id;
                  return IconButton.filledTonal(
                    tooltip:
                        busy
                            ? 'A excluir…'
                            : 'Excluir todas as revisões deste XML',
                    style: IconButton.styleFrom(
                      foregroundColor: cs.error,
                    ),
                    onPressed:
                        busy
                            ? null
                            : () => widget.controller.confirmDelete(xml),
                    icon:
                        busy
                            ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.error,
                              ),
                            )
                            : const Icon(Icons.delete_outline),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchClearSuffix extends StatelessWidget {
  const _SearchClearSuffix({
    required this.rxQuery,
    required this.textController,
  });

  final RxString rxQuery;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (rxQuery.value.isEmpty) return const SizedBox.shrink();
      return IconButton(
        tooltip: 'Limpar',
        icon: const Icon(Icons.clear),
        onPressed: () {
          textController.clear();
          rxQuery.value = '';
        },
      );
    });
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = StatusXml.fromValue(status).label;

    late final Color fg;
    late final Color bg;
    switch (status) {
      case 'aguardando':
        fg = cs.tertiary;
        bg = cs.tertiaryContainer;
        break;
      case 'orcado':
        fg = cs.primary;
        bg = cs.primaryContainer;
        break;
      case 'produzir':
        fg = cs.secondary;
        bg = cs.secondaryContainer;
        break;
      case 'em_producao':
        fg = cs.primary;
        bg = cs.surfaceContainerHigh;
        break;
      case 'finalizado':
        fg = cs.onSecondaryContainer;
        bg = cs.secondaryContainer;
        break;
      default:
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceContainerHighest;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
