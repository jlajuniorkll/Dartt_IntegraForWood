import 'dart:math';

import 'package:dartt_integraforwood/Models/xml_history.dart';
import 'package:dartt_integraforwood/Pages/imported_xmls/helpers/table_compare_isolate.dart';
import 'package:dartt_integraforwood/services/xml_importado_service.dart';
import 'package:flutter/material.dart';

const double _kRadius = 12;

/// Compara revisões do mesmo XML em formato de tabela (cadireta, cadiredi, cadproce, cadire2).
class VersionTablesComparisonScreen extends StatefulWidget {
  const VersionTablesComparisonScreen({super.key, required this.xmlNumero});

  final String xmlNumero;

  @override
  State<VersionTablesComparisonScreen> createState() =>
      _VersionTablesComparisonScreenState();
}

class _VersionTablesComparisonScreenState
    extends State<VersionTablesComparisonScreen>
    with SingleTickerProviderStateMixin {
  final _service = XmlImportadoService();
  TabController? _tabController;

  List<XmlImportado> _revisoes = [];
  XmlImportado? _esq;
  XmlImportado? _dir;
  bool _loading = true;
  String? _loadError;

  void _disposeTabController() {
    _tabController?.dispose();
    _tabController = null;
  }

  void _ensureTabController() {
    if (!mounted || _revisoes.isEmpty) return;
    if (_tabController != null) return;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _disposeTabController();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await _service.getXmlsByNumero(widget.xmlNumero);
      list.sort((a, b) => a.revisao.compareTo(b.revisao));
      if (!mounted) return;
      setState(() {
        _revisoes = list;
        if (list.length >= 2) {
          _esq = list[list.length - 2];
          _dir = list.last;
        } else if (list.length == 1) {
          _esq = list.first;
          _dir = list.first;
        }
        _loading = false;
        _ensureTabController();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showTabs =
        !_loading &&
        _loadError == null &&
        _revisoes.isNotEmpty &&
        _tabController != null;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Comparar versões — XML ${widget.xmlNumero}'),
        bottom:
            showTabs
                ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Cadireta'),
                    Tab(text: 'Cadiredi'),
                    Tab(text: 'Cadproce'),
                    Tab(text: 'Cadire2'),
                  ],
                )
                : null,
      ),
      body:
          _loading
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : _loadError != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar revisões: $_loadError',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _revisoes.isEmpty
              ? const Center(child: Text('Nenhuma revisão encontrada.'))
              : _tabController == null
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRevisionSelectors(cs, theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController!,
                      children: [
                        _TablePanel(
                          title:
                              'Linhas gravadas na cadireta (estrutura enviada ao ForWood).',
                          subtitle:
                              'Cada linha é um registro. Células com fundo indicam diferença entre revisões.',
                          leftLabel: 'Rev. ${_esq?.revisao ?? "—"}',
                          rightLabel: 'Rev. ${_dir?.revisao ?? "—"}',
                          child: _ListRowsDiff(
                            _esq?.jsonCadireta,
                            _dir?.jsonCadireta,
                          ),
                        ),
                        _TablePanel(
                          title: 'Cadiredi (dados associados ao pedido).',
                          subtitle:
                              'Comparação campo a campo. Na importação este bloco segue o formato do snapshot salvo.',
                          leftLabel: 'Rev. ${_esq?.revisao ?? "—"}',
                          rightLabel: 'Rev. ${_dir?.revisao ?? "—"}',
                          child: _FlatFieldDiff(
                            _esq?.jsonCadiredi,
                            _dir?.jsonCadiredi,
                          ),
                        ),
                        _TablePanel(
                          title: 'Cadproce (processo / pedido).',
                          subtitle: 'Mesmo tipo de comparação que Cadiredi.',
                          leftLabel: 'Rev. ${_esq?.revisao ?? "—"}',
                          rightLabel: 'Rev. ${_dir?.revisao ?? "—"}',
                          child: _FlatFieldDiff(
                            _esq?.jsonCadproce,
                            _dir?.jsonCadproce,
                          ),
                        ),
                        _TablePanel(
                          title: 'Cadire2 (produção).',
                          subtitle:
                              'Só existe após envio à produção; revisões antigas podem estar vazias.',
                          leftLabel: 'Rev. ${_esq?.revisao ?? "—"}',
                          rightLabel: 'Rev. ${_dir?.revisao ?? "—"}',
                          child: _ListRowsDiff(
                            _esq?.jsonCadire2,
                            _dir?.jsonCadire2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildRevisionSelectors(ColorScheme cs, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisão à esquerda',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<XmlImportado>(
                    // ignore: deprecated_member_use
                    value: _esq,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        _revisoes
                            .map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text('Rev. ${x.revisao}'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _esq = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisão à direita',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<XmlImportado>(
                    // ignore: deprecated_member_use
                    value: _dir,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        _revisoes
                            .map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text('Rev. ${x.revisao}'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _dir = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablePanel extends StatelessWidget {
  const _TablePanel({
    required this.title,
    required this.subtitle,
    required this.leftLabel,
    required this.rightLabel,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String leftLabel;
  final String rightLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChipLegend(
                label: leftLabel,
                color: cs.primaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChipLegend(
                label: rightLabel,
                color: cs.secondaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ChipLegend extends StatelessWidget {
  const _ChipLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Diff para listas de objetos (cadireta, cadire2).
class _ListRowsDiff extends StatefulWidget {
  const _ListRowsDiff(this.rawA, this.rawB);

  final String? rawA;
  final String? rawB;

  @override
  State<_ListRowsDiff> createState() => _ListRowsDiffState();
}

class _ListRowsDiffState extends State<_ListRowsDiff> {
  Future<ListRowsDiffData>? _future;

  @override
  void initState() {
    super.initState();
    _future = computeListRowsDiffAsync(widget.rawA, widget.rawB);
  }

  @override
  void didUpdateWidget(covariant _ListRowsDiff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawA != widget.rawA || oldWidget.rawB != widget.rawB) {
      _future = computeListRowsDiffAsync(widget.rawA, widget.rawB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FutureBuilder<ListRowsDiffData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: cs.primary),
          );
        }
        if (snap.hasError) {
          return Text(
            'Erro ao processar JSON: ${snap.error}',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
          );
        }
        final rowsA = snap.data!.rowsA;
        final rowsB = snap.data!.rowsB;
        final cols = snap.data!.cols;
        if (cols.isEmpty) {
          return Text(
            'Sem dados nesta revisão.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          );
        }
        final n = max(rowsA.length, rowsB.length);
        if (n == 0) {
          return Text(
            'Sem linhas para comparar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          );
        }

        return RepaintBoundary(
          child: Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                cs.surfaceContainerHigh,
              ),
              columns: [
                const DataColumn(label: Text('Linha')),
                ...cols.map(
                  (c) => DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72),
                      child: Text(
                        c,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
                const DataColumn(label: Text('')),
              ],
              rows: List.generate(n, (i) {
                final ma = i < rowsA.length ? rowsA[i] : <String, String>{};
                final mb = i < rowsB.length ? rowsB[i] : <String, String>{};
                var rowDiff = false;
                for (final c in cols) {
                  if ((ma[c] ?? '') != (mb[c] ?? '')) rowDiff = true;
                }
                final onlyA = i >= rowsB.length;
                final onlyB = i >= rowsA.length;
                if (onlyA || onlyB) rowDiff = true;
                return DataRow(
                  color:
                      WidgetStatePropertyAll(
                        rowDiff
                            ? cs.errorContainer.withValues(alpha: 0.22)
                            : null,
                      ),
                  cells: [
                    DataCell(Text('${i + 1}')),
                    ...cols.map((c) {
                      final va = ma[c] ?? (onlyB ? '—' : '');
                      final vb = mb[c] ?? (onlyA ? '—' : '');
                      final cellDiff = va != vb;
                      return DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'A: $va',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight:
                                      cellDiff
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'B: $vb',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.secondary,
                                  fontWeight:
                                      cellDiff
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Icon(
                        rowDiff
                            ? Icons.change_circle_outlined
                            : Icons.check_circle_outline,
                        size: 20,
                        color: rowDiff ? cs.error : cs.primary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
          ),
        );
      },
    );
  }
}

/// Diff campo a campo (objeto JSON achatado).
class _FlatFieldDiff extends StatefulWidget {
  const _FlatFieldDiff(this.rawA, this.rawB);

  final String? rawA;
  final String? rawB;

  @override
  State<_FlatFieldDiff> createState() => _FlatFieldDiffState();
}

class _FlatFieldDiffState extends State<_FlatFieldDiff> {
  Future<FlatFieldDiffData>? _future;

  @override
  void initState() {
    super.initState();
    _future = computeFlatFieldDiffAsync(widget.rawA, widget.rawB);
  }

  @override
  void didUpdateWidget(covariant _FlatFieldDiff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawA != widget.rawA || oldWidget.rawB != widget.rawB) {
      _future = computeFlatFieldDiffAsync(widget.rawA, widget.rawB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FutureBuilder<FlatFieldDiffData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: cs.primary),
          );
        }
        if (snap.hasError) {
          return Text(
            'Erro ao processar JSON: ${snap.error}',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
          );
        }
        final mapA = snap.data!.mapA;
        final mapB = snap.data!.mapB;
        final keys = snap.data!.keys;
        if (keys.isEmpty) {
          return Text(
            'Sem dados para comparar nesta revisão.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          );
        }

        return RepaintBoundary(
          child: Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                cs.surfaceContainerHigh,
              ),
              columns: const [
                DataColumn(label: Text('Campo')),
                DataColumn(label: Text('Revisão A')),
                DataColumn(label: Text('Revisão B')),
                DataColumn(label: Text('')),
              ],
              rows:
                  keys.map((k) {
                    final va = mapA[k] ?? '—';
                    final vb = mapB[k] ?? '—';
                    final diff = va != vb;
                    return DataRow(
                      color: WidgetStatePropertyAll(
                        diff
                            ? cs.errorContainer.withValues(alpha: 0.22)
                            : null,
                      ),
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              k,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              va,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              vb,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            diff
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            size: 20,
                            color: diff ? cs.error : cs.primary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
          ),
        );
      },
    );
  }
}
