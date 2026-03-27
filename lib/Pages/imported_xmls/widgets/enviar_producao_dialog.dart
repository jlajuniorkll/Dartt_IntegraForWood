import 'dart:math' as math;

import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:dartt_integraforwood/Models/xml_history.dart';
import 'package:dartt_integraforwood/Pages/common/progress_step.dart';
import 'package:dartt_integraforwood/Pages/common/widget_loader.dart';
import 'package:dartt_integraforwood/Pages/homescreen/controller/home_screen_controller.dart';
import 'package:dartt_integraforwood/Pages/imported_xmls/controller/imported_xmls_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double _kR = 12;

/// Colunas gravadas em `cadire2` (igual a [Cadire2.toMapPersisted]).
const List<String> _kCadire2PersistedColumns = <String>[
  'cadinfcont',
  'cadinfprod',
  'cadinfseq',
  'cadinfdes',
  'cadinfinf',
];

enum _EnvioFase { enviando, sucesso, erro }

/// Diálogo com passos do envio, tabela CADIRE2 e botão OK ao terminar.
class EnviarProducaoDialog extends StatefulWidget {
  const EnviarProducaoDialog({
    super.key,
    required this.outlite,
    required this.xml,
    required this.importedController,
  });

  final Outlite outlite;
  final XmlImportado xml;
  final ImportedXmlsController importedController;

  @override
  State<EnviarProducaoDialog> createState() => _EnviarProducaoDialogState();
}

class _EnviarProducaoDialogState extends State<EnviarProducaoDialog> {
  final HomeScreenController _home = Get.find<HomeScreenController>();
  _EnvioFase _fase = _EnvioFase.enviando;
  List<Map<String, dynamic>> _cadire2Rows = [];
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _executar());
  }

  Future<void> _executar() async {
    try {
      final ok = await _home.enviarOutliteParaForWood(
        widget.outlite,
        onCadiretaSuccessPreview: (rows) {
          if (mounted) {
            setState(() => _cadire2Rows = rows);
          }
        },
      );
      if (!mounted) return;
      if (ok) {
        await widget.importedController.applyProductionSuccess(
          widget.xml,
          widget.outlite,
          _home.lastSavedCadire2Json,
        );
        setState(() => _fase = _EnvioFase.sucesso);
        Get.snackbar('Sucesso', 'XML enviado para produção');
      } else {
        final erros = _home.saveOKCadireta;
        setState(() {
          _fase = _EnvioFase.erro;
          _mensagemErro =
              erros.isNotEmpty
                  ? erros.join('; ')
                  : (_home.cadiretaEnvioAbortMotivo ??
                      'Falha ao gravar no ForWood.');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fase = _EnvioFase.erro;
          _mensagemErro = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canClose = _fase == _EnvioFase.sucesso || _fase == _EnvioFase.erro;

    return PopScope(
      canPop: canClose,
      child: Dialog(
        backgroundColor: cs.surfaceContainerLow,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kR),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = (MediaQuery.sizeOf(context).height * 0.88).clamp(
              420.0,
              900.0,
            );
            final w =
                (constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width) -
                8;
            return SizedBox(
              width: w.clamp(320, 920),
              height: h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enviar para produção',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (canClose)
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _fase == _EnvioFase.enviando
                          ? 'A gravar no ForWood (cadireta e lista_corte). Após a cadireta, REF (por módulo) e PRG '
                              'para cadire2 são mostrados abaixo antes da gravação.'
                          : _fase == _EnvioFase.sucesso
                          ? 'Envio concluído com sucesso.'
                          : 'O envio não foi concluído.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(() {
                      // Ler o RxList dentro do Obx; passar só a referência ao LoadingWidget
                      // não registra dependência e o GetX deixa o bloco cinza.
                      final steps = List<ProgressStep>.from(
                        _home.saveProgressSteps,
                      );
                      return Card(
                        elevation: 0,
                        color: cs.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kR),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LoadingWidget(
                            steps: steps,
                            showSpinner: _fase == _EnvioFase.enviando,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Registos CADIRE2 a gravar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Card(
                        elevation: 0,
                        color: cs.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kR),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) {
                            return Scrollbar(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: math.max(
                                        320,
                                        innerConstraints.maxWidth - 4,
                                      ),
                                    ),
                                    child: _cadire2Table(theme, cs),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_fase == _EnvioFase.erro && _mensagemErro != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        _mensagemErro!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.error,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: FilledButton(
                      onPressed:
                          canClose ? () => Navigator.of(context).pop() : null,
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cadire2Table(ThemeData theme, ColorScheme cs) {
    final rows = _cadire2Rows;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nenhuma linha CADIRE2 (módulo sem código ForWood, sem linhas em lista_corte para o número de fabricação, ou PRG em falta por peça).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }
    return DataTable(
      headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
      columns:
          _kCadire2PersistedColumns
              .map((k) => DataColumn(label: Text(k)))
              .toList(),
      rows:
          rows.map((m) {
            return DataRow(
              cells:
                  _kCadire2PersistedColumns.map((k) {
                    return DataCell(Text('${m[k] ?? ''}'));
                  }).toList(),
            );
          }).toList(),
    );
  }
}
