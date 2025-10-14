// ... existing code ...
import 'dart:async';
import 'dart:io';

String? _pedidoLogFilePath;
String? _lastTableWritten;

Future<void> initLogsFolder() async {
  try {
    final dir = Directory('${Directory.current.path}\\log');
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
  } catch (_) {}
}

Future<void> initPedidoLog(String numeroPedidoOuArquivo) async {
  await initLogsFolder();
  final normalized = numeroPedidoOuArquivo.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '_');
  _pedidoLogFilePath = '${Directory.current.path}\\log\\$normalized.csv';
  try {
    final file = File(_pedidoLogFilePath!);
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    _lastTableWritten = null;
  } catch (_) {}
}

String _csvEscape(dynamic value) {
  final s = value?.toString() ?? '';
  final needsQuote = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
  final escaped = s.replaceAll('"', '""');
  return needsQuote ? '"$escaped"' : escaped;
}

Future<void> appendPedidoLog(
  String tabela,
  Map<String, dynamic> dados, {
  String? status,
  String? erro,
}) async {
  if (_pedidoLogFilePath == null) return;
  try {
    final file = File(_pedidoLogFilePath!);

    if (_lastTableWritten != tabela) {
      final header = dados.keys.join(',');
      await file.writeAsString('$tabela\n$header\n', mode: FileMode.append);
      _lastTableWritten = tabela;
    }

    final keys = dados.keys.toList();
    final valuesLine = keys.map((k) => _csvEscape(dados[k])).join(',');
    await file.writeAsString('$valuesLine\n', mode: FileMode.append);
  } catch (_) {}
}
// ... existing code ...