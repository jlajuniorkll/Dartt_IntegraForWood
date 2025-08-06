import 'package:dartt_integraforwood/Models/outlite.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  Future<void> printCompradosReport(Outlite outlite) async {
    final doc = pw.Document();
    final Map<String, double> comprados = {};

    for (var itembox in outlite.itembox!) {
      for (var itemPrice in itembox.itemPrice!) {
        final key = '${itemPrice.codigo} - ${itemPrice.des}';
        comprados[key] = (comprados[key] ?? 0) + double.parse(itemPrice.qtd!);
      }
    }

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Relatório de Itens Comprados',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Data: ${outlite.data}'),
                  ],
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Número: ${outlite.numero}'),
                  pw.Text('RIF: ${outlite.rif}'),
                ],
              ),
              pw.SizedBox(height: 20),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(4.5),
                  2: const pw.FlexColumnWidth(1),
                },
                headers: ['Código', 'Descrição', 'Qtd'],
                data:
                    comprados.entries
                        .map(
                          (e) => [
                            e.key.split(' - ')[0],
                            e.key.split(' - ')[1],
                            e.value.toStringAsFixed(4).toString(),
                          ],
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printFabricadosReport(
    Outlite outlite,
    Map<String, Map<String, double>> fabricados,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> widgets = [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Relatório de Itens Fabricados por Fase',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Data: ${outlite.data}'),
                ],
              ),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Número: ${outlite.numero}'),
                pw.Text('RIF: ${outlite.rif}'),
              ],
            ),
            pw.SizedBox(height: 20),
          ];

          fabricados.forEach((fase, items) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    fase,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  // ignore: deprecated_member_use
                  pw.Table.fromTextArray(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FlexColumnWidth(1.5),
                    },
                    headers: ['Código', 'Descrição', 'Qtd'],
                    data:
                        items.entries.map((item) {
                          return [
                            item.key.split(' - ')[0],
                            item.key.split(' - ')[1],
                            item.value.toStringAsFixed(4).replaceAll('.', ','),
                          ];
                        }).toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            );
          });

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
