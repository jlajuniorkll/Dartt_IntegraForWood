import 'dart:convert';
import 'dart:io';

import 'package:dartt_integraforwood/db/sqlserver_connection.dart';

int? multiplicaQtd(String s, String t) {
  int? result;
  final val1 = int.parse(s);
  final val2 = int.parse(t);
  if (val2 > 0) {
    result = val1 * val2;
  } else {
    result = val1;
  }
  return result;
}

/// Função que replica a funcionalidade do SQL Server dbo.ZeroPad
/// Adiciona zeros à esquerda até atingir o comprimento especificado
String zeroPad(dynamic value, int length) {
  String stringValue = value?.toString() ?? '0';
  return stringValue.padLeft(length, '0');
}

/// Função que gera a matrícula formatada seguindo o padrão:
/// 'C' + ZeroPad(numero, 6) + ZeroPad(matricola, 6)
String formatMatricula(dynamic numero, dynamic matricola) {
  return 'C${zeroPad(numero, 6)}${zeroPad(matricola, 6)}';
}

/// Função que gera a matrícula formatada usando número de fabricação
/// 'C' + ZeroPad(numeroFabricacao, 6) + ZeroPad(matricula, 6)
String formatMatriculaComFabricacao(
  dynamic numeroFabricacao,
  dynamic matricula,
) {
  return 'C${zeroPad(numeroFabricacao, 6)}${zeroPad(matricula, 6)}';
}

/// Extrai a matrícula (número) de uma matrícula formatada (ex: C000001000002 -> 2)
/// ou retorna o valor original se não estiver no formato esperado
String extractMatricola(String? matricula) {
  if (matricula == null || matricula.trim().isEmpty) return '0';
  // Formato C + 6 dígitos numero + 6 dígitos matricola
  final match = RegExp(r'^C\d{6}(\d{6})$').firstMatch(matricula.trim());
  if (match != null) {
    final s = match.group(1)!.replaceFirst(RegExp(r'^0+'), '');
    return s.isEmpty ? '0' : s;
  }
  // Se for só um número, retorna como está
  return matricula.trim();
}

/// Função para consultar Lista_corte e buscar PRG1 e PRG2
Future<Map<String, String>> consultarListaCorte(
  String numeroFabricacao,
  String matricola,
) async {
  final mssqlConnection = SqlServerConnection.getInstance().mssqlConnection;
  String codpeca = formatMatriculaComFabricacao(numeroFabricacao, matricola);

  String query =
      "SELECT PRG1, PRG2 FROM Lista_corte WHERE numero='$numeroFabricacao' AND idpeca='$codpeca'";

  try {
    String rawResult = await mssqlConnection.getData(query);
    List<dynamic> parsed = jsonDecode(rawResult);

    if (parsed.isNotEmpty && parsed.first is Map<String, dynamic>) {
      Map<String, dynamic> result = parsed.first;
      return {
        'PRG1': result['PRG1']?.toString() ?? '',
        'PRG2': result['PRG2']?.toString() ?? '',
      };
    }
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao consultar Lista_corte: $e');
  }

  return {'PRG1': '', 'PRG2': ''};
}

String? _pedidoLogFilePath;
String? _lastTableWritten;

String initPedidoLog(String numeroPedido) {
  final baseDir = Directory('${Directory.current.path}\\log');
  if (!baseDir.existsSync()) {
    baseDir.createSync(recursive: true);
  }
  final safeNumero = numeroPedido.isNotEmpty
      ? numeroPedido
      : 'pedido_desconhecido_${DateTime.now().millisecondsSinceEpoch}';
  final filePath = '${baseDir.path}\\$safeNumero.csv';
  final file = File(filePath);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  _pedidoLogFilePath = filePath;
  _lastTableWritten = null;
  return filePath;
}

String _csvEscape(dynamic value) {
  final s = value?.toString() ?? '';
  final needsQuote = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
  final escaped = s.replaceAll('"', '""');
  return needsQuote ? '"$escaped"' : escaped;
}

void appendPedidoLog(String tabela, Map<String, dynamic> registro) {
  try {
    if (_pedidoLogFilePath == null) return;
    final file = File(_pedidoLogFilePath!);

    if (_lastTableWritten != tabela) {
      final header = registro.keys.join(',');
      file.writeAsStringSync('$tabela\n$header\n', mode: FileMode.append);
      _lastTableWritten = tabela;
    }

    final keys = registro.keys.toList();
    final values = keys.map((k) => _csvEscape(registro[k])).join(',');
    file.writeAsStringSync('$values\n', mode: FileMode.append);
  } catch (_) {}
}

Future<void> initLogsFolder() async {
  try {
    final dir = Directory('${Directory.current.path}\\log');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  } catch (_) {}
}
