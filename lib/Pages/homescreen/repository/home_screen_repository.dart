import 'dart:convert';

import 'package:dartt_integraforwood/Models/cadire2.dart';
import 'package:dartt_integraforwood/Models/produto_resolve_result.dart';
import 'package:dartt_integraforwood/Models/cadiredi.dart';
import 'package:dartt_integraforwood/Models/cadireta.dart';
import 'package:dartt_integraforwood/db/postgres_connection.dart';
import 'package:dartt_integraforwood/db/sqlserver_connection.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:postgres/postgres.dart';
import 'package:dartt_integraforwood/commom/commom_functions.dart';

/// Uma linha em `estrutur` + dimensões do `produto` filho (multiplicidade = quantidade).
class EstruturFilhoDetalhe {
  final String estfilho;
  final String comprimento;
  final String largura;
  final String espessura;

  const EstruturFilhoDetalhe({
    required this.estfilho,
    required this.comprimento,
    required this.largura,
    required this.espessura,
  });
}

class HomeScreenRepository {
  Future<String?> findProdutoByNomeEMedidas(
    String pronome,
    String comp,
    String larg,
    String esp,
  ) async {
    final connection = PostgresConnection().connection;
    if (connection == null) {
      return null;
    }
    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT produto FROM produto '
          'WHERE pronome = @pronome '
          'AND proficom::text = @comp '
          'AND profilar::text = @larg '
          'AND profiesp::text = @esp '
          'LIMIT 1',
        ),
        parameters: {
          'pronome': pronome,
          'comp': comp,
          'larg': larg,
          'esp': esp,
        },
      );
      if (result.isEmpty) return null;
      return result.first.toColumnMap()['produto']?.toString();
    } catch (e) {
      // Se a consulta falhar, retorna null para cair no fluxo do especial
      return null;
    }
  }

  /// Descrição em `articoli` (SQL Server) pelo código.
  Future<String?> getDescricaoArticoli(String cod) async {
    try {
      final mssql = SqlServerConnection.getInstance().mssqlConnection;
      final escaped = cod.replaceAll("'", "''");
      final query = "SELECT des FROM articoli WHERE cod = '$escaped'";
      final rawResult = await mssql.getData(query);
      final parsed = jsonDecode(rawResult) as List;
      if (parsed.isNotEmpty) {
        return parsed.first['des']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Descrição em `vw_produto` pelo código PostgreSQL.
  Future<String?> getDescricaoVwProduto(String codigoPg) async {
    final connection = PostgresConnection().connection;
    if (connection == null) return null;
    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT descricao_produto FROM vw_produto WHERE codigo_produto = @codigo',
        ),
        parameters: {'codigo': codigoPg},
      );
      if (result.isEmpty) return null;
      return result.first.toColumnMap()['descricao_produto']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Resolve código/descrição para peça com dimensões (DISTINTAT).
  Future<ProdutoResolveResult> resolveProdutoComDimensoes(
    String codpeca,
    String comp,
    String larg,
    String esp,
  ) async {
    final connection = PostgresConnection().connection;
    if (connection == null) {
      return const ProdutoResolveResult(idpeca: 'Erro: Conexão não iniciada');
    }

    final descPgDireto = await getDescricaoVwProduto(codpeca);
    if (descPgDireto != null) {
      return ProdutoResolveResult(
        idpeca: descPgDireto,
        codigoProdutoPostgres: codpeca,
      );
    }

    final desSql = await getDescricaoArticoli(codpeca);
    if (desSql == null || desSql.trim().isEmpty) {
      return const ProdutoResolveResult(idpeca: 'Erro: Produto não cadastrado');
    }
    final pronome = desSql.trim();

    final pgCod = await findProdutoByNomeEMedidas(pronome, comp, larg, esp);
    if (pgCod != null) {
      final d = await getDescricaoVwProduto(pgCod) ?? pronome;
      return ProdutoResolveResult(
        idpeca: d,
        codigoProdutoPostgres: pgCod,
      );
    }

    return ProdutoResolveResult(
      idpeca: pronome,
      precisaCadastroForWood: true,
      descricaoSqlServer: pronome,
    );
  }

  /// Resolve item comprado (DETTPREZZO) — somente PostgreSQL (`vw_produto`).
  /// Itens fabricados (DISTINTAT) continuam usando [resolveProdutoComDimensoes], que pode consultar o SQL Server.
  Future<ProdutoResolveResult> resolveProdutoCodigoCompra(String codigo) async {
    final connection = PostgresConnection().connection;
    if (connection == null) {
      return const ProdutoResolveResult(idpeca: 'Erro: Conexão não iniciada');
    }

    final descPgDireto = await getDescricaoVwProduto(codigo);
    if (descPgDireto != null) {
      return ProdutoResolveResult(
        idpeca: descPgDireto,
        codigoProdutoPostgres: codigo,
      );
    }

    return const ProdutoResolveResult(idpeca: 'Erro: Produto não cadastrado');
  }

  /// Código `estproduto` em PostgreSQL para consultar `estrutur`.
  Future<String?> resolveEstprodutoParaEstrutur({
    required String? codigoRiga,
    required String? desModulo,
    required String? l,
    required String? a,
    required String? p,
  }) async {
    final c = (codigoRiga ?? '').trim();
    if (c.isNotEmpty && await estprodutoExisteEmEstrutur(c)) return c;
    final des = (desModulo ?? '').trim();
    if (des.isEmpty) return null;
    final pg = await findProdutoByNomeEMedidas(
      des,
      l ?? '',
      a ?? '',
      p ?? '',
    );
    if (pg != null && await estprodutoExisteEmEstrutur(pg)) return pg;
    return null;
  }

  /// Filhos com dimensões; cada linha = unidade de quantidade na estrutura.
  Future<List<EstruturFilhoDetalhe>> getFilhosEstruturDetalhado(
    String estproduto,
  ) async {
    final connection = PostgresConnection().connection;
    if (connection == null) return [];

    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT e.estfilho, p_filho.proficom::text AS comp, '
          'p_filho.profilar::text AS larg, p_filho.profiesp::text AS esp '
          'FROM estrutur e '
          'INNER JOIN produto p_filho ON p_filho.produto = e.estfilho '
          'WHERE e.estproduto = @estproduto',
        ),
        parameters: {'estproduto': estproduto},
      );

      return result
          .map((row) {
            final m = row.toColumnMap();
            return EstruturFilhoDetalhe(
              estfilho: m['estfilho']?.toString() ?? '',
              comprimento: m['comp']?.toString() ?? '0',
              largura: m['larg']?.toString() ?? '0',
              espessura: m['esp']?.toString() ?? '0',
            );
          })
          .where((e) => e.estfilho.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lista de códigos filhos (compatibilidade).
  Future<List<String>> getFilhosFromEstrutur(String estproduto) async {
    final det = await getFilhosEstruturDetalhado(estproduto);
    return det.map((e) => e.estfilho).toList();
  }

  /// Returns true if estproduto exists in estrutur table.
  Future<bool> estprodutoExisteEmEstrutur(String codigo) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      return false;
    }

    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT 1 FROM estrutur WHERE estproduto = @codigo LIMIT 1',
        ),
        parameters: {'codigo': codigo},
      );

      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String> getDescricaoProduto(String codigoProduto) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      return 'Erro: Conexão não iniciada';
    }

    final result = await connection.execute(
      Sql.named(
        'SELECT descricao_produto FROM vw_produto WHERE codigo_produto = @codigo',
      ),
      parameters: {'codigo': codigoProduto},
    );

    if (result.isNotEmpty) {
      final descricao = result.first.toColumnMap()['descricao_produto'];
      return descricao?.toString() ?? 'Erro: Sem descrição';
    }

    return 'Erro: Produto não cadastrado';
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

  Future<String> deleteCadireta() async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final query = Sql.named('DELETE FROM cadireta');
    try {
      await connection.execute(query);
      return "";
    } catch (e) {
      return 'Erro ao deletar cadireta: $e';
    }
  }

  Future<String> saveCadireta(Cadireta cadireta, int contador, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
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
    // Log da tentativa de inserção em cadireta
    appendPedidoLog('cadireta', cadireta.toMap());
    try {
      await connection.execute(query, parameters: parameters);
      return "";
    } catch (e) {
      return 'Erro linha $contador da $s: $e';
    }
  }

  Future<String> deleteCadiredi() async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final query = Sql.named('DELETE FROM cadiredi');
    try {
      await connection.execute(query);
      return "";
    } catch (e) {
      return 'Erro ao deletar cadiredi: $e';
    }
  }

  Future<String> saveCadiredi(Cadiredi cadiredi, int contador, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
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
    // Log da tentativa de inserção em cadiredi
    appendPedidoLog('cadiredi', cadiredi.toMap());
    try {
      await connection.execute(query, parameters: parameters);
      return "";
    } catch (e) {
      return 'Erro linha $contador da $s: $e';
    }
  }

  Future<String> deleteCadire2() async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final query = Sql.named('DELETE FROM cadire2');
    try {
      await connection.execute(query);
      return "";
    } catch (e) {
      return 'Erro ao deletar cadire2: $e';
    }
  }

  /// Maiores `cadinfseq` e `cadinfcont` já existentes para [cadinfprod] (inserção apenas, sem apagar).
  Future<({int seq, int cont})> getCadire2MaxCountersForProd(
    String cadinfprod,
  ) async {
    final connection = PostgresConnection().connection;
    if (connection == null) {
      return (seq: 0, cont: 0);
    }
    try {
      final result = await connection.execute(
        Sql.named(
          'SELECT COALESCE(MAX(cadinfseq), 0) AS mseq, '
          'COALESCE(MAX(cadinfcont), 0) AS mcont '
          'FROM cadire2 WHERE cadinfprod = @cadinfprod',
        ),
        parameters: {'cadinfprod': cadinfprod},
      );
      if (result.isEmpty) {
        return (seq: 0, cont: 0);
      }
      final m = result.first.toColumnMap();
      return (
        seq: _parseSqlInt(m['mseq']),
        cont: _parseSqlInt(m['mcont']),
      );
    } catch (_) {
      return (seq: 0, cont: 0);
    }
  }

  int _parseSqlInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is BigInt) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // Novo método para deletar apenas registros de um projeto específico
  Future<String> deleteCadire2ByProject(String cadinfprod) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final query = Sql.named(
      'DELETE FROM cadire2 WHERE cadinfprod = @cadinfprod',
    );
    try {
      await connection.execute(query, parameters: {'cadinfprod': cadinfprod});
      return "";
    } catch (e) {
      return 'Erro ao deletar cadire2 do projeto $cadinfprod: $e';
    }
  }

  Future<String> saveCadire2(Cadire2 cadire2, int contador, String s) async {
    final connection = PostgresConnection().connection;

    if (connection == null) {
      throw Exception('Erro: Conexão não iniciada');
    }
    final query = Sql.named(
      'INSERT INTO cadire2 (cadinfcont, cadinfprod, cadinfseq, cadinfdes, cadinfinf) '
      'VALUES (@cadinfcont, @cadinfprod, @cadinfseq, @cadinfdes, @cadinfinf)',
    );
    final parameters = {
      'cadinfcont': cadire2.cadinfcont,
      'cadinfprod': cadire2.cadinfprod,
      'cadinfseq': cadire2.cadinfseq,
      'cadinfdes': cadire2.cadinfdes,
      'cadinfinf': cadire2.cadinfinf,
    };
    try {
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
    final mssqlConnection = SqlServerConnection.getInstance().mssqlConnection;

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
    final mssqlConnection = SqlServerConnection.getInstance().mssqlConnection;

    // 1. Consulta principal da distinta
    String query =
        "SELECT CODFIG, QTA, FASE, VALIDO FROM DISTINTA WHERE cod = '$codDistinta'";
    String rawResult = await mssqlConnection.getData(query);

    List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(
      json.decode(rawResult),
    );

    // 2. Monta mapa de variáveis vindas da string
    Map<String, String> valores = {};
    if (variaveis != null && variaveis.isNotEmpty) {
      for (var par in variaveis.split(';')) {
        if (par.contains('=')) {
          var partes = par.split('=');
          valores[partes[0].toUpperCase()] = partes[1];
        }
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
          substituirVariaveis(
            (item['CODFIG'] ?? '').toString(),
            valores,
          ).trim().toUpperCase();
      String qtaRaw =
          (item['QTA'] ?? '').toString().replaceAll('\u0010', '').trim();
      String qtaSubstituida = substituirVariaveis(qtaRaw, valores);
      String validoRaw = (item['VALIDO'] ?? '').toString();

      // --- Validação do campo VALIDO ---
      if (validoRaw.trim().isNotEmpty) {
        bool passou = _avaliarValido(validoRaw, valores);
        if (!passou) continue; // ignora item se não passar na validação
      }

      double? valorFinal;
      try {
        // ignore: deprecated_member_use
        Parser p = Parser();
        Expression exp = p.parse(qtaSubstituida);
        ContextModel cm = ContextModel();
        valorFinal = exp.evaluate(EvaluationType.REAL, cm);
      } catch (_) {
        valorFinal = double.tryParse(qtaSubstituida.replaceAll(',', '.'));
      }

      if (valorFinal != null && codfig.isNotEmpty) {
        final fase = (item['FASE'] ?? '').toString().trim();
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

    // 5. Busca descrição das fases faltantes
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

    // 6. Adiciona descrições
    for (var item in processados) {
      final cod = item['CODFIG'];
      if ((item['FASE'] ?? '').isEmpty) {
        item['DESCRICAO'] = mapaFaseDescricao[cod] ?? '';
      } else {
        item['DESCRICAO'] = mapaDescricao[cod] ?? '';
      }
    }

    return jsonEncode(processados);
  }

  // Função para substituir placeholders <VAR>
  String substituirVariaveis(String input, Map<String, String> valores) {
    if (input.isEmpty) return '';
    RegExp regex = RegExp(r"<([^<>]+)>");
    return input.replaceAllMapped(regex, (match) {
      String chave = match.group(1)?.toUpperCase() ?? '';
      return valores[chave] ?? '';
    });
  }

  /// Avalia a expressão do campo VALIDO (com suporte a: !!, =, !=, >, <, >=, <=, & (AND), | (OR))
  bool _avaliarValido(String validoRaw, Map<String, String> valores) {
    // substitui placeholders <VAR>
    String expr = substituirVariaveis(validoRaw, valores).trim();

    if (expr.isEmpty) return true;

    // OR principal (suporta '|' ou '||')
    List<String> orParts = expr.split(RegExp(r'\s*\|\|\s*|\s*\|\s*'));
    for (var orPart in orParts) {
      // AND dentro do OR (suporta '&' ou '&&')
      List<String> andParts = orPart.split(RegExp(r'\s*&&\s*|\s*\&\s*'));

      bool andResult = true;
      for (var rawClause in andParts) {
        String clause = rawClause.trim();
        if (clause.isEmpty) {
          andResult = false;
          break;
        }

        bool clauseResult = false;

        // 1) operador "!!" (não vazio / não zero)
        if (clause.endsWith('!!')) {
          String token = clause.substring(0, clause.length - 2).trim();
          if (token.isEmpty) {
            clauseResult = false;
          } else {
            double? n = _parseDouble(token);
            if (n != null) {
              clauseResult = n != 0;
            } else {
              clauseResult = token.isNotEmpty;
            }
          }
        } else {
          // 2) Comparações: >=, <=, !=, =, >, <
          RegExp compRe = RegExp(r'^(.+?)(>=|<=|!=|==|=|>|<)(.+)$');
          var m = compRe.firstMatch(clause);
          if (m != null) {
            String left = m.group(1)!.trim();
            String op = m.group(2)!.trim();
            String right = m.group(3)!.trim();

            // remove aspas se houver
            String stripQuotes(String s) {
              if ((s.startsWith('"') && s.endsWith('"')) ||
                  (s.startsWith("'") && s.endsWith("'"))) {
                return s.substring(1, s.length - 1);
              }
              return s;
            }

            left = stripQuotes(left);
            right = stripQuotes(right);

            double? ln = _parseDouble(left);
            double? rn = _parseDouble(right);

            if (ln != null && rn != null) {
              switch (op) {
                case '>=':
                  clauseResult = ln >= rn;
                  break;
                case '<=':
                  clauseResult = ln <= rn;
                  break;
                case '>':
                  clauseResult = ln > rn;
                  break;
                case '<':
                  clauseResult = ln < rn;
                  break;
                case '!=':
                  clauseResult = ln != rn;
                  break;
                case '=':
                case '==':
                  clauseResult = ln == rn;
                  break;
                default:
                  clauseResult = false;
              }
            } else {
              // comparação textual (case-insensitive)
              String lU = left.toUpperCase();
              String rU = right.toUpperCase();
              if (op == '=' || op == '==') {
                clauseResult = lU == rU;
              } else if (op == '!=') {
                clauseResult = lU != rU;
              } else {
                // comparar lexicograficamente para >, <, >=, <=
                int cmp = lU.compareTo(rU);
                if (op == '>') clauseResult = cmp > 0;
                if (op == '<') clauseResult = cmp < 0;
                if (op == '>=') clauseResult = cmp >= 0;
                if (op == '<=') clauseResult = cmp <= 0;
              }
            }
          } else {
            // 3) cláusula simples (ex.: "1" ou "ABC") -> true se número diferente de zero ou string não vazia
            double? n = _parseDouble(clause);
            if (n != null) {
              clauseResult = n != 0;
            } else {
              clauseResult = clause.isNotEmpty;
            }
          }
        }

        if (!clauseResult) {
          andResult = false;
          break;
        }
      }

      if (andResult) {
        return true; // se qualquer OR for verdadeiro -> expressão verdadeira
      }
    }

    return false;
  }

  /// tenta converter string para double (suporta vírgula decimal)
  double? _parseDouble(String s) {
    String t = s.replaceAll(',', '.').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
}
