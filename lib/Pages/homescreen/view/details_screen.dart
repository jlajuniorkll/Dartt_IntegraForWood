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

Widget _metaChip(
  ThemeData theme,
  IconData icon,
  String label,
  String value,
) {
  final cs = theme.colorScheme;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.8)),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );
}

double _parseDimDetail(String? s) =>
    double.tryParse(s?.replaceAll(',', '.').trim() ?? '') ?? 0;

Size _bordaPreviewSize(String? comp, String? larg) {
  const maxSide = 52.0;
  final c = _parseDimDetail(comp);
  final l = _parseDimDetail(larg);
  if (c <= 0 && l <= 0) return const Size(12, 12);
  final w = (c / 10).clamp(10.0, maxSide);
  final h = (l / 10).clamp(10.0, maxSide);
  return Size(w, h);
}

Widget _detailTableHeaderCell(String text, ThemeData theme) {
  final cs = theme.colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    child: Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
    ),
  );
}

Widget _detailTableDataCell(Widget child, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: DefaultTextStyle.merge(
      style: theme.textTheme.bodyMedium,
      child: child,
    ),
  );
}

TableBorder _detailTableBorder(ColorScheme cs) {
  final b = BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55));
  return TableBorder(
    top: b,
    left: b,
    right: b,
    bottom: b,
    horizontalInside: b,
    verticalInside: b,
  );
}

/// Largura total explícita: dentro de scroll horizontal o `Table` recebe largura
/// ilimitada e `FlexColumnWidth` colapsa (texto uma letra por linha).
const double _kCompradosTableWidth = 118 + 320 + 72;

Widget _buildCompradosTable(List<ItemPrice> prices, ThemeData theme) {
  final cs = theme.colorScheme;
  return SizedBox(
    width: _kCompradosTableWidth,
    child: Table(
    columnWidths: const {
      0: FixedColumnWidth(118),
      1: FixedColumnWidth(320),
      2: FixedColumnWidth(72),
    },
    border: _detailTableBorder(cs),
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: [
          _detailTableHeaderCell('Código', theme),
          _detailTableHeaderCell('Descrição', theme),
          _detailTableHeaderCell('Qtd', theme),
        ],
      ),
      for (final itemPrice in prices)
        TableRow(
          decoration: BoxDecoration(
            color: itemPrice.hasErroDescricao
                ? cs.errorContainer.withValues(alpha: 0.32)
                : itemPrice.precisaCadastroForWoodUi
                    ? cs.primaryContainer.withValues(alpha: 0.25)
                    : null,
          ),
          children: [
            _detailTableDataCell(Text(itemPrice.codigo ?? ''), theme),
            _detailTableDataCell(
              itemPrice.precisaCadastroForWoodUi
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${itemPrice.codigo ?? ''} — ${itemPrice.descricaoSqlServer ?? itemPrice.des ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Atualizar',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Text(itemPrice.des ?? ''),
              theme,
            ),
            _detailTableDataCell(Text(itemPrice.qtd ?? ''), theme),
          ],
        ),
    ],
    ),
  );
}

Widget _buildFabricadosTable({
  required List<ItemPecas> pecas,
  required HomeScreenController controller,
  required BuildContext dialogContext,
}) {
  final theme = Theme.of(dialogContext);
  final cs = theme.colorScheme;
  const fabricadosW =
      112 +
      300 +
      56 +
      76 +
      76 +
      76 +
      116 +
      64 +
      48;
  return SizedBox(
    width: fabricadosW.toDouble(),
    child: Table(
    columnWidths: const {
      0: FixedColumnWidth(112),
      1: FixedColumnWidth(300),
      2: FixedColumnWidth(56),
      3: FixedColumnWidth(76),
      4: FixedColumnWidth(76),
      5: FixedColumnWidth(76),
      6: FixedColumnWidth(116),
      7: FixedColumnWidth(64),
      8: FixedColumnWidth(48),
    },
    border: _detailTableBorder(cs),
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: [
          _detailTableHeaderCell('Código', theme),
          _detailTableHeaderCell('Descrição', theme),
          _detailTableHeaderCell('Qtd', theme),
          _detailTableHeaderCell('Comp.', theme),
          _detailTableHeaderCell('Larg.', theme),
          _detailTableHeaderCell('Esp.', theme),
          _detailTableHeaderCell('Matrícula', theme),
          _detailTableHeaderCell('Fita', theme),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      for (final itemPecas in pecas)
        TableRow(
          decoration: BoxDecoration(
            color: itemPecas.hasErroDescricao
                ? cs.errorContainer.withValues(alpha: 0.32)
                : itemPecas.precisaCadastroForWoodUi
                    ? cs.primaryContainer.withValues(alpha: 0.22)
                    : null,
          ),
          children: [
            _detailTableDataCell(Text(itemPecas.codpeca ?? ''), theme),
            _detailTableDataCell(
              itemPecas.precisaCadastroForWoodUi
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${itemPecas.codpeca ?? ''} — ${itemPecas.descricaoSqlServer ?? itemPecas.idpeca ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Atualizar',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Text(itemPecas.idpeca ?? ''),
              theme,
            ),
            _detailTableDataCell(Text(itemPecas.qta ?? ''), theme),
            _detailTableDataCell(Text(itemPecas.comprimento ?? ''), theme),
            _detailTableDataCell(Text(itemPecas.largura ?? ''), theme),
            _detailTableDataCell(Text(itemPecas.espessura ?? ''), theme),
            _detailTableDataCell(Text(itemPecas.matricula ?? ''), theme),
            _detailTableDataCell(
              SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: CustomPaint(
                    size: _bordaPreviewSize(
                      itemPecas.comprimento,
                      itemPecas.largura,
                    ),
                    painter: BordaColoridaPainter(
                      bordaesq: itemPecas.fitaesq ?? 'N',
                      bordadir: itemPecas.fitadir ?? 'N',
                      bordafre: itemPecas.fitafre ?? 'N',
                      bordatra: itemPecas.fitatra ?? 'N',
                    ),
                  ),
                ),
              ),
              theme,
            ),
            _detailTableDataCell(
              IconButton(
                tooltip: 'Estrutura expandida',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: () async {
                  final result = await controller.getEstruturaExpandida(
                    itemPecas.codpeca!,
                    itemPecas.variaveis!,
                    itemPecas.comprimento!,
                    itemPecas.largura!,
                    itemPecas.espessura!,
                  );
                  if (result.isEmpty || result == 'Erro') {
                    // ignore: use_build_context_synchronously
                    _mostrarDialogComResultados(dialogContext, []);
                  } else {
                    final resultados = List<Map<String, dynamic>>.from(
                      json.decode(result),
                    );
                    // ignore: use_build_context_synchronously
                    _mostrarDialogComResultados(dialogContext, resultados);
                  }
                },
                icon: const Icon(Icons.add_box_outlined),
              ),
              theme,
            ),
          ],
        ),
    ],
    ),
  );
}

// ignore: must_be_immutable
class DetailsScreen extends StatelessWidget {
  DetailsScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());
  String? xmlString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Integra ForWood'),
        centerTitle: false,
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
                      leading: Icon(Icons.history),
                      title: Text('XMLs Importados'),
                      onTap: () {
                        Get.toNamed(PageRoutes.importedXmls);
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
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.article_outlined),
                      title: Text('Log do sistema'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(PageRoutes.systemLog);
                      },
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Obx(
                  () => Material(
                  elevation: 0,
                  color:
                      controller.sqlServerConnected.value
                          ? cs.primaryContainer.withValues(alpha: 0.55)
                          : cs.errorContainer.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          controller.sqlServerConnected.value
                              ? cs.primary.withValues(alpha: 0.35)
                              : cs.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              controller.sqlServerConnected.value
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color:
                                  controller.sqlServerConnected.value
                                      ? cs.primary
                                      : cs.error,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'SQL Server: ${controller.sqlServerStatus.value}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      controller.sqlServerConnected.value
                                          ? cs.onPrimaryContainer
                                          : cs.onErrorContainer,
                                ),
                              ),
                            ),
                            if (!controller.sqlServerConnected.value)
                              FilledButton.tonal(
                                onPressed: () => controller.connectSqlServer(),
                                child: const Text('Tentar'),
                              ),
                          ],
                        ),
                        if (controller.sqlServerError.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              controller.sqlServerError.value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                    FilledButton.icon(
                      onPressed: () async {
                        controller.cadiretaSuccess.value = false;
                        controller.saveOKCadireta.clear();
                        controller.outliteData.value = null;
                        final prefs = await SharedPreferences.getInstance();
                        final diretorio =
                            prefs.getString('diretorioXML') ?? 'T:\\xml';
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
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Abrir XML'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Get.toNamed(PageRoutes.importedXmls);
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('XMLs importados'),
                    ),
                    Obx(
                      () => FilledButton.icon(
                        onPressed:
                            controller.outliteData.value == null
                                ? null
                                : () async {
                                  final o = controller.outliteData.value!;
                                  final ok =
                                      await controller
                                          .confirmarEnvioParaForWoodSeNecessario(
                                            o,
                                          );
                                  if (!ok) return;
                                  controller.saveDataBase(
                                    outlite: o,
                                    xmlString: xmlString,
                                  );
                                },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Enviar ForWood'),
                      ),
                    ),
                    Obx(
                      () => FilledButton.tonalIcon(
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
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimir'),
                      ),
                    ),
                    GetBuilder<HomeScreenController>(
                      builder: (ctl) {
                        return Chip(
                          avatar: Icon(
                            Icons.storage_outlined,
                            size: 18,
                            color: ctl.databaseOn ? cs.primary : cs.error,
                          ),
                          label: Text(
                            ctl.databaseOn ? 'ForWood OK' : 'ForWood off',
                            style: theme.textTheme.labelMedium,
                          ),
                          backgroundColor: cs.surfaceContainerHighest,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      },
                    ),
                    GetBuilder<HomeScreenController>(
                      builder: (ctl) {
                        return Chip(
                          avatar: Icon(
                            Icons.dns_outlined,
                            size: 18,
                            color: ctl.databasePro ? cs.primary : cs.error,
                          ),
                          label: Text(
                            ctl.databasePro ? '3CAD OK' : '3CAD off',
                            style: theme.textTheme.labelMedium,
                          ),
                          backgroundColor: cs.surfaceContainerHighest,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: Obx(() {
                final outlite = controller.outliteData.value;
                if (controller.isLoading.value) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: LoadingWidget(
                        steps: controller.loadProgressSteps,
                        message: controller.loadProgressSteps.isEmpty
                            ? controller.statusMessage.value
                            : null,
                      ),
                    ),
                  );
                }
                if (controller.saveCadiretaLoading.value) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: LoadingWidget(
                        steps: controller.saveProgressSteps.isNotEmpty
                            ? controller.saveProgressSteps
                            : null,
                        message: controller.saveProgressSteps.isEmpty
                            ? "Importando dados para o ForWood..."
                            : null,
                      ),
                    ),
                  );
                }
                if (controller.saveOKCadireta.isNotEmpty) {
                  controller.saveCadiretaLoading.value = false;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.dangerous, color: Colors.red),
                            label: const Text(
                              "Erro ao importar dados para o ForWood! Clique para retornar!",
                            ),
                            onPressed: () {
                              controller.saveOKCadireta.clear();
                            },
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.saveOKCadireta.length,
                            itemBuilder: (_, index) {
                              return ListTile(
                                title: Text(controller.saveOKCadireta[index]),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (controller.saveOKCadireta.isEmpty &&
                    controller.cadiretaSuccess.value == true) {
                  controller.saveCadiretaLoading.value = false;
                  return SliverToBoxAdapter(
                    child: TextButton.icon(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text(
                        "Dados importados com sucesso! Importe um novo XML!",
                      ),
                      onPressed: () {},
                    ),
                  );
                }
                if (outlite != null && controller.saveOKCadireta.isEmpty) {
                  final modules = outlite.itembox;
                  final n = modules?.length ?? 0;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 0,
                                color: cs.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pedido',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 8,
                                        children: [
                                          _metaChip(
                                            theme,
                                            Icons.calendar_today_outlined,
                                            'Data',
                                            outlite.data ?? 'N/A',
                                          ),
                                          _metaChip(
                                            theme,
                                            Icons.tag_outlined,
                                            'Número',
                                            outlite.numero ?? 'N/A',
                                          ),
                                          _metaChip(
                                            theme,
                                            Icons.description_outlined,
                                            'RIF',
                                            outlite.rif,
                                          ),
                                          _metaChip(
                                            theme,
                                            Icons.account_tree_outlined,
                                            'Pai',
                                            outlite.codpai,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        }
                        final modIndex = index - 1;
                        final qtdfinal = multiplicaQtd(
                          modules![modIndex].qta!,
                          modules[modIndex].pz!,
                        );
                        final itemBox = modules[modIndex];
                        final hasErros = itemBox.totalErrosCount > 0;
                        final hasPend =
                            itemBox.totalPendentesCadastroCount > 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index > 1) const SizedBox(height: 10),
                            RepaintBoundary(
                              child: Material(
                                elevation: 0,
                                color: cs.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: hasErros
                                        ? cs.error.withValues(alpha: 0.65)
                                        : cs.outlineVariant
                                            .withValues(alpha: 0.55),
                                    width: hasErros ? 1.5 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    12,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itemBox.des ??
                                                      'Sem descrição',
                                                  style: theme
                                                      .textTheme.titleSmall
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Código ${itemBox.codigo ?? ''} · Qtd $qtdfinal · ${itemBox.l ?? '—'}×${itemBox.a ?? '—'}×${itemBox.p ?? '—'} mm',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (hasErros)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Tooltip(
                                                message:
                                                    '${itemBox.errosProducaoCount} erro(s) produção, ${itemBox.errosCompraCount} erro(s) compra',
                                                child: Chip(
                                                  avatar: Icon(
                                                    Icons
                                                        .warning_amber_rounded,
                                                    color: cs.error,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    '${itemBox.totalErrosCount} erro(s)',
                                                    style: theme
                                                        .textTheme.labelMedium
                                                        ?.copyWith(
                                                      color: cs.error,
                                                    ),
                                                  ),
                                                  backgroundColor: cs
                                                      .errorContainer
                                                      .withValues(alpha: 0.5),
                                                  side: BorderSide.none,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              ),
                                            ),
                                          if (hasPend) ...[
                                            if (hasErros)
                                              const SizedBox(width: 6),
                                            Tooltip(
                                              message:
                                                  'Cadastrar no PostgreSQL/ForWood',
                                              child: Chip(
                                                avatar: Icon(
                                                  Icons.edit_note_rounded,
                                                  color: cs.primary,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  '${itemBox.totalPendentesCadastroCount} atualizar',
                                                  style: theme
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                    color: cs.primary,
                                                  ),
                                                ),
                                                backgroundColor: cs
                                                    .primaryContainer
                                                    .withValues(alpha: 0.45),
                                                side: BorderSide.none,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              widgetproduzidos(
                                                context,
                                                outlite,
                                                modIndex,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.precision_manufacturing,
                                              size: 20,
                                            ),
                                            label: const Text('Fabricados'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              widgetcomprados(
                                                context,
                                                outlite,
                                                modIndex,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 20,
                                            ),
                                            label: const Text('Comprados'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: 1 + n,
                    ),
                  );
                }
                return const SliverToBoxAdapter(
                  child: Text('Nenhum dado XML carregado.'),
                );
              }),
          ),
        ],
      ),
    );
  }

  void widgetcomprados(BuildContext context, Outlite outlite, int index) {
    final prices = outlite.itembox![index].itemPrice ?? [];
    showDialog<String>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Itens comprados'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: prices.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma linha de compra para este módulo.',
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                )
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _buildCompradosTable(prices, Theme.of(ctx)),
                    ),
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
    final pecas = outlite.itembox![index].itemPecas ?? [];
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Itens fabricados'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: pecas.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma peça fabricada para este módulo.',
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                )
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _buildFabricadosTable(
                        pecas: pecas,
                        controller: controller,
                        dialogContext: ctx,
                      ),
                    ),
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
