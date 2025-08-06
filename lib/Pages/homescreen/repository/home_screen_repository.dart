import 'dart:convert';

import 'package:dartt_integraforwood/Models/cadiredi.dart';
import 'package:dartt_integraforwood/Models/cadireta.dart';
import 'package:dartt_integraforwood/db/postgres_connection.dart';
import 'package:dartt_integraforwood/db/sqlserver_connection.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:postgres/postgres.dart';

class HomeScreenRepository {
  Future<String> getDescricaoProduto(String codigoProduto) async {
    final connection = PostgresConnection().connection;
    final mssqlConnection = SqlServerConnection().mssqlConnection;

    if (connection == null) {
      return 'Erro: Conexão não iniciada';
    }

    final result = await connection.execute(
      Sql.named(
        'SELECT descricao_produto FROM vw_produto WHERE codigo_produto = @codigo',
      ),
      parameters: {'codigo': codigoProduto},
    );

    if (result.isEmpty) {
      String query = "SELECT des FROM articoli WHERE cod = '$codigoProduto'";
      String rawResult = await mssqlConnection.getData(
        query,
      ); // recebe como String
      List<dynamic> parsed = jsonDecode(rawResult); // decodifica o JSON
      if (parsed.isEmpty) {
        return 'Erro: Produto não cadastrado';
      }
      return parsed.first["des"] as String; // acessa o valor
    } else {
      final descricao = result.first.toColumnMap()['descricao_produto'];
      return descricao?.toString() ?? 'Erro: Sem descrição';
    }
  }

  Future<String> getProdutoForId(String codigoProduto, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      return jsonEncode({'erro': 'Conexão não iniciada'});
    }

    final result = await connection.execute(
      Sql.named('SELECT * FROM vw_produto WHERE codigo_produto = @codigo'),
      parameters: {'codigo': codigoProduto},
    );

    final lista = result.map((row) => row.toColumnMap()).toList();
    String returntype = '';
    for (var item in lista) {
      // item é um Map<String, dynamic>
      switch (s) {
        case 'grupo_produto':
          returntype = item['grupo_produto'].toString();
        case 'subgrupo_produto':
          returntype = item['subgrupo_produto'].toString();
        case 'um_produto':
          returntype = item['um_produto'].toString();
        case 'origem_produto':
          returntype = item['origem_produto'].toString();
        case 'status_produto':
          returntype = item['status_produto'].toString();
        case 'fase_padrao_consumo':
          returntype = item['fase_padrao_consumo'].toString();
      }
    }
    return returntype;
    // Converte cada linha para Map<String, dynamic> de forma segura
    //final lista = result.map((row) => row.toColumnMap()).toList();
    //return jsonEncode(lista);
  }

  Future<String> saveCadireta(Cadireta cadireta, int contador, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final deleteQuery = Sql.named('DELETE FROM cadireta');
    final query = Sql.named(
      'INSERT INTO cadireta (CADCONT, CADPAI, CADFILHO, CADSTATUS, CADSUSCAD, CADPAINOME, CADFILNOME, CADPAIUM, CADFILUM, CADUSO, CADCOMP, CADLARG, CADESPE, CADPESO, CADFASE, CADGRAV, CADHORA, CADIMPDT, CADIMPHR, CADUSUIMP, CADLOCAL, CADGRPAI, CADSGPAI, CADGRFIL, CADSGFIL, CADPRIEMB, CADPROJ, CADARQUIVO, CADCOBR, CADLABR, CADESBR, CADCLASS, CADPLCOR, CADUSAMED, CADBORINT, CADBORSUP, CADBORINF, CADBORESQ, CADBORDIR, CADPAIAREA, CADTIPFIL, CADPEMBPR, CADPEMBPP, CADINDTER, CADDIMPER, CADAPP, CADARQFIL, CADPESBRU, CADPAIFAN, CADMARCA, CADUSUMA, CADMCONTP, CADMPAI, CADIDLOTE, CADREAP, CADLIGFAN) '
      'VALUES (@CADCONT, @CADPAI, @CADFILHO, @CADSTATUS, @CADSUSCAD, @CADPAINOME, @CADFILNOME, @CADPAIUM, @CADFILUM, @CADUSO, @CADCOMP, @CADLARG, @CADESPE, @CADPESO, @CADFASE, @CADGRAV, @CADHORA, @CADIMPDT, @CADIMPHR, @CADUSUIMP, @CADLOCAL, @CADGRPAI, @CADSGPAI, @CADGRFIL, @CADSGFIL, @CADPRIEMB, @CADPROJ, @CADARQUIVO, @CADCOBR, @CADLABR, @CADESBR, @CADCLASS, @CADPLCOR, @CADUSAMED, @CADBORINT, @CADBORSUP, @CADBORINF, @CADBORESQ, @CADBORDIR, @CADPAIAREA, @CADTIPFIL, @CADPEMBPR, @CADPEMBPP, @CADINDTER, @CADDIMPER, @CADAPP, @CADARQFIL, @CADPESBRU, @CADPAIFAN, @CADMARCA, @CADUSUMA, @CADMCONTP, @CADMPAI, @CADIDLOTE, @CADREAP, @CADLIGFAN)',
    );
    final parameters = {
      'CADCONT': cadireta.cadcont,
      'CADPAI': cadireta.cadpai,
      'CADFILHO': cadireta.cadfilho,
      'CADSTATUS': cadireta.cadstatus,
      'CADSUSCAD': cadireta.cadsuscad,
      'CADPAINOME': cadireta.cadpainome,
      'CADFILNOME': cadireta.cadfilnome,
      'CADPAIUM': cadireta.cadpaium,
      'CADFILUM': cadireta.cadfilum,
      'CADUSO': cadireta.caduso,
      'CADCOMP': cadireta.cadcobr,
      'CADLARG': cadireta.cadlabr,
      'CADESPE': cadireta.cadesbr,
      'CADPESO': cadireta.cadpeso,
      'CADFASE': cadireta.cadfase,
      'CADGRAV': cadireta.cadgrav,
      'CADHORA': cadireta.cadhora,
      'CADIMPDT': cadireta.cadimpdt,
      'CADIMPHR': cadireta.cadimphr,
      'CADUSUIMP': cadireta.cadusuimp,
      'CADLOCAL': cadireta.cadlocal,
      'CADGRPAI': cadireta.cadgrpai,
      'CADSGPAI': cadireta.cadsgpai,
      'CADGRFIL': cadireta.cadsgrfil,
      'CADSGFIL': cadireta.cadsgfil,
      'CADPRIEMB': cadireta.cadoriemb,
      'CADPROJ': cadireta.cadproj,
      'CADARQUIVO': cadireta.cadarquivo,
      'CADCOBR': cadireta.cadcobr,
      'CADLABR': cadireta.cadlabr,
      'CADESBR': cadireta.cadesbr,
      'CADCLASS': cadireta.cadclass,
      'CADPLCOR': cadireta.cadplcor,
      'CADUSAMED': cadireta.cadusamed,
      'CADBORINT': cadireta.cadborint,
      'CADBORSUP': cadireta.cadbordsup,
      'CADBORINF': cadireta.cadbordinf,
      'CADBORESQ': cadireta.cadboresq,
      'CADBORDIR': cadireta.cadbordir,
      'CADPAIAREA': cadireta.cadpaiarea,
      'CADTIPFIL': cadireta.cadtpfil,
      'CADPEMBPR': cadireta.cadpembpr,
      'CADPEMBPP': cadireta.cadpembpp,
      'CADINDTER': cadireta.cadindter,
      'CADDIMPER': cadireta.caddimper,
      'CADAPP': cadireta.cadapp,
      'CADARQFIL': '',
      'CADPESBRU': 0.000,
      'CADPAIFAN': '',
      'CADMARCA': '',
      'CADUSUMA': '',
      'CADMCONTP': 0,
      'CADMPAI': '',
      'CADIDLOTE': 0,
      'CADREAP': '',
      'CADLIGFAN': '',
    };
    try {
      await connection.execute(deleteQuery);
      await connection.execute(query, parameters: parameters);
      return "";
    } catch (e) {
      return 'Erro linha $contador da $s: $e';
    }
  }

  Future<String> saveCadiredi(Cadiredi cadiredi, int contador, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final deleteQuery = Sql.named('DELETE FROM cadiredi');
    final query = Sql.named(
      'INSERT INTO cadiredi (caddcont, caddpai, caddfil, caddseq, caddcom, caddlar, caddesp, caddcob, caddlab, caddesb, caddcor, caddbint, caddbsup, caddbinf, caddbesq, caddbdir, caddpdes, caddper, caddqtd) '
      'VALUES (@caddcont, @caddpai, @caddfil, @caddseq, @caddcom, @caddlar, @caddesp, @caddcob, @caddlab, @caddesb, @caddcor, @caddbint, @caddbsup, @caddbinf, @caddbesq, @caddbdir, @caddpdes, @caddper, @caddqtd)',
    );
    final parameters = {
      'caddcont': cadiredi.cadcont,
      'caddpai': cadiredi.cadpai,
      'caddfil': cadiredi.cadfilho,
      'caddseq': cadiredi.caddseq,
      'caddcom': cadiredi.caddcom,
      'caddlar': cadiredi.caddlab,
      'caddesp': cadiredi.caddesp,
      'caddcob': cadiredi.caddcob,
      'caddlab': cadiredi.caddlab,
      'caddesb': cadiredi.caddesb,
      'caddcor': cadiredi.cadcor,
      'caddbint': cadiredi.caddbint,
      'caddbsup': cadiredi.caddbsup,
      'caddbinf': cadiredi.caddbinf,
      'caddbesq': cadiredi.caddbesq,
      'caddbdir': cadiredi.caddbdir,
      'caddpdes': cadiredi.caddpdes,
      'caddper': cadiredi.caddper,
      'caddqtd': cadiredi.caddqtd,
    };
    try {
      await connection.execute(deleteQuery);
      await connection.execute(query, parameters: parameters);
      return "";
    } catch (e) {
      return 'Erro linha $contador da $s: $e';
    }
  }

  Future<String> getEstruturaExpandida(
    String? codpeca,
    String? variaveis,
    double comp,
    double larg,
    double alt,
  ) async {
    final mssqlConnection = SqlServerConnection().mssqlConnection;

    String query = "SELECT CodiceDistinta FROM articoli WHERE cod = '$codpeca'";
    String rawResult = await mssqlConnection.getData(
      query,
    ); // recebe como String
    List<dynamic> parsed = jsonDecode(rawResult); // decodifica o JSON
    final codDistinta =
        parsed.first["CodiceDistinta"] as String; // acessa o valor
    if (codDistinta != "") {
      return getDistinta(codDistinta, variaveis, comp, larg, alt);
    } else {
      return "";
    }
  }

  Future<String> getDistinta(
    String codDistinta,
    String? variaveis,
    double comp,
    double larg,
    double alt,
  ) async {
    final mssqlConnection = SqlServerConnection().mssqlConnection;

    // 1. Consulta principal da distinta
    String query =
        "SELECT CODFIG, QTA, FASE FROM DISTINTA WHERE cod = '$codDistinta'";
    String rawResult = await mssqlConnection.getData(query);

    List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(
      json.decode(rawResult),
    );

    // 2. Monta mapa de variáveis vindas da string
    Map<String, String> valores = {};
    for (var par in variaveis!.split(';')) {
      if (par.contains('=')) {
        var partes = par.split('=');
        valores[partes[0].toUpperCase()] = partes[1];
      }
    }

    // 3. Adiciona variáveis de dimensão
    valores['L'] = comp.toString();
    valores['A'] = larg.toString();
    valores['P'] = alt.toString();

    List<Map<String, dynamic>> processados = [];
    Set<String> codigosUnicos = {};
    Set<String> fasesCodigosParaBuscar = {};

    for (var item in jsonList) {
      final codfig =
          substituirVariaveis(item['CODFIG'], valores).trim().toUpperCase();
      String qtaRaw = item['QTA']?.replaceAll('\u0010', '').trim() ?? '';
      String qtaSubstituida = substituirVariaveis(qtaRaw, valores);

      double? valorFinal;
      try {
        // ignore: deprecated_member_use
        Expression exp = Parser().parse(qtaSubstituida);
        ContextModel cm = ContextModel();
        valorFinal = exp.evaluate(EvaluationType.REAL, cm);
      } catch (_) {
        valorFinal = double.tryParse(qtaSubstituida);
      }

      if (valorFinal != null && codfig.isNotEmpty) {
        final fase = item['FASE']?.toString().trim() ?? '';
        if (fase.isEmpty) {
          fasesCodigosParaBuscar.add(codfig);
        }

        codigosUnicos.add(codfig);
        processados.add({
          'CODFIG': codfig,
          'QTA': valorFinal.toStringAsFixed(4),
          'FASE': fase,
        });
      }
    }

    // 4. Busca descrição dos CODFIG
    Map<String, String> mapaDescricao = {};
    if (codigosUnicos.isNotEmpty) {
      String codigosStr = codigosUnicos.map((c) => "'$c'").join(',');
      String queryDesc =
          "SELECT cod, des FROM articoli WHERE UPPER(LTRIM(RTRIM(cod))) IN ($codigosStr)";
      String rawDescResult = await mssqlConnection.getData(queryDesc);

      List<Map<String, dynamic>> descList = List<Map<String, dynamic>>.from(
        json.decode(rawDescResult),
      );

      for (var d in descList) {
        String key = (d['cod'] ?? '').toString().trim().toUpperCase();
        String desc = (d['des'] ?? '').toString();
        mapaDescricao[key] = desc;
      }
    }

    // 5. Busca descrição das fases faltantes (onde FASE estava em branco)
    Map<String, String> mapaFaseDescricao = {};
    if (fasesCodigosParaBuscar.isNotEmpty) {
      for (String cod in fasesCodigosParaBuscar) {
        String queryFase = "SELECT des FROM fasi WHERE cod = '$cod'";
        String rawFaseResult = await mssqlConnection.getData(queryFase);
        try {
          List<dynamic> faseList = json.decode(rawFaseResult);
          if (faseList.isNotEmpty) {
            String descricaoFase = faseList.first['des'] ?? '';
            mapaFaseDescricao[cod] = descricaoFase;
          }
        } catch (_) {
          mapaFaseDescricao[cod] = '';
        }
      }
    }

    // 6. Adiciona descrições ao resultado final
    for (var item in processados) {
      final cod = item['CODFIG'];
      if ((item['FASE'] ?? '').isEmpty) {
        item['DESCRICAO'] = mapaFaseDescricao[cod] ?? '';
      } else {
        item['DESCRICAO'] = mapaDescricao[cod] ?? '';
      }
    }

    // 7. Resultado final
    // print(jsonEncode(processados));
    return jsonEncode(processados);
  }

  // 3. Função para substituir placeholders
  String substituirVariaveis(String input, Map<String, String> valores) {
    RegExp regex = RegExp(r"<([^<>]+)>");
    return input.replaceAllMapped(regex, (match) {
      String chave = match.group(1)?.toUpperCase() ?? '';
      return valores[chave] ?? '';
    });
  }

  // busca descrição do item
  Future<String> buscarDescricao(String codfig) async {
    final mssqlConnection = SqlServerConnection().mssqlConnection;
    String query = "SELECT DESCRICAO FROM PRODUTOS WHERE CODFIG = '$codfig'";
    String rawResult = await mssqlConnection.getData(query);

    try {
      List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
        json.decode(rawResult),
      );
      if (result.isNotEmpty) {
        return result.first['DESCRICAO'] ?? '';
      }
    } catch (_) {}
    return '';
  }
}
