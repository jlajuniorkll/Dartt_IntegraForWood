import 'dart:convert';

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
